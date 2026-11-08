//
//  BadgeRecord.swift
//  CheatCharge
//
//  Created by Hasan Cavusoglu on 03.10.2026.
//

import Foundation
import SwiftData

/// Kullanıcının kazandığı bir rozetin kaydı.
/// Rozet kataloğu (isim, açıklama, koşul) kodda tutulur (Faz 3);
/// burada yalnızca kazanım bilgisi saklanır.
@Model
final class BadgeRecord {
    var id: UUID
    /// Katalog anahtarı: "iron_will", "burger_boss" vb.
    var badgeKey: String
    var unlockedDate: Date
    /// Kilidin hangi olayla açıldığını anlatan kısa not (opsiyonel).
    var triggerNote: String?
    /// Sahibi olan durum kaydı (UserGamificationState.unlockedBadges'in tersi).
    var state: UserGamificationState?

    init(
        id: UUID = UUID(),
        badgeKey: String,
        unlockedDate: Date = Date(),
        triggerNote: String? = nil
    ) {
        self.id = id
        self.badgeKey = badgeKey
        self.unlockedDate = unlockedDate
        self.triggerNote = triggerNote
    }
}
