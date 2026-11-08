//
//  WristbandTier.swift
//  CheatCharge
//
//  Created by Hasan Cavusoglu on 03.10.2026.
//

import SwiftUI

/// Kullanıcının kümülatif başarılı hafta sayısına göre kazandığı kalıcı bileklik seviyesi.
///
/// Seviyeler kümülatiftir, peş peşe olma şartı yoktur ve **asla düşmez**.
enum WristbandTier: String, CaseIterable, Identifiable, Comparable {
    case white = "white"
    case green = "green"
    case blue = "blue"
    case red = "red"
    case purple = "purple"
    case gold = "gold"
    case black = "black"

    var id: String { rawValue }

    /// Kademeye ulaşmak için gereken kümülatif başarılı hafta sayısı
    var requiredWeeks: Int {
        switch self {
        case .white: return 0
        case .green: return 2
        case .blue: return 4
        case .red: return 8
        case .purple: return 12
        case .gold: return 24
        case .black: return 52
        }
    }

    /// Bileklik Türkçe adı
    var title: String {
        switch self {
        case .white: return "Beyaz Bileklik"
        case .green: return "Yeşil Bileklik"
        case .blue: return "Mavi Bileklik"
        case .red: return "Kırmızı Bileklik"
        case .purple: return "Mor Bileklik"
        case .gold: return "Altın Bileklik"
        case .black: return "Siyah Bileklik"
        }
    }

    /// Bileklik English name (Neobrutalism UI)
    var englishTitle: String {
        switch self {
        case .white: return "White Wristband"
        case .green: return "Green Wristband"
        case .blue: return "Blue Wristband"
        case .red: return "Red Wristband"
        case .purple: return "Purple Wristband"
        case .gold: return "Gold Wristband"
        case .black: return "Master Wristband"
        }
    }

    /// Bileklik unvanı
    var subtitle: String {
        switch self {
        case .white: return "Çaylak"
        case .green: return "Başlangıç"
        case .blue: return "Disiplin"
        case .red: return "Kararlılık"
        case .purple: return "Launch Control"
        case .gold: return "Elit"
        case .black: return "Yenilmez (You vs. You)"
        }
    }

    /// Bileklik English subtitle
    var englishSubtitle: String {
        switch self {
        case .white: return "Rookie / Beginner Tier"
        case .green: return "Starter / Base Pace"
        case .blue: return "Discipline"
        case .red: return "Determination"
        case .purple: return "Launch Control"
        case .gold: return "Elite"
        case .black: return "Elite Titan (You vs. You)"
        }
    }

    /// Renk hex kodu (WidgetKit ve paylaşım için)
    var colorHex: String {
        switch self {
        case .white: return "#FFFFFF"
        case .green: return "#22C55E"
        case .blue: return "#3B82F6"
        case .red: return "#EF4444"
        case .purple: return "#A855F7"
        case .gold: return "#EAB308"
        case .black: return "#111827"
        }
    }

    /// SwiftUI ana rengi
    var color: Color {
        switch self {
        case .white: return Color(white: 0.95)
        case .green: return CyberTheme.neonGreen
        case .blue: return CyberTheme.neonCyan
        case .red: return CyberTheme.neonRed
        case .purple: return CyberTheme.neonPurple
        case .gold: return CyberTheme.neonOrange
        case .black: return Color(red: 0.11, green: 0.13, blue: 0.18)
        }
    }

    /// Işıma ve kenarlık rengi
    var glowColor: Color {
        switch self {
        case .white: return Color.white.opacity(0.6)
        case .green: return CyberTheme.neonGreen.opacity(0.7)
        case .blue: return CyberTheme.neonCyan.opacity(0.7)
        case .red: return CyberTheme.neonRed.opacity(0.7)
        case .purple: return CyberTheme.neonPurple.opacity(0.7)
        case .gold: return CyberTheme.neonOrange.opacity(0.7)
        case .black: return CyberTheme.neonGreen.opacity(0.8) // Siyah bilekliğin cyber neon çerçevesi
        }
    }

    /// SF Symbol ikonu
    var icon: String {
        switch self {
        case .white: return "circle"
        case .green: return "leaf.fill"
        case .blue: return "bolt.fill"
        case .red: return "flame.fill"
        case .purple: return "speedometer"
        case .gold: return "crown.fill"
        case .black: return "trophy.fill"
        }
    }

    // MARK: - Hesaplama ve Navigasyon Mantığı

    /// Verilen başarılı hafta sayısına göre güncel aktif bilekliği hesaplar.
    static func current(for totalSuccessfulWeeks: Int) -> WristbandTier {
        let sorted = allCases.sorted(by: { $0.requiredWeeks < $1.requiredWeeks })
        var currentTier = sorted[0]
        for tier in sorted {
            if totalSuccessfulWeeks >= tier.requiredWeeks {
                currentTier = tier
            } else {
                break
            }
        }
        return currentTier
    }

    /// Bir sonraki hedef kademe (en son kademede nil)
    var nextTier: WristbandTier? {
        let all = WristbandTier.allCases.sorted(by: { $0.requiredWeeks < $1.requiredWeeks })
        guard let index = all.firstIndex(of: self), index + 1 < all.count else { return nil }
        return all[index + 1]
    }

    /// Bir sonraki kademeye ilerleme yüzdesi (0.0 ... 1.0)
    static func progressToNext(for totalSuccessfulWeeks: Int) -> Double {
        let currentTier = current(for: totalSuccessfulWeeks)
        guard let next = currentTier.nextTier else { return 1.0 }
        let start = currentTier.requiredWeeks
        let end = next.requiredWeeks
        guard end > start else { return 1.0 }
        let progress = Double(totalSuccessfulWeeks - start) / Double(end - start)
        return min(max(progress, 0.0), 1.0)
    }

    /// Bir sonraki kademeye ulaşmak için kalan başarılı hafta adedi
    static func weeksRemaining(for totalSuccessfulWeeks: Int) -> Int {
        let currentTier = current(for: totalSuccessfulWeeks)
        guard let next = currentTier.nextTier else { return 0 }
        return max(0, next.requiredWeeks - totalSuccessfulWeeks)
    }

    // MARK: - Comparable
    static func < (lhs: WristbandTier, rhs: WristbandTier) -> Bool {
        lhs.requiredWeeks < rhs.requiredWeeks
    }
}
