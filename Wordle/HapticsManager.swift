//
//  HapticsManager.swift
//  Wordle
//
//  Created by Fikir on 11/9/26.
//

import UIKit

@MainActor
final class HapticsManager {
    static let shared = HapticsManager()

    var isEnabled: Bool = true

    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private let rigidImpact = UIImpactFeedbackGenerator(style: .rigid)
    private let softImpact = UIImpactFeedbackGenerator(style: .soft)
    private let notificationGen = UINotificationFeedbackGenerator()

    private init() {
        prepare()
    }

    func prepare() {
        guard isEnabled else { return }
        lightImpact.prepare()
        mediumImpact.prepare()
        rigidImpact.prepare()
        notificationGen.prepare()
    }

    /// Key typed or soft tap
    func keyTap() {
        guard isEnabled else { return }
        lightImpact.impactOccurred(intensity: 0.75)
    }

    /// Key deleted / backspace
    func keyDelete() {
        guard isEnabled else { return }
        softImpact.impactOccurred(intensity: 0.6)
    }

    /// Power-up activated (Reveal, Eliminate)
    func powerUpTrigger() {
        guard isEnabled else { return }
        rigidImpact.impactOccurred(intensity: 1.0)
    }

    /// Primary submit button tap
    func submitTap() {
        guard isEnabled else { return }
        mediumImpact.impactOccurred(intensity: 0.9)
    }

    /// Staggered flip tick during evaluation
    func flipTick(index: Int) {
        guard isEnabled else { return }
        let intensity = 0.5 + Double(index) * 0.1
        lightImpact.impactOccurred(intensity: min(1.0, intensity))
    }

    /// Elimination ticks (staggered 3 taps)
    func eliminationTick() {
        guard isEnabled else { return }
        rigidImpact.impactOccurred(intensity: 0.8)
    }

    /// Victory celebratory fanfare
    func victory() {
        guard isEnabled else { return }
        notificationGen.notificationOccurred(.success)
    }

    /// Invalid word shake / Error
    func invalidWordError() {
        guard isEnabled else { return }
        notificationGen.notificationOccurred(.error)
    }

    /// Warning / Game over
    func gameOver() {
        guard isEnabled else { return }
        notificationGen.notificationOccurred(.warning)
    }
}
