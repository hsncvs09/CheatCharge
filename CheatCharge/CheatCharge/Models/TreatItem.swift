//
//  TreatItem.swift
//  CheatCharge
//
//  Created by Hasan Cavusoglu on 24.09.2026.
//

import Foundation
import SwiftData

/// Kullanıcının önceden tanımladığı kaçamak şablonlarını temsil eder.
/// Örn: "Ev Yapımı Burger - 600 kcal", "Bira - 150 kcal"
@Model
final class TreatItem {
    var id: UUID
    /// Kaçamak adı (Burger, Pizza, Bira...)
    var name: String
    /// Kalorisi
    var calories: Double
    /// Emoji veya SF Symbol adı
    var icon: String
    /// v2: Kategori (`TreatCategory.rawValue`). Varsayılan değer, mevcut
    /// şablonların "Diğer" olarak migrate edilmesini sağlar.
    var categoryRaw: String = TreatCategory.other.rawValue
    /// Bu şablona bağlı tüketim kayıtları
    @Relationship(deleteRule: .cascade) var logs: [TreatLog]

    /// Tip güvenli kategori erişimi.
    var category: TreatCategory {
        get { TreatCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        name: String,
        calories: Double,
        icon: String = "🍔",
        category: TreatCategory = .other
    ) {
        self.id = id
        self.name = name
        self.calories = calories
        self.icon = icon
        self.categoryRaw = category.rawValue
        self.logs = []
    }
}
