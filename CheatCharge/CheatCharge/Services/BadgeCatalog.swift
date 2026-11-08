//
//  BadgeCatalog.swift
//  CheatCharge
//
//  Created by Hasan Cavusoglu on 03.10.2026.
//

import Foundation

/// Rozetlerin ait olduğu ana kategori.
enum BadgeCategory: String, Codable, CaseIterable, Identifiable {
    case charge = "Charge"
    case cheat = "Cheat"
    case secret = "Gizli"

    var id: String { rawValue }

    /// English display name for Neobrutalism UI
    var displayName: String {
        switch self {
        case .charge: return "Charge"
        case .cheat: return "Cheat"
        case .secret: return "Secret"
        }
    }

    /// Kategoriye uygun simge.
    var icon: String {
        switch self {
        case .charge: return "bolt.fill"
        case .cheat: return "flame.fill"
        case .secret: return "lock.fill"
        }
    }
}

/// Uygulamadaki bir rozetin sabit metaveri tanımı.
struct BadgeDefinition: Identifiable, Equatable, Hashable {
    var id: String { key }

    /// Veritabanı ve mantık motorundaki benzersiz anahtar ("iron_will", "burger_boss" vb.)
    let key: String

    /// Kullanıcıya gösterilen Türkçe başlık
    let title: String

    /// Rozetin kazanım şartını açıklayan detay metni
    let detail: String

    /// Ana kategori (Charge, Cheat, Gizli)
    let category: BadgeCategory

    /// Kilit açılana kadar detayları gizlenen sürpriz başarımlar için true
    var isSecret: Bool

    /// English display title
    var englishTitle: String {
        switch key {
        case "first_charge": return "First Charge"
        case "iron_will": return "Iron Will"
        case "endless_battery": return "Endless Battery"
        case "weekend_warrior": return "Weekend Warrior"
        case "charge_7k": return "7K Charge"
        case "charge_14k": return "14K Charge"
        case "charge_28k": return "28K Charge"
        case "charge_machine": return "Charge Machine"
        case "early_charger": return "Early Charger"
        case "night_charger": return "Night Charger"
        case "overcharged": return "Overcharged"
        case "first_cheat": return "First Cheat"
        case "cheat_happens": return "Cheat Happens"
        case "burger_boss": return "Burger Boss"
        case "pizza_party": return "Pizza Party"
        case "beer_oclock": return "Beer O'Clock"
        case "cheat_collector": return "Cheat Collector"
        case "cheat_weekend": return "Cheat Weekend"
        case "agave_spirit": return "Agave Spirit"
        case "sugar_coma": return "Sugar Coma"
        case "zero_guilt": return "Zero Guilt"
        case "classic_duo": return "Classic Duo"
        case "tactical_pause": return "Tactical Pause"
        case "yin_yang": return "Yin & Yang"
        case "night_owl": return "Night Owl"
        default: return title
        }
    }

    /// English achievement requirement detail
    var englishDetail: String {
        switch key {
        case "first_charge": return "Logged your first workout and initiated your budget."
        case "iron_will": return "Completed strength workouts on 3 different days in one week."
        case "endless_battery": return "Burned at least 500 kcal in a single session."
        case "weekend_warrior": return "Burned 400+ kcal in a single weekend session."
        case "charge_7k": return "Surpassed 7,000 kcal total active burn milestone."
        case "charge_14k": return "Surpassed 14,000 kcal total active burn milestone."
        case "charge_28k": return "Surpassed 28,000 kcal total active burn milestone."
        case "charge_machine": return "Burned 1,500+ total kcal in a single week."
        case "early_charger": return "Completed a workout between 06:00 and 09:00 AM."
        case "night_charger": return "Completed a workout between 21:00 and 00:00 PM."
        case "overcharged": return "Burned 1,000+ kcal in a single day."
        case "first_cheat": return "Logged your first cheat meal."
        case "cheat_happens": return "Logged your first cheat meal while holding positive balance."
        case "burger_boss": return "Logged 10 total Burger treats."
        case "pizza_party": return "Logged 10 total Pizza treats."
        case "beer_oclock": return "Logged 10 total Beer treats."
        case "cheat_collector": return "Enjoyed treats across 6 different categories."
        case "cheat_weekend": return "Logged a treat meal during the weekend."
        case "agave_spirit": return "Logged a cocktail or alcohol treat."
        case "sugar_coma": return "Logged dessert treats 2 days in a row."
        case "zero_guilt": return "Stayed in the green despite 1,000+ kcal treats in a day."
        case "classic_duo": return "Logged both Burger and Beer on the same day."
        case "tactical_pause": return "Enjoyed a controlled treat under 150 kcal."
        case "yin_yang": return "Logged 600+ kcal burn and 600+ kcal cheat on the same day."
        case "night_owl": return "Logged a cocktail treat late on Friday or Saturday night."
        default: return detail
        }
    }
}

/// CheatCharge v2.0 Rozet Kataloğu.
///
/// Toplam 25 rozet içerir:
/// - 11 Charge (Efor) rozeti
/// - 12 Cheat (Kaçamak) rozeti
/// - 2 Gizli rozet (Easter Eggs)
enum BadgeCatalog {

    /// Katalogdaki tüm 25 rozetin listesi.
    static let all: [BadgeDefinition] = [
        // MARK: - Charge (Efor) Rozetleri (11)
        BadgeDefinition(
            key: "first_charge",
            title: "İlk Şarj",
            detail: "İlk antrenmanını kaydederek bütçeni başlattın.",
            category: .charge,
            isSecret: false
        ),
        BadgeDefinition(
            key: "iron_will",
            title: "Demir İrade",
            detail: "Bir haftada 3 farklı gün ağırlık antrenmanı yaptın.",
            category: .charge,
            isSecret: false
        ),
        BadgeDefinition(
            key: "endless_battery",
            title: "Tükenmez Pil",
            detail: "Tek seansta en az 500 kcal yaktın.",
            category: .charge,
            isSecret: false
        ),
        BadgeDefinition(
            key: "weekend_warrior",
            title: "Hafta Sonu Savaşçısı",
            detail: "Hafta sonu tek seansta 400+ kcal yaktın.",
            category: .charge,
            isSecret: false
        ),
        BadgeDefinition(
            key: "charge_7k",
            title: "7K Charge",
            detail: "Toplam 7.000 kcal efor barajını aştın.",
            category: .charge,
            isSecret: false
        ),
        BadgeDefinition(
            key: "charge_14k",
            title: "14K Charge",
            detail: "Toplam 14.000 kcal efor barajını aştın.",
            category: .charge,
            isSecret: false
        ),
        BadgeDefinition(
            key: "charge_28k",
            title: "28K Charge",
            detail: "Toplam 28.000 kcal efor barajını aştın.",
            category: .charge,
            isSecret: false
        ),
        BadgeDefinition(
            key: "charge_machine",
            title: "Charge Machine",
            detail: "Bir haftada toplam 1.500+ kcal yaktın.",
            category: .charge,
            isSecret: false
        ),
        BadgeDefinition(
            key: "early_charger",
            title: "Early Charger",
            detail: "Sabah 06:00 - 09:00 arası antrenman yaptın.",
            category: .charge,
            isSecret: false
        ),
        BadgeDefinition(
            key: "night_charger",
            title: "Night Charger",
            detail: "Gece 21:00 - 00:00 arası antrenman yaptın.",
            category: .charge,
            isSecret: false
        ),
        BadgeDefinition(
            key: "overcharged",
            title: "Overcharged",
            detail: "Aynı gün içinde toplam 1.000+ kcal yaktın.",
            category: .charge,
            isSecret: false
        ),

        // MARK: - Cheat (Kaçamak) Rozetleri (12)
        BadgeDefinition(
            key: "first_cheat",
            title: "First Cheat",
            detail: "İlk kaçamağını kaydettin.",
            category: .cheat,
            isSecret: false
        ),
        BadgeDefinition(
            key: "cheat_happens",
            title: "Cheat Happens",
            detail: "Bütçen artıda iken ilk kaçamağını yaptın.",
            category: .cheat,
            isSecret: false
        ),
        BadgeDefinition(
            key: "burger_boss",
            title: "Burger Boss",
            detail: "Toplam 10 kez Burger kaçamağı kaydettin.",
            category: .cheat,
            isSecret: false
        ),
        BadgeDefinition(
            key: "pizza_party",
            title: "Pizza Party",
            detail: "Toplam 10 kez Pizza kaçamağı kaydettin.",
            category: .cheat,
            isSecret: false
        ),
        BadgeDefinition(
            key: "beer_oclock",
            title: "Beer O'Clock",
            detail: "Toplam 10 kez Bira kaçamağı kaydettin.",
            category: .cheat,
            isSecret: false
        ),
        BadgeDefinition(
            key: "cheat_collector",
            title: "Cheat Collector",
            detail: "6 farklı kategoride kaçamak denedin.",
            category: .cheat,
            isSecret: false
        ),
        BadgeDefinition(
            key: "cheat_weekend",
            title: "Cheat Weekend",
            detail: "Hafta sonu bir kaçamak kaydettin.",
            category: .cheat,
            isSecret: false
        ),
        BadgeDefinition(
            key: "agave_spirit",
            title: "Agave Ruhu",
            detail: "Kokteyl veya alkol kaçamağı kaydettin.",
            category: .cheat,
            isSecret: false
        ),
        BadgeDefinition(
            key: "sugar_coma",
            title: "Şeker Koması",
            detail: "Üst üste 2 gün Tatlı kaçamağı yaptın.",
            category: .cheat,
            isSecret: false
        ),
        BadgeDefinition(
            key: "zero_guilt",
            title: "Sıfır Suçluluk",
            detail: "Günde 1.000+ kcal kaçamağa rağmen artıda kaldın.",
            category: .cheat,
            isSecret: false
        ),
        BadgeDefinition(
            key: "classic_duo",
            title: "Klasik İkili",
            detail: "Aynı gün hem Burger hem Bira kaydettin.",
            category: .cheat,
            isSecret: false
        ),
        BadgeDefinition(
            key: "tactical_pause",
            title: "Taktiksel Mola",
            detail: "150 kcal altı kontrollü bir kaçamak yaptın.",
            category: .cheat,
            isSecret: false
        ),

        // MARK: - Gizli Rozetler (2)
        BadgeDefinition(
            key: "yin_yang",
            title: "Yin & Yang",
            detail: "Aynı gün 600+ kcal efor ve 600+ kcal kaçamak yaptın.",
            category: .secret,
            isSecret: true
        ),
        BadgeDefinition(
            key: "night_owl",
            title: "Gece Kuşu",
            detail: "Cuma/Cumartesi gecesi (23:00-04:00) kokteyl kaydettin.",
            category: .secret,
            isSecret: true
        )
    ]

    /// Hızlı arama sözlüğü.
    private static let dictionary: [String: BadgeDefinition] = {
        Dictionary(uniqueKeysWithValues: all.map { ($0.key, $0) })
    }()

    /// Anahtara göre rozet tanımını döndürür.
    static func definition(for key: String) -> BadgeDefinition? {
        dictionary[key]
    }

    /// Belirtilen kategoriye ait rozetleri döndürür.
    static func badges(in category: BadgeCategory) -> [BadgeDefinition] {
        all.filter { $0.category == category }
    }
}
