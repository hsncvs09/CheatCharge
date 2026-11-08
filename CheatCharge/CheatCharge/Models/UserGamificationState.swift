//
//  UserGamificationState.swift
//  CheatCharge
//
//  Created by Hasan Cavusoglu on 03.10.2026.
//

import Foundation
import SwiftData

/// Kullanıcının kalıcı ilerleme durumu. Uygulamada tek bir kayıt (singleton) bulunur.
@Model
final class UserGamificationState {
    var id: UUID
    /// Kalıcı bileklik seviyesini belirler. Sadece artar, asla düşmez.
    var totalSuccessfulWeeks: Int
    /// Anlık motivasyon alev sayacı (🔥). Kural bozulduğunda 0'a döner.
    var currentStreak: Int
    /// Bu hafta kullanılabilir devir kredisi (FIFO ile önce bundan harcanır).
    var currentRolloverBalance: Double
    /// Henüz kapatılmamış en eski haftanın başlangıcı (Pazartesi 00:00).
    /// Bu tarihten ÖNCEKİ haftalar kapatılmıştır. Hafta kaydıyla AYNI `save()` içinde
    /// ilerletilir, bu yüzden arşiv ile ilerleme hiçbir zaman tutarsız kalmaz.
    /// İlk değer, içinde bulunulan haftanın başıdır ("sıfırdan başla").
    var openWeekStart: Date

    @Relationship(deleteRule: .cascade, inverse: \BadgeRecord.state)
    var unlockedBadges: [BadgeRecord]

    init(
        id: UUID = UUID(),
        totalSuccessfulWeeks: Int = 0,
        currentStreak: Int = 0,
        currentRolloverBalance: Double = 0,
        openWeekStart: Date = WeekHelper.currentWeekStart()
    ) {
        self.id = id
        self.totalSuccessfulWeeks = totalSuccessfulWeeks
        self.currentStreak = currentStreak
        self.currentRolloverBalance = currentRolloverBalance
        self.openWeekStart = openWeekStart
        self.unlockedBadges = []
    }
}
