//
//  MotionManager.swift
//  CheatCharge
//
//  Created by Hasan Cavusoglu on 03.10.2026.
//

import Foundation
import CoreMotion
import Observation

/// Telefonun sağa/sola fiziksel eğimini (roll/gravity) takip eden servis.
///
/// Sıvı bardağının yerçekimine karşı doğal olarak dengelenmesini sağlar.
/// Sensör bulunmayan ortamlarda (Simulator, macOS Preview) otomatik simülasyon sunar.
@Observable
@MainActor
final class MotionManager {

    /// Sağa (+) / sola (-) eğim açısı (radyan, [-0.85, 0.85] aralığında filtrelenmiş).
    var roll: Double = 0.0

    /// Fiziksel hareket sensörü kullanılabilir mi?
    private(set) var isMotionAvailable: Bool = false

    @ObservationIgnored
    private let motionManager = CMMotionManager()

    @ObservationIgnored
    private var isUpdating = false

    init() {
        isMotionAvailable = motionManager.isDeviceMotionAvailable
    }

    /// Jiroskop dinlemesini başlatır.
    func start() {
        guard !isUpdating else { return }
        guard motionManager.isDeviceMotionAvailable else {
            isMotionAvailable = false
            return
        }

        isMotionAvailable = true
        isUpdating = true
        motionManager.deviceMotionUpdateInterval = 1.0 / 50.0 // 50 Hz akıcı ve pil dostu

        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self, let motion else { return }
            // gravity.x: cihaz sağa eğilince +, sola eğilince -
            let rawX = motion.gravity.x
            let clamped = max(-0.85, min(0.85, rawX))
            // Yumuşatma filtresi (hızlı tepki ve pürüzsüz geçiş dengesi)
            self.roll = self.roll * 0.78 + clamped * 0.22
        }
    }

    /// Jiroskop dinlemesini durdurur (ekran arka plana geçtiğinde pili korur).
    func stop() {
        guard isUpdating else { return }
        isUpdating = false
        motionManager.stopDeviceMotionUpdates()
    }

    deinit {
        motionManager.stopDeviceMotionUpdates()
    }
}
