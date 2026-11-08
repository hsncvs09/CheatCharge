//
//  TreatCategory.swift
//  CheatCharge
//
//  Created by Hasan Cavusoglu on 03.10.2026.
//

import Foundation

/// Kaçamak şablonlarının kategorisi. Rozet kurallarında kullanılır
/// (örn. Burger Boss, Beer O'Clock, Cheat Collector).
enum TreatCategory: String, Codable, CaseIterable, Identifiable {
    case burger = "Burger"
    case pizza = "Pizza"
    case beer = "Bira"
    case cocktail = "Kokteyl / Alkol"
    case dessert = "Tatlı"
    case fastFood = "Fast Food"
    case snack = "Atıştırmalık"
    case drink = "İçecek"
    case other = "Diğer"

    var id: String { rawValue }

    /// Recommended default emoji when category is selected.
    var defaultIcon: String {
        switch self {
        case .burger:   return "🍔"
        case .pizza:    return "🍕"
        case .beer:     return "🍺"
        case .cocktail: return "🍸"
        case .dessert:  return "🍰"
        case .fastFood: return "🍟"
        case .snack:    return "🍿"
        case .drink:    return "🥤"
        case .other:    return "🍽️"
        }
    }

    /// English display title for Neobrutalist UI.
    var displayName: String {
        switch self {
        case .burger:   return "Burger"
        case .pizza:    return "Pizza"
        case .beer:     return "Beer"
        case .cocktail: return "Alcohol"
        case .dessert:  return "Dessert"
        case .fastFood: return "Fast Food"
        case .snack:    return "Snack"
        case .drink:    return "Drink"
        case .other:    return "Other"
        }
    }
}
