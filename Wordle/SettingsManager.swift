//
//  SettingsManager.swift
//  Wordle
//
//  Created by Fikir on 11/9/26.
//

import SwiftUI
import Observation

@Observable
final class SettingsManager {
    static let shared = SettingsManager()

    var appearanceMode: AppearanceMode {
        didSet {
            UserDefaults.standard.set(appearanceMode.rawValue, forKey: "settings_appearance_mode")
        }
    }

    var themePalette: ThemePalette {
        didSet {
            UserDefaults.standard.set(themePalette.rawValue, forKey: "settings_theme_palette")
        }
    }

    var hapticsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(hapticsEnabled, forKey: "settings_haptics_enabled")
            HapticsManager.shared.isEnabled = hapticsEnabled
        }
    }

    var soundEffectsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(soundEffectsEnabled, forKey: "settings_sound_enabled")
        }
    }

    private init() {
        let storedAppearance = UserDefaults.standard.string(forKey: "settings_appearance_mode") ?? AppearanceMode.system.rawValue
        self.appearanceMode = AppearanceMode(rawValue: storedAppearance) ?? .system

        let storedTheme = UserDefaults.standard.string(forKey: "settings_theme_palette") ?? ThemePalette.swissClassic.rawValue
        self.themePalette = ThemePalette(rawValue: storedTheme) ?? .swissClassic

        let storedHaptics = UserDefaults.standard.object(forKey: "settings_haptics_enabled") as? Bool ?? true
        self.hapticsEnabled = storedHaptics
        HapticsManager.shared.isEnabled = storedHaptics

        let storedSound = UserDefaults.standard.object(forKey: "settings_sound_enabled") as? Bool ?? true
        self.soundEffectsEnabled = storedSound
    }
}
