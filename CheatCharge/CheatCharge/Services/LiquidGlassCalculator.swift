//
//  LiquidGlassCalculator.swift
//  CheatCharge
//
//  Created by Hasan Cavusoglu on 03.10.2026.
//

import Foundation

/// Sıvı bardağı doluluk ve çarpan hesaplama çıktısı.
struct LiquidCupMetrics: Equatable {
    /// Bütçe açıkta mı? (Bakiye < 0)
    let isDeficit: Bool
    /// Tamamlanmış tam bardak sayısı (örn. 500 kcal için 2 adet 210 kcal)
    let fullCups: Int
    /// Mevcut bardağın doluluk oranı (0.0 – 1.0)
    let fillRatio: Double
    /// Mevcut bardaktaki kalori miktarı (0 – 210 kcal)
    let currentCupCalories: Double
    /// Çarpan rozeti gösterilmeli mi? (En az 1 tam bardak yedekte/tamamlanmış: >= 210 kcal)
    let hasMultiplier: Bool
    /// Çarpan metni ("1x", "2x", "3x" vb.)
    let multiplierText: String?
}

/// 210 kcal modüler sıvı bardağının doluluk oranını ve çarpanını hesaplayan saf matematik motoru.
///
/// SwiftData ve UI'dan tamamen bağımsızdır; birim testleri ve WidgetKit paylaşımı için uygundur.
enum LiquidGlassCalculator {

    /// Bir bardağın tam kalori hacmi (210 kcal)
    static let cupVolume: Double = 210.0

    /// Verilen net kalan bakiye için bardak metriklerini hesaplar.
    static func compute(remainingCalories: Double) -> LiquidCupMetrics {
        if remainingCalories < 0 {
            return LiquidCupMetrics(
                isDeficit: true,
                fullCups: 0,
                fillRatio: 0.0,
                currentCupCalories: 0.0,
                hasMultiplier: false,
                multiplierText: nil
            )
        }

        if remainingCalories == 0 {
            return LiquidCupMetrics(
                isDeficit: false,
                fullCups: 0,
                fillRatio: 0.0,
                currentCupCalories: 0.0,
                hasMultiplier: false,
                multiplierText: nil
            )
        }

        let fullCount = Int(remainingCalories / cupVolume)
        let remainder = remainingCalories.truncatingRemainder(dividingBy: cupVolume)

        let fillRatio: Double
        let currentCupCalories: Double
        let fullCupsForMultiplier: Int

        if remainder == 0 {
            // Tam katı ise (örn. 210, 420 kcal) bardak tamamen doludur
            fillRatio = 1.0
            currentCupCalories = cupVolume
            fullCupsForMultiplier = fullCount
        } else {
            fillRatio = remainder / cupVolume
            currentCupCalories = remainder
            fullCupsForMultiplier = fullCount
        }

        // Çarpan rozeti en az 1 tam bardak tamamlandığında görünür (>= 210 kcal)
        let hasMultiplier = fullCupsForMultiplier >= 1
        let multiplierText = hasMultiplier ? "\(fullCupsForMultiplier)x" : nil

        return LiquidCupMetrics(
            isDeficit: false,
            fullCups: fullCount,
            fillRatio: min(max(fillRatio, 0.0), 1.0),
            currentCupCalories: currentCupCalories,
            hasMultiplier: hasMultiplier,
            multiplierText: multiplierText
        )
    }
}
