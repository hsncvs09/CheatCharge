//
//  Faz4LogicTests.swift
//  DevTools
//
//  Created by Hasan Cavusoglu on 03.10.2026.
//

import Foundation

nonisolated(unsafe) var failures = 0

func check(_ condition: Bool, _ message: String, line: Int = #line) {
    if condition {
        print("  ✓ \(message)")
    } else {
        failures += 1
        print("  ✗ BAŞARISIZ: \(message) (satır \(line))")
    }
}

func testLiquidGlassCalculator() {
    print("LiquidGlassCalculator (210 kcal Modüler Sıvı Bardağı & Çarpan)")

    // 1. Negatif Değerler (Açık / Deficit)
    var m = LiquidGlassCalculator.compute(remainingCalories: -150)
    check(m.isDeficit == true, "-150 kcal: isDeficit == true")
    check(m.fillRatio == 0.0, "-150 kcal: fillRatio == 0.0 (bardak boş)")
    check(m.currentCupCalories == 0.0, "-150 kcal: currentCupCalories == 0.0")
    check(m.fullCups == 0, "-150 kcal: fullCups == 0")
    check(m.hasMultiplier == false, "-150 kcal: hasMultiplier == false")
    check(m.multiplierText == nil, "-150 kcal: multiplierText == nil")

    m = LiquidGlassCalculator.compute(remainingCalories: -1)
    check(m.isDeficit == true && m.fillRatio == 0.0, "-1 kcal: açık durumu korunur")

    // 2. Sıfır Bakiye (Nötr / Boş)
    m = LiquidGlassCalculator.compute(remainingCalories: 0)
    check(m.isDeficit == false, "0 kcal: isDeficit == false")
    check(m.fillRatio == 0.0, "0 kcal: fillRatio == 0.0")
    check(m.currentCupCalories == 0.0, "0 kcal: currentCupCalories == 0.0")
    check(m.hasMultiplier == false, "0 kcal: çarpan yok")

    // 3. Tek Bardak Altı Değerler (< 210 kcal)
    m = LiquidGlassCalculator.compute(remainingCalories: 105)
    check(m.isDeficit == false, "105 kcal: açık yok")
    check(abs(m.fillRatio - 0.5) < 0.001, "105 kcal: tam yarım bardak (%50 doluluk)")
    check(m.currentCupCalories == 105.0, "105 kcal: bardak kalorisi 105")
    check(m.fullCups == 0, "105 kcal: 0 tam bardak")
    check(m.hasMultiplier == false, "105 kcal: çarpan yok (< 420)")

    m = LiquidGlassCalculator.compute(remainingCalories: 84)
    check(abs(m.fillRatio - 0.4) < 0.001, "84 kcal: %40 doluluk")
    check(m.currentCupCalories == 84.0, "84 kcal: bardak kalorisi 84")

    // 4. Tam 1 Bardak (210 kcal)
    m = LiquidGlassCalculator.compute(remainingCalories: 210)
    check(m.isDeficit == false, "210 kcal: açık yok")
    check(m.fillRatio == 1.0, "210 kcal: bardak %100 tam dolu")
    check(m.currentCupCalories == 210.0, "210 kcal: bardak kalorisi 210")
    check(m.fullCups == 1, "210 kcal: 1 tam bardak")
    check(m.hasMultiplier == true, "210 kcal: çarpan var (1x)")
    check(m.multiplierText == "1x", "210 kcal: multiplierText == '1x'")

    // 5. 1 ile 2 Bardak Arası (210 - 420 kcal)
    m = LiquidGlassCalculator.compute(remainingCalories: 315)
    check(m.fullCups == 1, "315 kcal: 1 tam bardak")
    check(abs(m.fillRatio - 0.5) < 0.001, "315 kcal: 2. bardak %50 dolu (105/210)")
    check(m.currentCupCalories == 105.0, "315 kcal: 2. bardaktaki kalori 105")
    check(m.hasMultiplier == true, "315 kcal: çarpan var (1x yedekte)")
    check(m.multiplierText == "1x", "315 kcal: multiplierText == '1x'")

    // 6. Tam 2 Bardak (420 kcal) -> 2x Başlangıcı
    m = LiquidGlassCalculator.compute(remainingCalories: 420)
    check(m.fullCups == 2, "420 kcal: 2 tam bardak")
    check(m.fillRatio == 1.0, "420 kcal: bardak %100 dolu")
    check(m.currentCupCalories == 210.0, "420 kcal: bardak kalorisi 210")
    check(m.hasMultiplier == true, "420 kcal: hasMultiplier == true")
    check(m.multiplierText == "2x", "420 kcal: multiplierText == '2x'")

    // 7. Plandaki Referans Senaryo: 500 kcal
    // "Bardağın önünde neon '2x' çarpan rozeti. Bardak içi ise 500 - (2 * 210) = 80 kcal seviyesinde (%38 dolu) dalgalanır."
    m = LiquidGlassCalculator.compute(remainingCalories: 500)
    check(m.fullCups == 2, "500 kcal: 2 tam bardak")
    check(m.currentCupCalories == 80.0, "500 kcal: bardak içi 80 kcal")
    check(abs(m.fillRatio - (80.0 / 210.0)) < 0.001, "500 kcal: %38.1 doluluk oranı")
    check(m.hasMultiplier == true, "500 kcal: hasMultiplier == true")
    check(m.multiplierText == "2x", "500 kcal: multiplierText == '2x'")

    // 8. Tam 3 Bardak (630 kcal)
    m = LiquidGlassCalculator.compute(remainingCalories: 630)
    check(m.fullCups == 3, "630 kcal: 3 tam bardak")
    check(m.fillRatio == 1.0, "630 kcal: bardak %100 dolu")
    check(m.hasMultiplier == true, "630 kcal: hasMultiplier == true")
    check(m.multiplierText == "3x", "630 kcal: multiplierText == '3x'")

    // 9. 3 Bardak Üstü (750 kcal)
    m = LiquidGlassCalculator.compute(remainingCalories: 750)
    check(m.fullCups == 3, "750 kcal: 3 tam bardak")
    check(m.currentCupCalories == 120.0, "750 kcal: bardak içi 120 kcal")
    check(abs(m.fillRatio - (120.0 / 210.0)) < 0.001, "750 kcal: %57.1 doluluk oranı")
    check(m.hasMultiplier == true && m.multiplierText == "3x", "750 kcal: multiplierText == '3x'")
}

@main
struct Faz4Tests {
    static func main() {
        testLiquidGlassCalculator()
        print(failures == 0 ? "\nTÜM TESTLER GEÇTİ" : "\n\(failures) TEST BAŞARISIZ")
        exit(failures == 0 ? 0 : 1)
    }
}
