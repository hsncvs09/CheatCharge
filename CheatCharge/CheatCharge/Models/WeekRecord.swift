//
//  WeekRecord.swift
//  CheatCharge
//
//  Created by Hasan Cavusoglu on 03.10.2026.
//

import Foundation
import SwiftData

/// Kapanan bir haftanın değişmez (donuk) arşiv kaydı.
/// Hafta kapanışında `WeekRolloverEngine` tarafından oluşturulur (Faz 2).
/// Kapanmış haftalar sonradan düzenlenmez; arşiv ve devir zinciri sabittir.
@Model
final class WeekRecord {
    var id: UUID
    var weekStartDate: Date
    /// Haftanın bitişi (DIŞLAYICI sınır): bir sonraki haftanın başlangıcıyla aynıdır.
    var weekEndDate: Date
    /// Bu hafta kazanılan kalori (E_t, afterburn dahil)
    var earnedCalories: Double
    /// Bu hafta yapılan toplam harcama (S_t)
    var spentCalories: Double
    /// Önceki haftadan gelen devir (R_t)
    var rolloverReceived: Double
    /// Devirden arta kalan, kullanılmadığı için yanan kısım
    var rolloverRemaining: Double
    /// Bir sonraki haftaya devredilen bakiye (R_{t+1})
    var rolloverCarriedForward: Double
    /// Başarılı hafta mı? (E_t + R_t ≥ S_t ve E_t > 0)
    var isSuccessful: Bool

    /// Hafta sonu net bilanço: (E_t + R_t) - S_t
    var netBalance: Double {
        (earnedCalories + rolloverReceived) - spentCalories
    }

    init(
        id: UUID = UUID(),
        weekStartDate: Date,
        weekEndDate: Date,
        earnedCalories: Double,
        spentCalories: Double,
        rolloverReceived: Double,
        rolloverRemaining: Double,
        rolloverCarriedForward: Double,
        isSuccessful: Bool
    ) {
        self.id = id
        self.weekStartDate = weekStartDate
        self.weekEndDate = weekEndDate
        self.earnedCalories = earnedCalories
        self.spentCalories = spentCalories
        self.rolloverReceived = rolloverReceived
        self.rolloverRemaining = rolloverRemaining
        self.rolloverCarriedForward = rolloverCarriedForward
        self.isSuccessful = isSuccessful
    }
}
