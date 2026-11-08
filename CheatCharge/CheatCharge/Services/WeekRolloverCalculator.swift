//
//  WeekRolloverCalculator.swift
//  CheatCharge
//
//  Created by Hasan Cavusoglu on 03.10.2026.
//

import Foundation

/// Hafta kapanış matematiği. SwiftData'dan bağımsız saf hesaplamadır; birim testi kolaydır.
///
/// Değişkenler (plan 1.1):
/// - E: bu hafta kazanılan kalori (afterburn dahil)
/// - R: geçen haftadan devreden bakiye
/// - S: bu hafta yapılan toplam harcama
///
/// FIFO kuralı: Harcama önce devirden (R), sonra bu haftanın kazanımından (E) düşer.
/// Devirden arta kalan kısım yanar; bir sonraki haftaya yalnızca bu haftanın
/// harcanmayan kazanımı taşınır (zincirleme devir yoktur).
struct WeekRolloverResult: Equatable {
    /// R: gelen devir
    let rolloverReceived: Double
    /// min(S, R): devirden harcanan
    let spentFromRollover: Double
    /// max(0, S - R): bu haftanın kazanımından harcanan
    let spentFromCurrent: Double
    /// R - min(S, R): kullanılmadığı için yanan devir
    let rolloverExpired: Double
    /// max(0, E - spentFromCurrent): bir sonraki haftaya devredilen bakiye
    let carriedForward: Double
    /// (E + R) ≥ S ve E > 0
    let isSuccessful: Bool
}

enum WeekRolloverCalculator {

    static func close(earned: Double, spent: Double, rollover: Double) -> WeekRolloverResult {
        // Negatif girişlere karşı savunma (veri hatası durumunda).
        let earned = max(0, earned)
        let spent = max(0, spent)
        let rollover = max(0, rollover)

        let spentFromRollover = min(spent, rollover)
        let spentFromCurrent = max(0, spent - rollover)
        let carriedForward = max(0, earned - spentFromCurrent)
        let isSuccessful = (earned + rollover) >= spent && earned > 0

        return WeekRolloverResult(
            rolloverReceived: rollover,
            spentFromRollover: spentFromRollover,
            spentFromCurrent: spentFromCurrent,
            rolloverExpired: rollover - spentFromRollover,
            carriedForward: carriedForward,
            isSuccessful: isSuccessful
        )
    }

    /// Dashboard için canlı bakiye: R + E - S
    static func liveBalance(earned: Double, spent: Double, rollover: Double) -> Double {
        rollover + earned - spent
    }
}
