//
//  TreatLog.swift
//  CheatCharge
//
//  Created by Hasan Cavusoglu on 24.09.2026.
//

import Foundation
import SwiftData

/// Kullanıcının fiilen tükettiği kaçamakları temsil eder.
/// TreatItem şablonundan yaratılır ve tüketim tarihini tutar.
@Model
final class TreatLog {
    var id: UUID
    /// Hangi kaçamak şablonundan türetildi
    var treat: TreatItem?
    /// Tüketim tarihi
    var date: Date

    init(
        id: UUID = UUID(),
        treat: TreatItem? = nil,
        date: Date = Date()
    ) {
        self.id = id
        self.treat = treat
        self.date = date
    }
}
