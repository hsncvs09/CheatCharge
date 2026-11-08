import Foundation
import SwiftData

// Faz 2 mantık testleri: hesaplayıcı, hafta sınırları ve motor (bellek içi SwiftData).

nonisolated(unsafe) var failures = 0

func check(_ condition: Bool, _ message: String, line: Int = #line) {
    if condition {
        print("  ✓ \(message)")
    } else {
        failures += 1
        print("  ✗ BAŞARISIZ: \(message) (satır \(line))")
    }
}

func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 0, _ min: Int = 0) -> Date {
    Calendar(identifier: .gregorian).date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: min))!
}

// MARK: - Hesaplayıcı

func testCalculator() {
    print("WeekRolloverCalculator")

    var r = WeekRolloverCalculator.close(earned: 1000, spent: 0, rollover: 0)
    check(r.carriedForward == 1000 && r.isSuccessful, "E=1000, S=0 → 1000 devreder, başarılı")

    r = WeekRolloverCalculator.close(earned: 1000, spent: 400, rollover: 0)
    check(r.carriedForward == 600 && r.isSuccessful, "E=1000, S=400 → 600 devreder")

    r = WeekRolloverCalculator.close(earned: 500, spent: 200, rollover: 300)
    check(r.spentFromRollover == 200 && r.spentFromCurrent == 0, "FIFO: 200 harcama tamamen devirden düşer")
    check(r.rolloverExpired == 100, "Devirden kullanılmayan 100 yanar")
    check(r.carriedForward == 500, "Bu haftanın 500'ü eksiksiz devreder (devir zincirlenmez)")

    r = WeekRolloverCalculator.close(earned: 500, spent: 600, rollover: 300)
    check(r.spentFromRollover == 300 && r.spentFromCurrent == 300, "FIFO: 600 harcamanın 300'ü devirden, 300'ü bu haftadan")
    check(r.carriedForward == 200 && r.isSuccessful, "500-300 = 200 devreder, (500+300≥600) başarılı")

    r = WeekRolloverCalculator.close(earned: 0, spent: 0, rollover: 300)
    check(!r.isSuccessful, "E=0 pasif hafta başarısız (pasiflik engeli)")
    check(r.carriedForward == 0 && r.rolloverExpired == 300, "Pasif haftada devir tamamen yanar")

    r = WeekRolloverCalculator.close(earned: 500, spent: 900, rollover: 0)
    check(!r.isSuccessful && r.carriedForward == 0, "Bilanço eksiye düşünce başarısız, devir yok")

    r = WeekRolloverCalculator.close(earned: 0, spent: 100, rollover: 0)
    check(!r.isSuccessful, "Sadece harcama olan hafta başarısız")

    check(WeekRolloverCalculator.liveBalance(earned: 300, spent: 800, rollover: 600) == 100, "Canlı bakiye R+E-S = 100")
}

// MARK: - Hafta sınırları

func testWeekHelper() {
    print("WeekHelper (sabit Pazartesi)")
    let cal = Calendar(identifier: .gregorian)
    let monday = date(2026, 9, 28)
    check(cal.component(.weekday, from: monday) == 2, "28 Eylül 2026 Pazartesi")

    check(WeekHelper.currentWeekStart(now: date(2026, 10, 3, 12)) == monday, "Cumartesi → hafta Pazartesi 28 Eyl'de başlar")
    check(WeekHelper.currentWeekStart(now: date(2026, 10, 4, 23, 59)) == monday, "Pazar 23:59 hâlâ aynı hafta")
    check(WeekHelper.currentWeekStart(now: date(2026, 10, 5)) == date(2026, 10, 5), "Pazartesi 00:00 yeni hafta")
    check(WeekHelper.weekEnd(startingAt: monday) == date(2026, 10, 5), "Haftanın bitişi bir sonraki Pazartesi")

    let now = date(2026, 10, 3, 12)
    check(!WeekHelper.isInCurrentWeek(date(2026, 9, 27, 23, 59), now: now), "Önceki Pazar bu haftada değil")
    check(WeekHelper.isInCurrentWeek(monday, now: now), "Pazartesi 00:00 bu haftada")
    check(WeekHelper.isInCurrentWeek(date(2026, 10, 4, 23, 59), now: now), "Pazar 23:59 bu haftada")
    check(!WeekHelper.isInCurrentWeek(date(2026, 10, 5), now: now), "Sonraki Pazartesi bu haftada değil")

    // Aylık takvim hafta satırları testi (Kasım 2026: 1 Kasım Pazar -> 6 hafta satırı: 26 Eki .. 30 Kas)
    let novDate = date(2026, 11, 15, 10)
    check(WeekHelper.monthStart(containing: novDate) == date(2026, 11, 1), "Kasım 2026 ay başlangıcı 1 Kasım 00:00")
    let novRows = WeekHelper.monthWeekRows(for: novDate)
    check(novRows.count == 6, "Kasım 2026 (1 Kas Pazar, 30 Kas Pazartesi) 6 takvim satırı üretir")
    check(novRows.first?.weekStart == date(2026, 10, 26), "İlk hafta satırı 26 Ekim Pazartesi başlar")
    check(novRows.last?.weekStart == date(2026, 11, 30), "Son hafta satırı 30 Kasım Pazartesi başlar")
    check(novRows.allSatisfy { $0.days.count == 7 }, "Her hafta satırı tam 7 gün içerir")
}

// MARK: - Motor

@MainActor
func testEngine() throws {
    print("WeekRolloverEngine")
    let schema = Schema([Workout.self, TreatItem.self, TreatLog.self, WeekRecord.self, UserGamificationState.self, BadgeRecord.self])
    let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)])
    let context = container.mainContext

    let state = UserGamificationState(openWeekStart: date(2026, 9, 28))
    context.insert(state)

    let small = TreatItem(name: "Burger", calories: 400, category: .burger)
    let big = TreatItem(name: "Büyük Menü", calories: 800, category: .fastFood)
    context.insert(small)
    context.insert(big)

    // Hafta 1 (28 Eyl – 5 Eki): E=1000, S=400
    context.insert(Workout(type: "Koşu", rawCalories: 1000, date: date(2026, 9, 30, 18)))
    let log1 = TreatLog(treat: small, date: date(2026, 10, 1, 20))
    context.insert(log1)

    // Hafta 2 (5 – 12 Eki): Ağırlık 250 → afterburn ile 300, S=800
    let weights = Workout(type: "Ağırlık", rawCalories: 250, date: date(2026, 10, 6, 7))
    context.insert(weights)
    check(weights.caloriesBurned == 300 && weights.afterburnBonus == 50, "Ağırlık 250 kcal → 300 kcal (+50 Afterburn)")
    let log2 = TreatLog(treat: big, date: date(2026, 10, 8, 21))
    context.insert(log2)

    // Hafta 3 (12 – 19 Eki): boş
    try context.save()

    var closed = try WeekRolloverEngine.closeElapsedWeeks(context: context, now: date(2026, 10, 3, 12))
    check(closed.isEmpty && state.openWeekStart == date(2026, 9, 28), "Hafta ortasında hiçbir şey kapanmaz")

    // Pazartesi sabahı: hafta 1 ve 2 kapanır
    closed = try WeekRolloverEngine.closeElapsedWeeks(context: context, now: date(2026, 10, 13, 9))
    check(closed.count == 2, "2 hafta kapandı")
    let r1 = closed[0], r2 = closed[1]
    check(r1.earnedCalories == 1000 && r1.spentCalories == 400 && r1.rolloverReceived == 0, "Hafta 1: E=1000, S=400, R=0")
    check(r1.rolloverCarriedForward == 600 && r1.isSuccessful, "Hafta 1: 600 devreder, başarılı")
    check(r2.earnedCalories == 300 && r2.spentCalories == 800 && r2.rolloverReceived == 600, "Hafta 2: E=300 (afterburn dahil), S=800, R=600")
    check(r2.rolloverRemaining == 0 && r2.rolloverCarriedForward == 100 && r2.isSuccessful, "Hafta 2: devir tükendi, 100 devreder, başarılı")
    check(state.totalSuccessfulWeeks == 2 && state.currentStreak == 2, "Seviye 2, seri 2")
    check(state.currentRolloverBalance == 100, "Devir bakiyesi 100")
    check(state.openWeekStart == date(2026, 10, 12), "Açık hafta 12 Eki'ye ilerledi")

    // Hafta 3 pasif geçer, hafta 4 başlarken kapanır
    closed = try WeekRolloverEngine.closeElapsedWeeks(context: context, now: date(2026, 10, 20, 9))
    check(closed.count == 1 && !closed[0].isSuccessful, "Hafta 3 pasif → başarısız")
    check(closed[0].rolloverReceived == 100 && closed[0].rolloverRemaining == 100 && closed[0].rolloverCarriedForward == 0,
          "Hafta 3: 100 devir kullanılmadı, yandı; zincirleme devir yok")
    check(state.currentStreak == 0, "Seri sıfırlandı")
    check(state.totalSuccessfulWeeks == 2, "Kalıcı seviye düşmedi (2)")
    check(state.currentRolloverBalance == 0, "Devir bakiyesi 0")

    // İdempotens
    closed = try WeekRolloverEngine.closeElapsedWeeks(context: context, now: date(2026, 10, 20, 9))
    let records = try context.fetch(FetchDescriptor<WeekRecord>())
    check(closed.isEmpty && records.count == 3, "Tekrar çalıştırmak yeni kayıt açmaz (toplam 3 arşiv)")

    // Uzun süre açılmayan uygulama: 5 hafta atlanır, her biri sırayla kapanır
    closed = try WeekRolloverEngine.closeElapsedWeeks(context: context, now: date(2026, 11, 24, 9))
    check(closed.count == 5, "5 haftalık boşlukta 5 hafta sırayla kapandı")
    check(state.currentStreak == 0 && state.totalSuccessfulWeeks == 2, "Pasif haftalar seviyeyi etkilemez")
}

@main
struct Tests {
    @MainActor
    static func main() throws {
        testCalculator()
        testWeekHelper()
        try testEngine()
        print(failures == 0 ? "\nTÜM TESTLER GEÇTİ" : "\n\(failures) TEST BAŞARISIZ")
        exit(failures == 0 ? 0 : 1)
    }
}
