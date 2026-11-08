//
//  Faz5LogicTests.swift
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

func testWristbandTiers() {
    print("WristbandTier (Kümülatif Seviye Vitrini & Bileklik Yolculuğu)")

    // 1. Hafta 0 (Çaylak)
    var tier = WristbandTier.current(for: 0)
    check(tier == .white, "0 hafta: Beyaz Bileklik")
    check(tier.title == "Beyaz Bileklik" && tier.subtitle == "Çaylak", "0 hafta: Başlık ve unvan doğru")
    check(tier.nextTier == .green, "0 hafta: Sonraki kademe Yeşil")
    check(WristbandTier.weeksRemaining(for: 0) == 2, "0 hafta: Yeşile 2 hafta kaldı")
    check(WristbandTier.progressToNext(for: 0) == 0.0, "0 hafta: İlerleme 0.0")

    // 2. Hafta 1
    tier = WristbandTier.current(for: 1)
    check(tier == .white, "1 hafta: Hâlâ Beyaz Bileklik")
    check(WristbandTier.weeksRemaining(for: 1) == 1, "1 hafta: Yeşile 1 hafta kaldı")
    check(abs(WristbandTier.progressToNext(for: 1) - 0.5) < 0.001, "1 hafta: İlerleme %50")

    // 3. Hafta 2 (Yeşil - Başlangıç)
    tier = WristbandTier.current(for: 2)
    check(tier == .green, "2 hafta: Yeşil Bileklik")
    check(tier.subtitle == "Başlangıç", "2 hafta: Başlangıç unvanı")
    check(tier.nextTier == .blue, "2 hafta: Sonraki kademe Mavi")
    check(WristbandTier.weeksRemaining(for: 2) == 2, "2 hafta: Maviye 2 hafta kaldı (4-2)")
    check(WristbandTier.progressToNext(for: 2) == 0.0, "2 hafta: İlerleme 0.0")

    // 4. Hafta 3
    tier = WristbandTier.current(for: 3)
    check(tier == .green, "3 hafta: Yeşil Bileklik")
    check(WristbandTier.weeksRemaining(for: 3) == 1, "3 hafta: Maviye 1 hafta kaldı")
    check(abs(WristbandTier.progressToNext(for: 3) - 0.5) < 0.001, "3 hafta: İlerleme %50")

    // 5. Hafta 4 (Mavi - Disiplin)
    tier = WristbandTier.current(for: 4)
    check(tier == .blue, "4 hafta: Mavi Bileklik")
    check(tier.subtitle == "Disiplin", "4 hafta: Disiplin unvanı")
    check(tier.nextTier == .red, "4 hafta: Sonraki Kırmızı (8 hafta)")
    check(WristbandTier.weeksRemaining(for: 4) == 4, "4 hafta: Kırmızıya 4 hafta kaldı (8-4)")

    // 6. Hafta 8 (Kırmızı - Kararlılık)
    tier = WristbandTier.current(for: 8)
    check(tier == .red, "8 hafta: Kırmızı Bileklik")
    check(tier.subtitle == "Kararlılık", "8 hafta: Kararlılık unvanı")
    check(tier.nextTier == .purple, "8 hafta: Sonraki Mor (12 hafta)")
    check(WristbandTier.weeksRemaining(for: 8) == 4, "8 hafta: Mora 4 hafta kaldı (12-8)")

    // 7. Hafta 12 (Mor - Launch Control)
    tier = WristbandTier.current(for: 12)
    check(tier == .purple, "12 hafta: Mor Bileklik")
    check(tier.subtitle == "Launch Control", "12 hafta: Launch Control unvanı")
    check(tier.nextTier == .gold, "12 hafta: Sonraki Altın (24 hafta)")
    check(WristbandTier.weeksRemaining(for: 12) == 12, "12 hafta: Altına 12 hafta kaldı (24-12)")

    // 8. Hafta 24 (Altın - Elit)
    tier = WristbandTier.current(for: 24)
    check(tier == .gold, "24 hafta: Altın Bileklik")
    check(tier.subtitle == "Elit", "24 hafta: Elit unvanı")
    check(tier.nextTier == .black, "24 hafta: Sonraki Siyah (52 hafta)")
    check(WristbandTier.weeksRemaining(for: 24) == 28, "24 hafta: Siyaha 28 hafta kaldı (52-24)")

    // 9. Hafta 52 (Siyah - Yenilmez)
    tier = WristbandTier.current(for: 52)
    check(tier == .black, "52 hafta: Siyah Bileklik")
    check(tier.subtitle == "Yenilmez (You vs. You)", "52 hafta: Yenilmez unvanı")
    check(tier.nextTier == nil, "52 hafta: Zirve kademe, sonraki yok")
    check(WristbandTier.weeksRemaining(for: 52) == 0, "52 hafta: Kalan 0")
    check(WristbandTier.progressToNext(for: 52) == 1.0, "52 hafta: İlerleme %100")

    // 10. 52 Hafta Üstü (örn. 75 hafta)
    tier = WristbandTier.current(for: 75)
    check(tier == .black, "75 hafta: Siyah Bileklik korunur")
    check(WristbandTier.progressToNext(for: 75) == 1.0, "75 hafta: İlerleme %100")
}

@main
struct Faz5Tests {
    static func main() {
        testWristbandTiers()
        print(failures == 0 ? "\nTÜM TESTLER GEÇTİ" : "\n\(failures) TEST BAŞARISIZ")
        exit(failures == 0 ? 0 : 1)
    }
}
