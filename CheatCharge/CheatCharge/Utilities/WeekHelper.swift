//
//  WeekHelper.swift
//  CheatCharge
//
//  Created by Hasan Cavusoglu on 24.09.2026.
//

import Foundation

/// Aylık takvimdeki tek bir hafta satırını (Pazartesi - Pazar) temsil eder.
struct CalendarWeekRow: Identifiable, Equatable {
    var id: Date { weekStart }
    let weekStart: Date
    let weekEnd: Date
    let days: [Date]
}

/// Haftalık döngü hesaplamaları. Hafta her zaman **Pazartesi 00:00**'da başlar.
///
/// Saf, takvim tabanlı fonksiyonlardır; saklanan bir duruma bağlı değildir.
/// Hangi haftaların kapatıldığı bilgisi `UserGamificationState.openWeekStart`'ta tutulur.
enum WeekHelper {

    static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2 // 2 = Pazartesi
        return calendar
    }

    // MARK: - Hafta Sınırları

    /// `date`'i içeren haftanın Pazartesi 00:00 başlangıcı.
    static func weekStart(containing date: Date) -> Date {
        calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? calendar.startOfDay(for: date)
    }

    /// `start`'ta başlayan haftanın bitişi (DIŞLAYICI): bir sonraki Pazartesi 00:00.
    static func weekEnd(startingAt start: Date) -> Date {
        calendar.date(byAdding: .day, value: 7, to: start) ?? start.addingTimeInterval(7 * 86_400)
    }

    // MARK: - Mevcut Hafta

    /// Bu haftanın Pazartesi 00:00 tarihi.
    static func currentWeekStart(now: Date = Date()) -> Date {
        weekStart(containing: now)
    }

    /// Bu haftanın bitişi (dışlayıcı): bir sonraki Pazartesi 00:00.
    static func currentWeekEnd(now: Date = Date()) -> Date {
        weekEnd(startingAt: currentWeekStart(now: now))
    }

    /// Verilen tarih mevcut haftanın içinde mi?
    static func isInCurrentWeek(_ date: Date, now: Date = Date()) -> Bool {
        let start = currentWeekStart(now: now)
        return date >= start && date < weekEnd(startingAt: start)
    }

    /// Formats current week as "12 OCT - 18 OCT".
    static var weekRangeString: String {
        let start = currentWeekStart()
        let lastDay = calendar.date(byAdding: .day, value: 6, to: start) ?? start
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        formatter.locale = Locale(identifier: "en_US")
        return "\(formatter.string(from: start).uppercased()) - \(formatter.string(from: lastDay).uppercased())"
    }

    // MARK: - Aylık Takvim Yardımcıları

    /// Verilen tarihin (varsayılan: bugün) ait olduğu ayın başlangıç (1. gün 00:00) tarihini döndürür.
    static func monthStart(containing date: Date = Date()) -> Date {
        let components = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: components) ?? calendar.startOfDay(for: date)
    }

    /// İçinde bulunulan ayı kapsayan tüm Pazartesi-Pazar hafta satırlarını döndürür.
    static func monthWeekRows(for date: Date = Date()) -> [CalendarWeekRow] {
        let startOfMonth = monthStart(containing: date)
        guard let monthRange = calendar.range(of: .day, in: .month, for: startOfMonth),
              let lastDayOfMonth = calendar.date(byAdding: .day, value: monthRange.count - 1, to: startOfMonth)
        else { return [] }

        let firstWeekStart = weekStart(containing: startOfMonth)
        let lastWeekStart = weekStart(containing: lastDayOfMonth)

        var rows: [CalendarWeekRow] = []
        var cursor = firstWeekStart

        while cursor <= lastWeekStart {
            let days = (0..<7).compactMap { offset in
                calendar.date(byAdding: .day, value: offset, to: cursor)
            }
            let end = weekEnd(startingAt: cursor)
            rows.append(CalendarWeekRow(weekStart: cursor, weekEnd: end, days: days))
            guard let nextWeek = calendar.date(byAdding: .day, value: 7, to: cursor) else { break }
            cursor = nextWeek
        }
        return rows
    }
}
