//
//  BadgeRules.swift
//  CheatCharge
//
//  Created by Hasan Cavusoglu on 03.10.2026.
//

import Foundation

/// Antrenman kaydının rozet değerlendirmesinde kullanılan hafif snapshot modeli.
struct WorkoutSnapshot: Equatable {
    let date: Date
    /// Afterburn çarpanı dahil edilmiş yakılan kalori
    let calories: Double
    /// Antrenman türü ("Ağırlık", "Koşu", "Yürüyüş" vb.)
    let type: String
}

/// Kaçamak kaydının rozet değerlendirmesinde kullanılan hafif snapshot modeli.
struct TreatSnapshot: Equatable {
    let date: Date
    let calories: Double
    let category: TreatCategory
}

/// Rozet değerlendirme motoruna sağlanan girdi verileri.
struct BadgeEvaluationInput {
    let workouts: [WorkoutSnapshot]
    let treats: [TreatSnapshot]
    let currentRollover: Double
    let openWeekStart: Date
    let calendar: Calendar

    init(
        workouts: [WorkoutSnapshot],
        treats: [TreatSnapshot],
        currentRollover: Double = 0,
        openWeekStart: Date = WeekHelper.currentWeekStart(),
        calendar: Calendar = WeekHelper.calendar
    ) {
        self.workouts = workouts
        self.treats = treats
        self.currentRollover = currentRollover
        self.openWeekStart = openWeekStart
        self.calendar = calendar
    }
}

/// Rozet kurallarını işleten saf, durumsuz mantık motoru.
///
/// SwiftData'dan tamamen bağımsızdır; birim testleri doğrudan
/// snapshot modelleri üzerinden kolayca çalıştırılabilir.
enum BadgeRules {

    /// Tüm kuralları çalıştırır ve koşulları sağlanan tüm rozet anahtarlarını döndürür.
    static func evaluate(input: BadgeEvaluationInput) -> Set<String> {
        var unlocked = Set<String>()

        // Charge
        if evaluateFirstCharge(input: input) { unlocked.insert("first_charge") }
        if evaluateIronWill(input: input) { unlocked.insert("iron_will") }
        if evaluateEndlessBattery(input: input) { unlocked.insert("endless_battery") }
        if evaluateWeekendWarrior(input: input) { unlocked.insert("weekend_warrior") }
        if evaluateCharge7K(input: input) { unlocked.insert("charge_7k") }
        if evaluateCharge14K(input: input) { unlocked.insert("charge_14k") }
        if evaluateCharge28K(input: input) { unlocked.insert("charge_28k") }
        if evaluateChargeMachine(input: input) { unlocked.insert("charge_machine") }
        if evaluateEarlyCharger(input: input) { unlocked.insert("early_charger") }
        if evaluateNightCharger(input: input) { unlocked.insert("night_charger") }
        if evaluateOvercharged(input: input) { unlocked.insert("overcharged") }

        // Cheat
        if evaluateFirstCheat(input: input) { unlocked.insert("first_cheat") }
        if evaluateCheatHappens(input: input) { unlocked.insert("cheat_happens") }
        if evaluateBurgerBoss(input: input) { unlocked.insert("burger_boss") }
        if evaluatePizzaParty(input: input) { unlocked.insert("pizza_party") }
        if evaluateBeerOClock(input: input) { unlocked.insert("beer_oclock") }
        if evaluateCheatCollector(input: input) { unlocked.insert("cheat_collector") }
        if evaluateCheatWeekend(input: input) { unlocked.insert("cheat_weekend") }
        if evaluateAgaveSpirit(input: input) { unlocked.insert("agave_spirit") }
        if evaluateSugarComa(input: input) { unlocked.insert("sugar_coma") }
        if evaluateZeroGuilt(input: input) { unlocked.insert("zero_guilt") }
        if evaluateClassicDuo(input: input) { unlocked.insert("classic_duo") }
        if evaluateTacticalPause(input: input) { unlocked.insert("tactical_pause") }

        // Gizli (Secret)
        if evaluateYinYang(input: input) { unlocked.insert("yin_yang") }
        if evaluateNightOwl(input: input) { unlocked.insert("night_owl") }

        return unlocked
    }

    // MARK: - Charge Kuralları

    /// İlk antrenman kaydı
    static func evaluateFirstCharge(input: BadgeEvaluationInput) -> Bool {
        !input.workouts.isEmpty
    }

    /// Aynı takvim haftasında 3 farklı günde direnç (ağırlık) antrenmanı
    static func evaluateIronWill(input: BadgeEvaluationInput) -> Bool {
        let strengthWorkouts = input.workouts.filter { $0.type == "Ağırlık" }
        guard !strengthWorkouts.isEmpty else { return false }

        var daysByWeek: [Date: Set<Date>] = [:]
        for workout in strengthWorkouts {
            let week = weekStart(for: workout.date, calendar: input.calendar)
            let day = input.calendar.startOfDay(for: workout.date)
            daysByWeek[week, default: []].insert(day)
        }

        return daysByWeek.values.contains { $0.count >= 3 }
    }

    /// Tek seansta en az 500 kcal yakmak
    static func evaluateEndlessBattery(input: BadgeEvaluationInput) -> Bool {
        input.workouts.contains { $0.calories >= 500 }
    }

    /// Cumartesi veya Pazar günü tek seansta en az 400 kcal
    static func evaluateWeekendWarrior(input: BadgeEvaluationInput) -> Bool {
        input.workouts.contains { workout in
            let weekday = input.calendar.component(.weekday, from: workout.date)
            let isWeekend = (weekday == 1 || weekday == 7) // 1 = Pazar, 7 = Cumartesi
            return isWeekend && workout.calories >= 400
        }
    }

    /// Ömür boyu toplamda en az 7.000 kcal
    static func evaluateCharge7K(input: BadgeEvaluationInput) -> Bool {
        input.workouts.reduce(0) { $0 + $1.calories } >= 7_000
    }

    /// Ömür boyu toplamda en az 14.000 kcal
    static func evaluateCharge14K(input: BadgeEvaluationInput) -> Bool {
        input.workouts.reduce(0) { $0 + $1.calories } >= 14_000
    }

    /// Ömür boyu toplamda en az 28.000 kcal
    static func evaluateCharge28K(input: BadgeEvaluationInput) -> Bool {
        input.workouts.reduce(0) { $0 + $1.calories } >= 28_000
    }

    /// Bir takvim haftasında toplamda en az 1.500 kcal
    static func evaluateChargeMachine(input: BadgeEvaluationInput) -> Bool {
        var weeklyCalories: [Date: Double] = [:]
        for workout in input.workouts {
            let week = weekStart(for: workout.date, calendar: input.calendar)
            weeklyCalories[week, default: 0] += workout.calories
        }
        return weeklyCalories.values.contains { $0 >= 1_500 }
    }

    /// Sabah 06:00 - 09:00 arasında antrenman
    static func evaluateEarlyCharger(input: BadgeEvaluationInput) -> Bool {
        input.workouts.contains { workout in
            let hour = input.calendar.component(.hour, from: workout.date)
            return hour >= 6 && hour < 9
        }
    }

    /// Gece 21:00 - 00:00 arasında antrenman
    static func evaluateNightCharger(input: BadgeEvaluationInput) -> Bool {
        input.workouts.contains { workout in
            let hour = input.calendar.component(.hour, from: workout.date)
            return hour >= 21 && hour < 24
        }
    }

    /// Aynı takvim gününde toplamda en az 1.000 kcal
    static func evaluateOvercharged(input: BadgeEvaluationInput) -> Bool {
        var dailyCalories: [Date: Double] = [:]
        for workout in input.workouts {
            let day = input.calendar.startOfDay(for: workout.date)
            dailyCalories[day, default: 0] += workout.calories
        }
        return dailyCalories.values.contains { $0 >= 1_000 }
    }

    // MARK: - Cheat Kuralları

    /// İlk kaçamak kaydı
    static func evaluateFirstCheat(input: BadgeEvaluationInput) -> Bool {
        !input.treats.isEmpty
    }

    /// Bakiye pozitifken (kayıttan sonra canlı bakiye >= 0 ve havuz > 0) yapılan ilk kaçamak
    static func evaluateCheatHappens(input: BadgeEvaluationInput) -> Bool {
        guard !input.treats.isEmpty else { return false }

        // Haftalara göre grupla
        let workoutsByWeek = Dictionary(grouping: input.workouts) {
            weekStart(for: $0.date, calendar: input.calendar)
        }
        let treatsByWeek = Dictionary(grouping: input.treats) {
            weekStart(for: $0.date, calendar: input.calendar)
        }

        for (week, weekTreats) in treatsByWeek {
            let weekWorkouts = workoutsByWeek[week] ?? []
            let weekEarned = weekWorkouts.reduce(0) { $0 + $1.calories }
            let weekRollover = (week == input.openWeekStart) ? input.currentRollover : 0
            let pool = weekEarned + weekRollover
            guard pool > 0 else { continue }

            let sortedTreats = weekTreats.sorted { $0.date < $1.date }
            var cumulativeSpent: Double = 0
            for treat in sortedTreats {
                cumulativeSpent += treat.calories
                if cumulativeSpent <= pool {
                    return true
                }
            }
        }

        return false
    }

    /// 10 defa Burger kategorisinde kaçamak
    static func evaluateBurgerBoss(input: BadgeEvaluationInput) -> Bool {
        input.treats.filter { $0.category == .burger }.count >= 10
    }

    /// 10 defa Pizza kategorisinde kaçamak
    static func evaluatePizzaParty(input: BadgeEvaluationInput) -> Bool {
        input.treats.filter { $0.category == .pizza }.count >= 10
    }

    /// 10 defa Bira kategorisinde kaçamak
    static func evaluateBeerOClock(input: BadgeEvaluationInput) -> Bool {
        input.treats.filter { $0.category == .beer }.count >= 10
    }

    /// En az 6 farklı kategoride kaçamak
    static func evaluateCheatCollector(input: BadgeEvaluationInput) -> Bool {
        Set(input.treats.map { $0.category }).count >= 6
    }

    /// Cumartesi veya Pazar günü kaçamak kaydetmek
    static func evaluateCheatWeekend(input: BadgeEvaluationInput) -> Bool {
        input.treats.contains { treat in
            let weekday = input.calendar.component(.weekday, from: treat.date)
            return weekday == 1 || weekday == 7
        }
    }

    /// Kokteyl / Alkol kategorisinde kaçamak
    static func evaluateAgaveSpirit(input: BadgeEvaluationInput) -> Bool {
        input.treats.contains { $0.category == .cocktail }
    }

    /// Art arda 2 takvim günü Tatlı kategorisinde kaçamak
    static func evaluateSugarComa(input: BadgeEvaluationInput) -> Bool {
        let dessertTreats = input.treats.filter { $0.category == .dessert }
        let uniqueDays = Set(dessertTreats.map { input.calendar.startOfDay(for: $0.date) })
        guard uniqueDays.count >= 2 else { return false }

        let sortedDays = uniqueDays.sorted()
        for i in 0..<(sortedDays.count - 1) {
            let dayDiff = input.calendar.dateComponents([.day], from: sortedDays[i], to: sortedDays[i + 1]).day
            if dayDiff == 1 {
                return true
            }
        }

        return false
    }

    /// Tek günde en az 1.000 kcal kaçamak yapılmasına rağmen gün sonu bakiyesinin pozitif kalması
    static func evaluateZeroGuilt(input: BadgeEvaluationInput) -> Bool {
        let treatsByDay = Dictionary(grouping: input.treats) {
            input.calendar.startOfDay(for: $0.date)
        }

        let workoutsByWeek = Dictionary(grouping: input.workouts) {
            weekStart(for: $0.date, calendar: input.calendar)
        }
        let treatsByWeek = Dictionary(grouping: input.treats) {
            weekStart(for: $0.date, calendar: input.calendar)
        }

        for (day, dayTreats) in treatsByDay {
            let dayTotal = dayTreats.reduce(0) { $0 + $1.calories }
            guard dayTotal >= 1_000 else { continue }

            let week = weekStart(for: day, calendar: input.calendar)
            let weekWorkouts = workoutsByWeek[week] ?? []
            let weekEarned = weekWorkouts.reduce(0) { $0 + $1.calories }
            let weekRollover = (week == input.openWeekStart) ? input.currentRollover : 0
            let pool = weekEarned + weekRollover

            let allWeekTreats = treatsByWeek[week] ?? []
            let weekSpent = allWeekTreats.reduce(0) { $0 + $1.calories }

            // Tüm hafta bakiyesi pozitifse doğrudan geçerli
            if (pool - weekSpent) >= 0 {
                return true
            }

            // Ya da o günün sonu itibarıyla kümülatif bakiye pozitifse geçerli
            if let nextDayStart = input.calendar.date(byAdding: .day, value: 1, to: day) {
                let earnedUpToDay = weekWorkouts.filter { $0.date < nextDayStart }.reduce(0) { $0 + $1.calories }
                let spentUpToDay = allWeekTreats.filter { $0.date < nextDayStart }.reduce(0) { $0 + $1.calories }
                if (earnedUpToDay + weekRollover - spentUpToDay) >= 0 {
                    return true
                }
            }
        }

        return false
    }

    /// Aynı takvim gününde hem Burger hem Bira kaçamağı
    static func evaluateClassicDuo(input: BadgeEvaluationInput) -> Bool {
        let treatsByDay = Dictionary(grouping: input.treats) {
            input.calendar.startOfDay(for: $0.date)
        }

        for dayTreats in treatsByDay.values {
            let hasBurger = dayTreats.contains { $0.category == .burger }
            let hasBeer = dayTreats.contains { $0.category == .beer }
            if hasBurger && hasBeer {
                return true
            }
        }

        return false
    }

    /// 150 kcal altı ufak kaçamak
    static func evaluateTacticalPause(input: BadgeEvaluationInput) -> Bool {
        input.treats.contains { $0.calories < 150 }
    }

    // MARK: - Gizli (Secret) Kurallar

    /// Aynı takvim gününde hem antrenman >= 600 hem kaçamak >= 600
    static func evaluateYinYang(input: BadgeEvaluationInput) -> Bool {
        var workoutDaily: [Date: Double] = [:]
        for workout in input.workouts {
            let day = input.calendar.startOfDay(for: workout.date)
            workoutDaily[day, default: 0] += workout.calories
        }

        var treatDaily: [Date: Double] = [:]
        for treat in input.treats {
            let day = input.calendar.startOfDay(for: treat.date)
            treatDaily[day, default: 0] += treat.calories
        }

        for (day, workoutCal) in workoutDaily where workoutCal >= 600 {
            if let treatCal = treatDaily[day], treatCal >= 600 {
                return true
            }
        }

        return false
    }

    /// Cuma 23:00 - Cumartesi 04:00 veya Cumartesi 23:00 - Pazar 04:00 kokteyl kaydı
    static func evaluateNightOwl(input: BadgeEvaluationInput) -> Bool {
        let cocktails = input.treats.filter { $0.category == .cocktail }
        return cocktails.contains { treat in
            let weekday = input.calendar.component(.weekday, from: treat.date)
            let hour = input.calendar.component(.hour, from: treat.date)

            // 1 = Pazar, 6 = Cuma, 7 = Cumartesi
            let isFridayNight = (weekday == 6 && hour == 23) || (weekday == 7 && hour < 4)
            let isSaturdayNight = (weekday == 7 && hour == 23) || (weekday == 1 && hour < 4)

            return isFridayNight || isSaturdayNight
        }
    }

    // MARK: - Yardımcı Fonksiyonlar

    private static func weekStart(for date: Date, calendar: Calendar) -> Date {
        calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? calendar.startOfDay(for: date)
    }
}
