//
//  Models.swift
//  Wordle
//
//  Created by Fikir on 11/9/26.
//

import SwiftUI

// MARK: - Tile State
enum TileEvaluationState: String, Codable, Equatable {
    case empty
    case typing
    case correct   // Right letter, right spot
    case present   // Right letter, wrong spot
    case absent    // Not in word

    var priority: Int {
        switch self {
        case .correct: return 4
        case .present: return 3
        case .absent: return 2
        case .typing: return 1
        case .empty: return 0
        }
    }
}

// MARK: - Tile Model
struct WordleTile: Identifiable, Equatable {
    let id: UUID
    var letter: Character?
    var state: TileEvaluationState
    var isRevealed: Bool       // Revealed by Magnifying Glass power-up
    var flipAngle: Double      // 3D rotation flip angle
    var bounceOffset: CGFloat  // Joyful victory bounce offset
    var scale: CGFloat         // Pop scale spring when typed

    init(
        id: UUID = UUID(),
        letter: Character? = nil,
        state: TileEvaluationState = .empty,
        isRevealed: Bool = false,
        flipAngle: Double = 0,
        bounceOffset: CGFloat = 0,
        scale: CGFloat = 1.0
    ) {
        self.id = id
        self.letter = letter
        self.state = state
        self.isRevealed = isRevealed
        self.flipAngle = flipAngle
        self.bounceOffset = bounceOffset
        self.scale = scale
    }
}

// MARK: - Row Model
struct WordleRow: Identifiable, Equatable {
    let id: UUID
    var tiles: [WordleTile]
    var shakeOffset: CGFloat

    init(id: UUID = UUID(), tiles: [WordleTile]? = nil, shakeOffset: CGFloat = 0) {
        self.id = id
        self.tiles = tiles ?? (0..<5).map { _ in WordleTile() }
        self.shakeOffset = shakeOffset
    }

    var wordString: String {
        tiles.compactMap { $0.letter }.map { String($0) }.joined()
    }

    var isComplete: Bool {
        tiles.allSatisfy { $0.letter != nil }
    }
}

// MARK: - Game Mode
enum GameMode: String, CaseIterable, Identifiable, Codable {
    case daily
    case classic

    var id: String { rawValue }

    var title: String {
        switch self {
        case .daily: return "Daily Word"
        case .classic: return "Classic Endless"
        }
    }

    var subtitle: String {
        switch self {
        case .daily: return "One puzzle every day"
        case .classic: return "Infinite back-to-back runs"
        }
    }

    var iconName: String {
        switch self {
        case .daily: return "calendar"
        case .classic: return "infinity"
        }
    }
}

// MARK: - Power-Up Types
enum PowerUpType: String, CaseIterable, Identifiable {
    case reveal     // Magnifying glass: reveals 1 correct letter in active row
    case eliminate  // Bullseye: eliminates 3 unneeded letters from keyboard
    case skip       // Skip: pass difficult word in classic mode

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .reveal: return "magnifyingglass"
        case .eliminate: return "scope"
        case .skip: return "forward.end.fill"
        }
    }

    var title: String {
        switch self {
        case .reveal: return "Reveal Letter"
        case .eliminate: return "Eliminate 3"
        case .skip: return "Skip Word"
        }
    }

    var coinCost: Int {
        switch self {
        case .reveal: return 50
        case .eliminate: return 35
        case .skip: return 25
        }
    }
}

// MARK: - Currency Reward Item
struct CoinRewardItem: Identifiable, Codable {
    var id: UUID = UUID()
    let title: String
    let amount: Int
    let icon: String
}

// MARK: - Theme Palette
enum ThemePalette: String, CaseIterable, Identifiable, Codable {
    case swissClassic = "Swiss Classic"
    case indigoPop = "Indigo Pop"
    case forestMatte = "Forest Matte"
    case obsidianCoral = "Obsidian Coral"

    var id: String { rawValue }

    var correctColor: Color {
        switch self {
        case .swissClassic: return Color(red: 0.18, green: 0.74, blue: 0.52) // Lush Sage (#2EBD85)
        case .indigoPop: return Color(red: 0.31, green: 0.27, blue: 0.90)    // Royal Indigo (#4F46E5)
        case .forestMatte: return Color(red: 0.08, green: 0.50, blue: 0.24)  // Forest (#15803D)
        case .obsidianCoral: return Color(red: 0.96, green: 0.25, blue: 0.37)// Coral (#F43F5E)
        }
    }

    var presentColor: Color {
        switch self {
        case .swissClassic: return Color(red: 0.96, green: 0.62, blue: 0.04) // Marigold (#F59E0B)
        case .indigoPop: return Color(red: 0.96, green: 0.62, blue: 0.04)    // Marigold (#F59E0B)
        case .forestMatte: return Color(red: 0.85, green: 0.47, blue: 0.02)  // Ochre Amber (#D97706)
        case .obsidianCoral: return Color(red: 0.92, green: 0.70, blue: 0.03)// Electric Gold (#EAB308)
        }
    }

    var accentPrimary: Color {
        correctColor
    }

    var eliminateColor: Color {
        Color(red: 0.65, green: 0.33, blue: 0.97) // Soft Berry Purple (#A855F7)
    }

    var revealColor: Color {
        Color(red: 0.96, green: 0.50, blue: 0.20) // Warm Marigold / Coral
    }

    var skipColor: Color {
        Color(red: 0.20, green: 0.70, blue: 0.95) // Cyan Sky (#38BDF8)
    }

    var previewGradient: [Color] {
        [correctColor, presentColor]
    }
}

// MARK: - Appearance Mode
enum AppearanceMode: String, CaseIterable, Identifiable, Codable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .system: return "circle.righthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

// MARK: - Statistics Model
struct GameStats: Codable {
    var gamesPlayed: Int = 0
    var wins: Int = 0
    var currentStreak: Int = 0
    var maxStreak: Int = 0
    var guessDistribution: [Int: Int] = [1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0]
    var totalWordsSolved: Int = 0
    var classicHighScore: Int = 0

    var winRatePercent: Int {
        guard gamesPlayed > 0 else { return 0 }
        return Int((Double(wins) / Double(gamesPlayed)) * 100)
    }
}

// MARK: - Daily Record
struct DailyGameRecord: Codable {
    let dateKey: String     // Format "yyyy-MM-dd"
    let word: String
    var isCompleted: Bool
    var didWin: Bool
    var guessesCount: Int
    var guesses: [String]
}
