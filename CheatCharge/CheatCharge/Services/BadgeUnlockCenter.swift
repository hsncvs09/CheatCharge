//
//  BadgeUnlockCenter.swift
//  CheatCharge
//
//  Created by Hasan Cavusoglu on 03.10.2026.
//

import Foundation
import Observation

/// Yeni kazanılan rozetlerin bildirim kuyruğunu yöneten merkezi servis.
///
/// Faz 3'te model ve kuyruk yapısı kurulur; Faz 5'te kullanıcı arayüzünde
/// banner/toast olarak gösterilir.
@Observable
@MainActor
final class BadgeUnlockCenter {

    /// Uygulama genelinde paylaşılan tekil örnek.
    static let shared = BadgeUnlockCenter()

    /// Henüz kullanıcıya gösterilmemiş / bekleyen rozet tanımları.
    var pendingBadges: [BadgeDefinition] = []

    init() {}

    /// Kuyruğa yeni açılan rozetleri ekler.
    func enqueue(_ badges: [BadgeDefinition]) {
        guard !badges.isEmpty else { return }
        pendingBadges.append(contentsOf: badges)
    }

    /// Kuyruktan sıradaki rozeti çeker ve kaldırır.
    func popNext() -> BadgeDefinition? {
        guard !pendingBadges.isEmpty else { return nil }
        return pendingBadges.removeFirst()
    }

    /// Tüm bekleyen rozetleri temizler.
    func clear() {
        pendingBadges.removeAll()
    }
}
