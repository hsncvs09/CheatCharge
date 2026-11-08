//
//  Faz3LogicTests.swift
//  DevTools
//
//  Created by Hasan Cavusoglu on 03.10.2026.
//

import Foundation
import SwiftData

nonisolated(unsafe) var failures = 0

func check(_ condition: Bool, _ message: String, line: Int = #line) {
    if condition {
        print("  ✓ \(message)")
    } else {
        failures += 1
        print("  ✗ BAŞARISIZ: \(message) (satır \(line))")
    }
}

func makeDate(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 0, _ min: Int = 0) -> Date {
    Calendar(identifier: .gregorian).date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: min))!
}

// MARK: - Katalog Testleri

func testBadgeCatalog() {
    print("BadgeCatalog (Rozet Kataloğu)")

    check(BadgeCatalog.all.count == 25, "Toplam rozet sayısı 25")

    let chargeBadges = BadgeCatalog.badges(in: .charge)
    let cheatBadges = BadgeCatalog.badges(in: .cheat)
    let secretBadges = BadgeCatalog.badges(in: .secret)

    check(chargeBadges.count == 11, "11 Charge rozeti mevcut")
    check(cheatBadges.count == 12, "12 Cheat rozeti mevcut")
    check(secretBadges.count == 2, "2 Gizli rozet mevcut")

    for badge in BadgeCatalog.all {
        check(!badge.key.isEmpty, "Rozet anahtarı boş değil: \(badge.key)")
        check(!badge.title.isEmpty, "Rozet başlığı boş değil: \(badge.title)")
        check(!badge.detail.isEmpty, "Rozet detayı boş değil: \(badge.detail)")
        check(BadgeCatalog.definition(for: badge.key) != nil, "Anahtarla sorgulama çalışıyor: \(badge.key)")
    }

    check(BadgeCatalog.definition(for: "yin_yang")?.isSecret == true, "Yin & Yang gizli rozet")
    check(BadgeCatalog.definition(for: "night_owl")?.isSecret == true, "Gece Kuşu gizli rozet")
    check(BadgeCatalog.definition(for: "first_charge")?.isSecret == false, "İlk Şarj normal rozet")
}

// MARK: - Saf Kural Testleri (BadgeRules)

func testBadgeRules() {
    print("BadgeRules (Saf Rozet Kuralları)")
    let cal = Calendar(identifier: .gregorian)

    // 1. first_charge
    let emptyInput = BadgeEvaluationInput(workouts: [], treats: [], calendar: cal)
    check(!BadgeRules.evaluateFirstCharge(input: emptyInput), "first_charge: antrenman yokken açılmaz")
    let oneWorkoutInput = BadgeEvaluationInput(
        workouts: [WorkoutSnapshot(date: makeDate(2026, 10, 5, 10), calories: 200, type: "Koşu")],
        treats: [],
        calendar: cal
    )
    check(BadgeRules.evaluateFirstCharge(input: oneWorkoutInput), "first_charge: ilk antrenmanda açılır")

    // 2. iron_will: Aynı hafta 3 farklı günde Ağırlık
    // 2026-10-05 (Pzt), 2026-10-07 (Çar), 2026-10-09 (Cum)
    let ironWillNegative = BadgeEvaluationInput(
        workouts: [
            WorkoutSnapshot(date: makeDate(2026, 10, 5, 10), calories: 200, type: "Ağırlık"),
            WorkoutSnapshot(date: makeDate(2026, 10, 5, 18), calories: 200, type: "Ağırlık"), // aynı gün
            WorkoutSnapshot(date: makeDate(2026, 10, 7, 10), calories: 200, type: "Ağırlık"),
            WorkoutSnapshot(date: makeDate(2026, 10, 9, 10), calories: 200, type: "Koşu") // farklı tür
        ],
        treats: [],
        calendar: cal
    )
    check(!BadgeRules.evaluateIronWill(input: ironWillNegative), "iron_will: 2 farklı gün ağırlık yeterli değil")

    let ironWillPositive = BadgeEvaluationInput(
        workouts: [
            WorkoutSnapshot(date: makeDate(2026, 10, 5, 10), calories: 200, type: "Ağırlık"),
            WorkoutSnapshot(date: makeDate(2026, 10, 7, 10), calories: 200, type: "Ağırlık"),
            WorkoutSnapshot(date: makeDate(2026, 10, 9, 10), calories: 200, type: "Ağırlık")
        ],
        treats: [],
        calendar: cal
    )
    check(BadgeRules.evaluateIronWill(input: ironWillPositive), "iron_will: aynı haftada 3 farklı gün ağırlıkta açılır")

    // 3. endless_battery: Tek seansta >= 500 kcal
    let batteryNegative = BadgeEvaluationInput(
        workouts: [WorkoutSnapshot(date: makeDate(2026, 10, 5, 10), calories: 499, type: "Koşu")],
        treats: [],
        calendar: cal
    )
    check(!BadgeRules.evaluateEndlessBattery(input: batteryNegative), "endless_battery: 499 kcal açılmaz")
    let batteryPositive = BadgeEvaluationInput(
        workouts: [WorkoutSnapshot(date: makeDate(2026, 10, 5, 10), calories: 500, type: "Koşu")],
        treats: [],
        calendar: cal
    )
    check(BadgeRules.evaluateEndlessBattery(input: batteryPositive), "endless_battery: 500 kcal açılır")

    // 4. weekend_warrior: Cmt/Paz tek seansta >= 400 kcal
    // 2026-10-09 (Cuma), 2026-10-10 (Cmt), 2026-10-11 (Paz)
    let warriorFriday = BadgeEvaluationInput(
        workouts: [WorkoutSnapshot(date: makeDate(2026, 10, 9, 10), calories: 500, type: "Koşu")],
        treats: [],
        calendar: cal
    )
    check(!BadgeRules.evaluateWeekendWarrior(input: warriorFriday), "weekend_warrior: Cuma günü 500 kcal açılmaz")

    let warriorSaturdayLow = BadgeEvaluationInput(
        workouts: [WorkoutSnapshot(date: makeDate(2026, 10, 10, 10), calories: 399, type: "Koşu")],
        treats: [],
        calendar: cal
    )
    check(!BadgeRules.evaluateWeekendWarrior(input: warriorSaturdayLow), "weekend_warrior: Cumartesi 399 kcal açılmaz")

    let warriorSaturday = BadgeEvaluationInput(
        workouts: [WorkoutSnapshot(date: makeDate(2026, 10, 10, 10), calories: 400, type: "Koşu")],
        treats: [],
        calendar: cal
    )
    check(BadgeRules.evaluateWeekendWarrior(input: warriorSaturday), "weekend_warrior: Cumartesi 400 kcal açılır")

    let warriorSunday = BadgeEvaluationInput(
        workouts: [WorkoutSnapshot(date: makeDate(2026, 10, 11, 10), calories: 420, type: "Ağırlık")],
        treats: [],
        calendar: cal
    )
    check(BadgeRules.evaluateWeekendWarrior(input: warriorSunday), "weekend_warrior: Pazar 420 kcal açılır")

    // 5. charge_7k, charge_14k, charge_28k
    let total6999 = BadgeEvaluationInput(
        workouts: [WorkoutSnapshot(date: makeDate(2026, 10, 5, 10), calories: 6999, type: "Koşu")],
        treats: [],
        calendar: cal
    )
    check(!BadgeRules.evaluateCharge7K(input: total6999), "charge_7k: 6999 kcal açılmaz")

    let total7000 = BadgeEvaluationInput(
        workouts: [
            WorkoutSnapshot(date: makeDate(2026, 10, 5, 10), calories: 3500, type: "Koşu"),
            WorkoutSnapshot(date: makeDate(2026, 10, 6, 10), calories: 3500, type: "Koşu")
        ],
        treats: [],
        calendar: cal
    )
    check(BadgeRules.evaluateCharge7K(input: total7000), "charge_7k: 7000 kcal açılır")
    check(!BadgeRules.evaluateCharge14K(input: total7000), "charge_14k: 7000 kcal açılmaz")

    let total14000 = BadgeEvaluationInput(
        workouts: [WorkoutSnapshot(date: makeDate(2026, 10, 5, 10), calories: 14000, type: "Koşu")],
        treats: [],
        calendar: cal
    )
    check(BadgeRules.evaluateCharge14K(input: total14000), "charge_14k: 14000 kcal açılır")
    check(!BadgeRules.evaluateCharge28K(input: total14000), "charge_28k: 14000 kcal açılmaz")

    let total28000 = BadgeEvaluationInput(
        workouts: [WorkoutSnapshot(date: makeDate(2026, 10, 5, 10), calories: 28000, type: "Koşu")],
        treats: [],
        calendar: cal
    )
    check(BadgeRules.evaluateCharge28K(input: total28000), "charge_28k: 28000 kcal açılır")

    // 8. charge_machine: Takvim haftasında toplam >= 1500 kcal
    let machineNegative = BadgeEvaluationInput(
        workouts: [
            WorkoutSnapshot(date: makeDate(2026, 10, 5, 10), calories: 700, type: "Koşu"),
            WorkoutSnapshot(date: makeDate(2026, 10, 12, 10), calories: 800, type: "Koşu") // sonraki hafta
        ],
        treats: [],
        calendar: cal
    )
    check(!BadgeRules.evaluateChargeMachine(input: machineNegative), "charge_machine: iki farklı haftada toplam 1500 açılmaz")

    let machinePositive = BadgeEvaluationInput(
        workouts: [
            WorkoutSnapshot(date: makeDate(2026, 10, 5, 10), calories: 750, type: "Koşu"),
            WorkoutSnapshot(date: makeDate(2026, 10, 7, 10), calories: 750, type: "Koşu")
        ],
        treats: [],
        calendar: cal
    )
    check(BadgeRules.evaluateChargeMachine(input: machinePositive), "charge_machine: aynı haftada 1500 kcal açılır")

    // 9. early_charger: 06:00 - 09:00
    let earlyNegative1 = BadgeEvaluationInput(
        workouts: [WorkoutSnapshot(date: makeDate(2026, 10, 5, 5, 59), calories: 200, type: "Koşu")],
        treats: [],
        calendar: cal
    )
    check(!BadgeRules.evaluateEarlyCharger(input: earlyNegative1), "early_charger: 05:59 açılmaz")

    let earlyNegative2 = BadgeEvaluationInput(
        workouts: [WorkoutSnapshot(date: makeDate(2026, 10, 5, 9, 0), calories: 200, type: "Koşu")],
        treats: [],
        calendar: cal
    )
    check(!BadgeRules.evaluateEarlyCharger(input: earlyNegative2), "early_charger: 09:00 açılmaz")

    let earlyPositive = BadgeEvaluationInput(
        workouts: [WorkoutSnapshot(date: makeDate(2026, 10, 5, 6, 30), calories: 200, type: "Koşu")],
        treats: [],
        calendar: cal
    )
    check(BadgeRules.evaluateEarlyCharger(input: earlyPositive), "early_charger: 06:30 açılır")

    // 10. night_charger: 21:00 - 24:00
    let nightNegative1 = BadgeEvaluationInput(
        workouts: [WorkoutSnapshot(date: makeDate(2026, 10, 5, 20, 59), calories: 200, type: "Koşu")],
        treats: [],
        calendar: cal
    )
    check(!BadgeRules.evaluateNightCharger(input: nightNegative1), "night_charger: 20:59 açılmaz")

    let nightPositive = BadgeEvaluationInput(
        workouts: [WorkoutSnapshot(date: makeDate(2026, 10, 5, 21, 30), calories: 200, type: "Koşu")],
        treats: [],
        calendar: cal
    )
    check(BadgeRules.evaluateNightCharger(input: nightPositive), "night_charger: 21:30 açılır")

    // 11. overcharged: Aynı takvim gününde toplam >= 1000 kcal
    let overchargedNegative = BadgeEvaluationInput(
        workouts: [
            WorkoutSnapshot(date: makeDate(2026, 10, 5, 8), calories: 500, type: "Koşu"),
            WorkoutSnapshot(date: makeDate(2026, 10, 6, 8), calories: 500, type: "Koşu") // farklı gün
        ],
        treats: [],
        calendar: cal
    )
    check(!BadgeRules.evaluateOvercharged(input: overchargedNegative), "overcharged: farklı günlerde toplam 1000 açılmaz")

    let overchargedPositive = BadgeEvaluationInput(
        workouts: [
            WorkoutSnapshot(date: makeDate(2026, 10, 5, 8), calories: 600, type: "Koşu"),
            WorkoutSnapshot(date: makeDate(2026, 10, 5, 18), calories: 400, type: "Ağırlık")
        ],
        treats: [],
        calendar: cal
    )
    check(BadgeRules.evaluateOvercharged(input: overchargedPositive), "overcharged: aynı gün toplam 1000 kcal açılır")

    // 12. first_cheat
    check(!BadgeRules.evaluateFirstCheat(input: emptyInput), "first_cheat: kaçamak yokken açılmaz")
    let oneTreatInput = BadgeEvaluationInput(
        workouts: [],
        treats: [TreatSnapshot(date: makeDate(2026, 10, 5, 12), calories: 300, category: .burger)],
        calendar: cal
    )
    check(BadgeRules.evaluateFirstCheat(input: oneTreatInput), "first_cheat: ilk kaçamakta açılır")

    // 13. cheat_happens: Bakiye pozitifken yapılan ilk kaçamak
    // Havuz = 0 iken açılmaz
    let cheatHappensZeroPool = BadgeEvaluationInput(
        workouts: [],
        treats: [TreatSnapshot(date: makeDate(2026, 10, 5, 12), calories: 300, category: .burger)],
        currentRollover: 0,
        calendar: cal
    )
    check(!BadgeRules.evaluateCheatHappens(input: cheatHappensZeroPool), "cheat_happens: havuz 0 iken açılmaz")

    // Havuz = 500, harcama = 300 (bakiye 200 >= 0)
    let cheatHappensPositive = BadgeEvaluationInput(
        workouts: [WorkoutSnapshot(date: makeDate(2026, 10, 5, 10), calories: 500, type: "Koşu")],
        treats: [TreatSnapshot(date: makeDate(2026, 10, 5, 12), calories: 300, category: .burger)],
        currentRollover: 0,
        calendar: cal
    )
    check(BadgeRules.evaluateCheatHappens(input: cheatHappensPositive), "cheat_happens: pozitif bakiyeyle kaçamakta açılır")

    // 14. burger_boss, pizza_party, beer_oclock (10 adet)
    let nineBurgers = (1...9).map {
        TreatSnapshot(date: makeDate(2026, 10, 5, $0), calories: 400, category: .burger)
    }
    let input9Burgers = BadgeEvaluationInput(workouts: [], treats: nineBurgers, calendar: cal)
    check(!BadgeRules.evaluateBurgerBoss(input: input9Burgers), "burger_boss: 9 burger açılmaz")

    let tenBurgers = (1...10).map {
        TreatSnapshot(date: makeDate(2026, 10, 5, $0), calories: 400, category: .burger)
    }
    let input10Burgers = BadgeEvaluationInput(workouts: [], treats: tenBurgers, calendar: cal)
    check(BadgeRules.evaluateBurgerBoss(input: input10Burgers), "burger_boss: 10 burger açılır")

    let tenPizzas = (1...10).map {
        TreatSnapshot(date: makeDate(2026, 10, 5, $0), calories: 600, category: .pizza)
    }
    let input10Pizzas = BadgeEvaluationInput(workouts: [], treats: tenPizzas, calendar: cal)
    check(BadgeRules.evaluatePizzaParty(input: input10Pizzas), "pizza_party: 10 pizza açılır")

    let tenBeers = (1...10).map {
        TreatSnapshot(date: makeDate(2026, 10, 5, $0), calories: 150, category: .beer)
    }
    let input10Beers = BadgeEvaluationInput(workouts: [], treats: tenBeers, calendar: cal)
    check(BadgeRules.evaluateBeerOClock(input: input10Beers), "beer_oclock: 10 bira açılır")

    // 17. cheat_collector: En az 6 farklı kategori
    let fiveCategories: [TreatSnapshot] = [
        TreatSnapshot(date: makeDate(2026, 10, 5), calories: 200, category: .burger),
        TreatSnapshot(date: makeDate(2026, 10, 5), calories: 200, category: .pizza),
        TreatSnapshot(date: makeDate(2026, 10, 5), calories: 200, category: .beer),
        TreatSnapshot(date: makeDate(2026, 10, 5), calories: 200, category: .cocktail),
        TreatSnapshot(date: makeDate(2026, 10, 5), calories: 200, category: .dessert)
    ]
    check(!BadgeRules.evaluateCheatCollector(input: BadgeEvaluationInput(workouts: [], treats: fiveCategories, calendar: cal)), "cheat_collector: 5 kategori açılmaz")

    var sixCategories = fiveCategories
    sixCategories.append(TreatSnapshot(date: makeDate(2026, 10, 5), calories: 200, category: .snack))
    check(BadgeRules.evaluateCheatCollector(input: BadgeEvaluationInput(workouts: [], treats: sixCategories, calendar: cal)), "cheat_collector: 6 kategori açılır")

    // 18. cheat_weekend: Cmt/Paz kaçamak
    let weekdayCheat = BadgeEvaluationInput(
        workouts: [],
        treats: [TreatSnapshot(date: makeDate(2026, 10, 5, 12), calories: 200, category: .burger)], // Pazartesi
        calendar: cal
    )
    check(!BadgeRules.evaluateCheatWeekend(input: weekdayCheat), "cheat_weekend: Pazartesi açılmaz")

    let saturdayCheat = BadgeEvaluationInput(
        workouts: [],
        treats: [TreatSnapshot(date: makeDate(2026, 10, 10, 12), calories: 200, category: .burger)], // Cumartesi
        calendar: cal
    )
    check(BadgeRules.evaluateCheatWeekend(input: saturdayCheat), "cheat_weekend: Cumartesi açılır")

    // 19. agave_spirit: cocktail kaydı
    check(!BadgeRules.evaluateAgaveSpirit(input: oneTreatInput), "agave_spirit: burger kaydı ile açılmaz")
    let cocktailInput = BadgeEvaluationInput(
        workouts: [],
        treats: [TreatSnapshot(date: makeDate(2026, 10, 5, 20), calories: 250, category: .cocktail)],
        calendar: cal
    )
    check(BadgeRules.evaluateAgaveSpirit(input: cocktailInput), "agave_spirit: kokteyl kaydı ile açılır")

    // 20. sugar_coma: Art arda 2 takvim günü Tatlı
    let dessertNonConsecutive = BadgeEvaluationInput(
        workouts: [],
        treats: [
            TreatSnapshot(date: makeDate(2026, 10, 5, 14), calories: 300, category: .dessert),
            TreatSnapshot(date: makeDate(2026, 10, 7, 14), calories: 300, category: .dessert) // 1 gün ara var
        ],
        calendar: cal
    )
    check(!BadgeRules.evaluateSugarComa(input: dessertNonConsecutive), "sugar_coma: 1 gün aralıklı tatlı açılmaz")

    let dessertConsecutive = BadgeEvaluationInput(
        workouts: [],
        treats: [
            TreatSnapshot(date: makeDate(2026, 10, 5, 14), calories: 300, category: .dessert),
            TreatSnapshot(date: makeDate(2026, 10, 6, 14), calories: 300, category: .dessert) // ardışık günler
        ],
        calendar: cal
    )
    check(BadgeRules.evaluateSugarComa(input: dessertConsecutive), "sugar_coma: ardışık 2 gün tatlıda açılır")

    // 21. zero_guilt: Tek günde >= 1000 kcal kaçamak ve bakiye >= 0
    let zeroGuiltDeficit = BadgeEvaluationInput(
        workouts: [WorkoutSnapshot(date: makeDate(2026, 10, 5, 10), calories: 500, type: "Koşu")],
        treats: [TreatSnapshot(date: makeDate(2026, 10, 5, 14), calories: 1000, category: .burger)], // 500 - 1000 = -500
        currentRollover: 0,
        openWeekStart: makeDate(2026, 10, 5),
        calendar: cal
    )
    check(!BadgeRules.evaluateZeroGuilt(input: zeroGuiltDeficit), "zero_guilt: eksi bakiyeyle açılmaz")

    let zeroGuiltPositive = BadgeEvaluationInput(
        workouts: [WorkoutSnapshot(date: makeDate(2026, 10, 5, 10), calories: 1200, type: "Koşu")],
        treats: [TreatSnapshot(date: makeDate(2026, 10, 5, 14), calories: 1000, category: .burger)], // 1200 - 1000 = +200
        currentRollover: 0,
        openWeekStart: makeDate(2026, 10, 5),
        calendar: cal
    )
    check(BadgeRules.evaluateZeroGuilt(input: zeroGuiltPositive), "zero_guilt: >= 1000 kcal ve pozitif bakiye ile açılır")

    // 22. classic_duo: Aynı günde Burger + Bira
    let duoDifferentDays = BadgeEvaluationInput(
        workouts: [],
        treats: [
            TreatSnapshot(date: makeDate(2026, 10, 5, 12), calories: 500, category: .burger),
            TreatSnapshot(date: makeDate(2026, 10, 6, 18), calories: 150, category: .beer)
        ],
        calendar: cal
    )
    check(!BadgeRules.evaluateClassicDuo(input: duoDifferentDays), "classic_duo: farklı günlerde açılmaz")

    let duoSameDay = BadgeEvaluationInput(
        workouts: [],
        treats: [
            TreatSnapshot(date: makeDate(2026, 10, 5, 12), calories: 500, category: .burger),
            TreatSnapshot(date: makeDate(2026, 10, 5, 18), calories: 150, category: .beer)
        ],
        calendar: cal
    )
    check(BadgeRules.evaluateClassicDuo(input: duoSameDay), "classic_duo: aynı gün burger + birada açılır")

    // 23. tactical_pause: < 150 kcal
    let tacticalNegative = BadgeEvaluationInput(
        workouts: [],
        treats: [TreatSnapshot(date: makeDate(2026, 10, 5), calories: 150, category: .snack)],
        calendar: cal
    )
    check(!BadgeRules.evaluateTacticalPause(input: tacticalNegative), "tactical_pause: tam 150 kcal açılmaz")

    let tacticalPositive = BadgeEvaluationInput(
        workouts: [],
        treats: [TreatSnapshot(date: makeDate(2026, 10, 5), calories: 149, category: .snack)],
        calendar: cal
    )
    check(BadgeRules.evaluateTacticalPause(input: tacticalPositive), "tactical_pause: 149 kcal açılır")

    // 24. yin_yang: Aynı gün antrenman >= 600 ve kaçamak >= 600
    let yinYangNegative = BadgeEvaluationInput(
        workouts: [WorkoutSnapshot(date: makeDate(2026, 10, 5, 10), calories: 600, type: "Koşu")],
        treats: [TreatSnapshot(date: makeDate(2026, 10, 5, 14), calories: 599, category: .burger)],
        calendar: cal
    )
    check(!BadgeRules.evaluateYinYang(input: yinYangNegative), "yin_yang: kaçamak 599 kcal iken açılmaz")

    let yinYangPositive = BadgeEvaluationInput(
        workouts: [WorkoutSnapshot(date: makeDate(2026, 10, 5, 10), calories: 650, type: "Koşu")],
        treats: [TreatSnapshot(date: makeDate(2026, 10, 5, 14), calories: 600, category: .burger)],
        calendar: cal
    )
    check(BadgeRules.evaluateYinYang(input: yinYangPositive), "yin_yang: aynı gün 650 antrenman ve 600 kaçamakla açılır")

    // 25. night_owl: Cuma 23:00 - Cmt 04:00 veya Cmt 23:00 - Paz 04:00 kokteyl
    // 2026-10-09 (Cuma), 2026-10-10 (Cmt), 2026-10-11 (Paz)
    let fridayEarlyNight = BadgeEvaluationInput(
        workouts: [],
        treats: [TreatSnapshot(date: makeDate(2026, 10, 9, 22, 59), calories: 200, category: .cocktail)],
        calendar: cal
    )
    check(!BadgeRules.evaluateNightOwl(input: fridayEarlyNight), "night_owl: Cuma 22:59 açılmaz")

    let fridayNight = BadgeEvaluationInput(
        workouts: [],
        treats: [TreatSnapshot(date: makeDate(2026, 10, 9, 23, 30), calories: 200, category: .cocktail)],
        calendar: cal
    )
    check(BadgeRules.evaluateNightOwl(input: fridayNight), "night_owl: Cuma 23:30 açılır")

    let saturdayAfterMidnight = BadgeEvaluationInput(
        workouts: [],
        treats: [TreatSnapshot(date: makeDate(2026, 10, 10, 2, 15), calories: 200, category: .cocktail)],
        calendar: cal
    )
    check(BadgeRules.evaluateNightOwl(input: saturdayAfterMidnight), "night_owl: Cumartesi 02:15 (Cuma gecesi) açılır")

    let saturdayNight = BadgeEvaluationInput(
        workouts: [],
        treats: [TreatSnapshot(date: makeDate(2026, 10, 10, 23, 15), calories: 200, category: .cocktail)],
        calendar: cal
    )
    check(BadgeRules.evaluateNightOwl(input: saturdayNight), "night_owl: Cumartesi 23:15 açılır")

    let sundayAfterMidnight = BadgeEvaluationInput(
        workouts: [],
        treats: [TreatSnapshot(date: makeDate(2026, 10, 11, 3, 30), calories: 200, category: .cocktail)],
        calendar: cal
    )
    check(BadgeRules.evaluateNightOwl(input: sundayAfterMidnight), "night_owl: Pazar 03:30 (Cumartesi gecesi) açılır")

    let sundayMorning = BadgeEvaluationInput(
        workouts: [],
        treats: [TreatSnapshot(date: makeDate(2026, 10, 11, 4, 30), calories: 200, category: .cocktail)],
        calendar: cal
    )
    check(!BadgeRules.evaluateNightOwl(input: sundayMorning), "night_owl: Pazar 04:30 açılmaz")
}

// MARK: - SwiftData ve BadgeEvaluator Entegrasyon Testleri

@MainActor
func testBadgeEvaluatorEngine() throws {
    print("BadgeEvaluator Engine & SwiftData")

    let schema = Schema([
        Workout.self,
        TreatItem.self,
        TreatLog.self,
        WeekRecord.self,
        UserGamificationState.self,
        BadgeRecord.self,
    ])
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(for: schema, configurations: [config])
    let context = container.mainContext

    let unlockCenter = BadgeUnlockCenter()

    // Başlangıç: boş veritabanında değerlendirme
    var newlyUnlocked = try BadgeEvaluator.evaluate(context: context, now: makeDate(2026, 10, 5, 10), unlockCenter: unlockCenter)
    check(newlyUnlocked.isEmpty, "Boş veritabanında rozet açılmaz")
    check(unlockCenter.pendingBadges.isEmpty, "Kuyruk boş")

    // 1 antrenman ekle (500 kcal koşu)
    let workout1 = Workout(type: "Koşu", rawCalories: 500, date: makeDate(2026, 10, 5, 10), isSyncedFromHealth: false)
    context.insert(workout1)
    try context.save()

    newlyUnlocked = try BadgeEvaluator.evaluate(context: context, now: makeDate(2026, 10, 5, 10), unlockCenter: unlockCenter)
    let unlockedKeys = Set(newlyUnlocked.map { $0.badgeKey })
    check(unlockedKeys.contains("first_charge"), "İlk antrenmanda first_charge açıldı")
    check(unlockedKeys.contains("endless_battery"), "500 kcal ile endless_battery açıldı")
    check(unlockCenter.pendingBadges.count == newlyUnlocked.count, "UnlockCenter bekleyen kuyruğuna rozetler eklendi")

    // İdempotens testi: aynı verilerle tekrar çalıştırıldığında rozetler yinelenmemeli
    let secondRun = try BadgeEvaluator.evaluate(context: context, now: makeDate(2026, 10, 5, 11), unlockCenter: unlockCenter)
    check(secondRun.isEmpty, "İdempotens: ikinci çalıştırmada sıfır yeni rozet döner")

    let state = try WeekRolloverEngine.fetchOrCreateState(context: context)
    check(state.unlockedBadges.count == unlockedKeys.count, "State içindeki rozet sayısı duplike olmadan korundu")

    // Kaçamak ekle (Burger şablonu ve tüketim kaydı)
    let burgerItem = TreatItem(name: "Burger", calories: 400, icon: "🍔", category: .burger)
    context.insert(burgerItem)
    let treatLog1 = TreatLog(treat: burgerItem, date: makeDate(2026, 10, 5, 12))
    context.insert(treatLog1)
    try context.save()

    let thirdRun = try BadgeEvaluator.evaluate(context: context, now: makeDate(2026, 10, 5, 12), unlockCenter: unlockCenter)
    let thirdKeys = Set(thirdRun.map { $0.badgeKey })
    check(thirdKeys.contains("first_cheat"), "İlk kaçamakta first_cheat açıldı")
    check(thirdKeys.contains("cheat_happens"), "Bütçe pozitifken kaçamakta cheat_happens açıldı")
}

@main
struct Faz3Tests {
    @MainActor
    static func main() throws {
        testBadgeCatalog()
        testBadgeRules()
        try testBadgeEvaluatorEngine()

        print(failures == 0 ? "\nTÜM TESTLER GEÇTİ" : "\n\(failures) TEST BAŞARISIZ")
        exit(failures == 0 ? 0 : 1)
    }
}
