//
//  GameViewModel.swift
//  Wordle
//
//  Created by Fikir on 11/9/26.
//

import SwiftUI
import Observation

@Observable
final class GameViewModel {
    // MARK: - Game State
    var gameMode: GameMode = .classic
    var secretWord: String = ""
    var grid: [WordleRow] = []
    var currentRowIndex: Int = 0
    var isGameOver: Bool = false
    var isVictory: Bool = false
    var isEvaluating: Bool = false
    var showCelebration: Bool = false
    var showConfetti: Bool = false
    var toastMessage: String? = nil
    var toastIcon: String = "info.circle.fill"

    // MARK: - Keyboard & Power-Up States
    var keyboardStates: [Character: TileEvaluationState] = [:]
    var eliminatedKeys: Set<Character> = []

    // MARK: - In-Game Currency & Economy
    var coins: Int = 100
    var hintsUsedInCurrentGame: Int = 0
    var lastCoinsEarned: Int = 0
    var lastRewardBreakdown: [CoinRewardItem] = []

    // MARK: - Legacy Charges (Compatibility)
    var revealCharges: Int = 2
    var eliminateCharges: Int = 2
    var skipCharges: Int = 2

    // MARK: - Scores & Streaks
    var score: Int = 0
    var stats: GameStats = GameStats()

    // MARK: - Daily Tracking
    var dailyCompletedToday: Bool = false
    var dailyWinToday: Bool = false
    var dailyGuessesToday: Int = 0

    /// Whether the current row's word is a valid English word (for submit button state)
    var isCurrentWordValid: Bool = false

    init() {
        loadData()
        startNewGame(mode: .classic)
    }

    // MARK: - Start Game
    func startNewGame(mode: GameMode, force: Bool = false) {
        self.gameMode = mode
        self.isGameOver = false
        self.isVictory = false
        self.isEvaluating = false
        self.showCelebration = false
        self.showConfetti = false
        self.currentRowIndex = 0
        self.grid = (0..<6).map { _ in WordleRow() }
        self.keyboardStates.removeAll()
        self.eliminatedKeys.removeAll()
        self.isCurrentWordValid = false
        self.hintsUsedInCurrentGame = 0
        self.lastCoinsEarned = 0
        self.lastRewardBreakdown.removeAll()

        switch mode {
        case .daily:
            let dateKey = todayDateKey()
            self.secretWord = WordProvider.dailyWord()

            // Check if already completed today
            if let record = loadDailyRecord(for: dateKey), record.isCompleted, !force {
                self.dailyCompletedToday = true
                self.dailyWinToday = record.didWin
                self.dailyGuessesToday = record.guessesCount
                self.isGameOver = true
                self.isVictory = record.didWin
                restoreBoard(from: record.guesses)
                return
            } else {
                self.dailyCompletedToday = false
            }

        case .classic:
            self.secretWord = WordProvider.randomTargetWord()
        }
    }

    // MARK: - Typing & Deleting
    func typeLetter(_ char: Character) {
        guard !isGameOver, !isEvaluating, currentRowIndex < 6 else { return }

        var row = grid[currentRowIndex]

        // Find first empty tile
        if let emptyIndex = row.tiles.firstIndex(where: { $0.letter == nil }) {
            row.tiles[emptyIndex].letter = Character(char.uppercased())
            row.tiles[emptyIndex].state = .typing
            row.tiles[emptyIndex].scale = 1.15
            grid[currentRowIndex] = row

            // Reset scale with a spring pop
            withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                grid[currentRowIndex].tiles[emptyIndex].scale = 1.0
            }

            // Revalidate current word
            validateCurrentWord()
        }
    }

    func deleteLetter() {
        guard !isGameOver, !isEvaluating, currentRowIndex < 6 else { return }

        var row = grid[currentRowIndex]

        // Find last non-nil letter that was not locked/revealed by power-up
        if let lastFilledIndex = row.tiles.lastIndex(where: { $0.letter != nil && !$0.isRevealed }) {
            HapticsManager.shared.keyDelete()
            row.tiles[lastFilledIndex].letter = nil
            row.tiles[lastFilledIndex].state = .empty
            row.tiles[lastFilledIndex].scale = 1.0
            grid[currentRowIndex] = row

            // Revalidate current word
            validateCurrentWord()
        }
    }

    /// Checks whether the current row forms a valid 5-letter English word
    private func validateCurrentWord() {
        guard currentRowIndex < 6 else {
            isCurrentWordValid = false
            return
        }

        let row = grid[currentRowIndex]
        guard row.isComplete else {
            isCurrentWordValid = false
            return
        }

        let word = row.wordString.uppercased()
        isCurrentWordValid = WordProvider.isValidWord(word)
    }

    // MARK: - Submit Guess
    func submitGuess() {
        guard !isGameOver, !isEvaluating, currentRowIndex < 6 else { return }

        let row = grid[currentRowIndex]
        guard row.isComplete else {
            triggerShake()
            showToast("Not enough letters", icon: "exclamationmark.triangle.fill")
            HapticsManager.shared.invalidWordError()
            return
        }

        let guess = row.wordString.uppercased()

        // Validate word
        guard WordProvider.isValidWord(guess) else {
            triggerShake()
            showToast("Not in word list", icon: "character.bubble.fill")
            HapticsManager.shared.invalidWordError()
            return
        }

        // Valid word -> Staggered Evaluation
        evaluateRow(guess: guess)
    }

    // MARK: - Evaluation with 3D Flip
    private func evaluateRow(guess: String) {
        isEvaluating = true
        isCurrentWordValid = false // Reset during evaluation
        let targetChars = Array(secretWord.uppercased())
        let guessChars = Array(guess)
        var targetLetterCounts: [Character: Int] = [:]
        for c in targetChars {
            targetLetterCounts[c, default: 0] += 1
        }

        var results: [TileEvaluationState] = Array(repeating: .absent, count: 5)

        // Pass 1: Correct letters
        for i in 0..<5 {
            if guessChars[i] == targetChars[i] {
                results[i] = .correct
                targetLetterCounts[guessChars[i], default: 1] -= 1
            }
        }

        // Pass 2: Present letters & Absent
        for i in 0..<5 {
            if results[i] != .correct {
                let char = guessChars[i]
                if let count = targetLetterCounts[char], count > 0 {
                    results[i] = .present
                    targetLetterCounts[char] = count - 1
                } else {
                    results[i] = .absent
                }
            }
        }

        // Staggered 3D Flip Animation (0.12s per tile)
        for i in 0..<5 {
            let delay = Double(i) * 0.12
            let char = guessChars[i]
            let evaluatedState = results[i]

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self else { return }

                // Flip to 90 degrees
                withAnimation(.linear(duration: 0.14)) {
                    self.grid[self.currentRowIndex].tiles[i].flipAngle = 90
                }

                // Midpoint: swap color & update keyboard
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) {
                    self.grid[self.currentRowIndex].tiles[i].state = evaluatedState
                    self.updateKeyboardState(for: char, with: evaluatedState)
                    HapticsManager.shared.flipTick(index: i)

                    // Flip from 90 to 0 degrees
                    withAnimation(.linear(duration: 0.14)) {
                        self.grid[self.currentRowIndex].tiles[i].flipAngle = 0
                    }
                }
            }
        }

        // Finish evaluation after all 5 flips complete
        let totalFlipTime = 5 * 0.12 + 0.32
        DispatchQueue.main.asyncAfter(deadline: .now() + totalFlipTime) { [weak self] in
            guard let self else { return }
            self.isEvaluating = false
            self.finalizeRowEvaluation(allCorrect: results.allSatisfy { $0 == .correct })
        }
    }

    private func updateKeyboardState(for char: Character, with newState: TileEvaluationState) {
        let currentState = keyboardStates[char] ?? .empty
        if newState.priority > currentState.priority {
            keyboardStates[char] = newState
        }
    }

    private func finalizeRowEvaluation(allCorrect: Bool) {
        if allCorrect {
            // VICTORY!
            isVictory = true
            isGameOver = true
            showConfetti = true
            HapticsManager.shared.victory()

            // Trigger Joyful Wave Bounce on winning row
            for i in 0..<5 {
                let bounceDelay = Double(i) * 0.08
                DispatchQueue.main.asyncAfter(deadline: .now() + bounceDelay) { [weak self] in
                    guard let self else { return }
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.5)) {
                        self.grid[self.currentRowIndex].tiles[i].bounceOffset = -18
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
                        withAnimation(.spring(response: 0.24, dampingFraction: 0.6)) {
                            self.grid[self.currentRowIndex].tiles[i].bounceOffset = 0
                        }
                    }
                }
            }

            let guessesUsed = currentRowIndex + 1

            recordWin(guesses: guessesUsed)
            calculatePerformanceReward(guessesUsed: guessesUsed)

            if gameMode == .daily {
                saveDailyRecord(didWin: true, guesses: guessesUsed)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
                    self?.showCelebration = true
                }
            } else {
                score += 1
                if score > stats.classicHighScore {
                    stats.classicHighScore = score
                    saveData()
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
                    self?.showCelebration = true
                }
            }

        } else if currentRowIndex == 5 {
            // GAME OVER - Loss
            isGameOver = true
            HapticsManager.shared.gameOver()
            showToast("The word was \(secretWord)", icon: "xmark.circle.fill")
            recordLoss()
            calculateLossReward()

            if gameMode == .daily {
                saveDailyRecord(didWin: false, guesses: 6)
            } else {
                score = 0
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
                self?.showCelebration = true
            }

        } else {
            // Advance to next row
            currentRowIndex += 1
            isCurrentWordValid = false
        }
    }

    // MARK: - Power-Up 1: Reveal Letter (Magnifying Glass)
    func useRevealLetter() {
        let cost = PowerUpType.reveal.coinCost
        guard !isGameOver, !isEvaluating, currentRowIndex < 6 else { return }

        guard coins >= cost else {
            HapticsManager.shared.keyDelete()
            showToast("Need \(cost) Coins for Reveal Letter", icon: "exclamationmark.circle.fill")
            return
        }

        let targetChars = Array(secretWord.uppercased())
        var row = grid[currentRowIndex]

        // Find the first column in the active row that isn't already correct or revealed
        var targetCol: Int? = nil
        for c in 0..<5 {
            if row.tiles[c].letter != targetChars[c] && !row.tiles[c].isRevealed {
                targetCol = c
                break
            }
        }

        guard let col = targetCol else {
            showToast("Letters already match!", icon: "sparkles")
            return
        }

        coins -= cost
        hintsUsedInCurrentGame += 1
        saveCoins()

        let correctChar = targetChars[col]
        row.tiles[col].letter = correctChar
        row.tiles[col].isRevealed = true
        row.tiles[col].scale = 1.3
        grid[currentRowIndex] = row

        HapticsManager.shared.powerUpTrigger()
        showToast("-\(cost) Coins • Revealed: \(correctChar)", icon: "sparkles")

        withAnimation(.spring(response: 0.3, dampingFraction: 0.55)) {
            grid[currentRowIndex].tiles[col].scale = 1.0
        }

        // Revalidate
        validateCurrentWord()
    }

    // MARK: - Power-Up 2: Eliminate 3 Letters (Bullseye)
    func useEliminateLetters() {
        let cost = PowerUpType.eliminate.coinCost
        guard !isGameOver, !isEvaluating else { return }

        guard coins >= cost else {
            HapticsManager.shared.keyDelete()
            showToast("Need \(cost) Coins to Eliminate Letters", icon: "exclamationmark.circle.fill")
            return
        }

        let targetLetters = Set(secretWord.uppercased())
        let allAlphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"

        let candidates = allAlphabet.filter { char in
            !targetLetters.contains(char) &&
            !eliminatedKeys.contains(char) &&
            (keyboardStates[char] != .absent)
        }

        guard !candidates.isEmpty else {
            showToast("No more letters to eliminate!", icon: "checkmark.circle")
            return
        }

        coins -= cost
        hintsUsedInCurrentGame += 1
        saveCoins()

        let toEliminate = Array(candidates.shuffled().prefix(3))

        for (idx, char) in toEliminate.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(idx) * 0.15) { [weak self] in
                guard let self else { return }
                self.eliminatedKeys.insert(char)
                HapticsManager.shared.eliminationTick()
            }
        }

        let eliminatedStr = toEliminate.map { String($0) }.joined(separator: ", ")
        showToast("-\(cost) Coins • Eliminated: \(eliminatedStr)", icon: "scope")
    }

    // MARK: - Power-Up 3: Skip Word
    func useSkipWord() {
        let cost = PowerUpType.skip.coinCost
        guard !isGameOver, !isEvaluating, gameMode == .classic else { return }

        guard coins >= cost else {
            HapticsManager.shared.keyDelete()
            showToast("Need \(cost) Coins to Skip Word", icon: "exclamationmark.circle.fill")
            return
        }

        coins -= cost
        hintsUsedInCurrentGame += 1
        saveCoins()

        HapticsManager.shared.powerUpTrigger()
        let oldWord = secretWord
        showToast("-\(cost) Coins • Skipped! Word was \(oldWord)", icon: "forward.end.fill")

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            guard let self else { return }
            self.startNewGame(mode: .classic)
        }
    }

    // MARK: - Performance-Based Currency Economy
    private func calculatePerformanceReward(guessesUsed: Int) {
        var breakdown: [CoinRewardItem] = []
        var total = 0

        // 1. Guess efficiency reward
        let guessCoins: Int
        let guessLabel: String
        switch guessesUsed {
        case 1:
            guessCoins = 100
            guessLabel = "Genius (1 Guess)"
        case 2:
            guessCoins = 60
            guessLabel = "Magnificent (2 Guesses)"
        case 3:
            guessCoins = 40
            guessLabel = "Splendid (3 Guesses)"
        case 4:
            guessCoins = 25
            guessLabel = "Great (4 Guesses)"
        case 5:
            guessCoins = 15
            guessLabel = "Solved (5 Guesses)"
        default:
            guessCoins = 10
            guessLabel = "Phew! (6 Guesses)"
        }
        breakdown.append(CoinRewardItem(title: guessLabel, amount: guessCoins, icon: "target"))
        total += guessCoins

        // 2. Clean Solve / Purity Bonus (No hints used)
        if hintsUsedInCurrentGame == 0 {
            let purityBonus = 20
            breakdown.append(CoinRewardItem(title: "No Hints Used Bonus", amount: purityBonus, icon: "sparkles"))
            total += purityBonus
        }

        // 3. Daily Puzzle Bonus
        if gameMode == .daily {
            let dailyBonus = 30
            breakdown.append(CoinRewardItem(title: "Daily Puzzle Bonus", amount: dailyBonus, icon: "calendar"))
            total += dailyBonus
        }

        // 4. Streak Milestone Bonus
        if stats.currentStreak > 0 && stats.currentStreak % 3 == 0 {
            let streakBonus = 25
            breakdown.append(CoinRewardItem(title: "\(stats.currentStreak)-Game Streak Bonus", amount: streakBonus, icon: "flame.fill"))
            total += streakBonus
        }

        self.lastCoinsEarned = total
        self.lastRewardBreakdown = breakdown
        self.coins += total
        self.saveCoins()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.showToast("+\(total) Coins Earned!", icon: "circle.circle.fill")
        }
    }

    private func calculateLossReward() {
        let consolation = 5
        let item = CoinRewardItem(title: "Effort Reward", amount: consolation, icon: "heart.fill")
        self.lastCoinsEarned = consolation
        self.lastRewardBreakdown = [item]
        self.coins += consolation
        self.saveCoins()
    }

    // MARK: - Toast Banner Presentation
    func showToast(_ message: String, icon: String = "info.circle.fill") {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            self.toastMessage = message
            self.toastIcon = icon
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) { [weak self] in
            withAnimation(.easeInOut(duration: 0.25)) {
                if self?.toastMessage == message {
                    self?.toastMessage = nil
                }
            }
        }
    }

    // MARK: - Shake Animation
    private func triggerShake() {
        let offsets: [CGFloat] = [-12, 12, -8, 8, -4, 4, 0]
        for (index, offset) in offsets.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.04) { [weak self] in
                guard let self else { return }
                withAnimation(.linear(duration: 0.04)) {
                    self.grid[self.currentRowIndex].shakeOffset = offset
                }
            }
        }
    }

    // MARK: - Persistence & Stats
    private func todayDateKey() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    private func recordWin(guesses: Int) {
        stats.gamesPlayed += 1
        stats.wins += 1
        stats.currentStreak += 1
        stats.maxStreak = max(stats.maxStreak, stats.currentStreak)
        stats.guessDistribution[guesses, default: 0] += 1
        stats.totalWordsSolved += 1
        saveData()
    }

    private func recordLoss() {
        stats.gamesPlayed += 1
        stats.currentStreak = 0
        saveData()
    }

    private func saveDailyRecord(didWin: Bool, guesses: Int) {
        let key = todayDateKey()
        let guessesList = grid.prefix(guesses).map { $0.wordString }
        let record = DailyGameRecord(
            dateKey: key,
            word: secretWord,
            isCompleted: true,
            didWin: didWin,
            guessesCount: guesses,
            guesses: guessesList
        )
        if let encoded = try? JSONEncoder().encode(record) {
            UserDefaults.standard.set(encoded, forKey: "daily_record_\(key)")
        }
        self.dailyCompletedToday = true
        self.dailyWinToday = didWin
        self.dailyGuessesToday = guesses
    }

    private func loadDailyRecord(for key: String) -> DailyGameRecord? {
        guard let data = UserDefaults.standard.data(forKey: "daily_record_\(key)"),
              let record = try? JSONDecoder().decode(DailyGameRecord.self, from: data) else {
            return nil
        }
        return record
    }

    private func restoreBoard(from savedGuesses: [String]) {
        for (rIdx, guess) in savedGuesses.enumerated() {
            guard rIdx < 6 else { break }
            let chars = Array(guess)
            for (cIdx, char) in chars.enumerated() {
                guard cIdx < 5 else { break }
                grid[rIdx].tiles[cIdx].letter = char
                let targetChars = Array(secretWord)
                if targetChars[cIdx] == char {
                    grid[rIdx].tiles[cIdx].state = .correct
                    keyboardStates[char] = .correct
                } else if targetChars.contains(char) {
                    grid[rIdx].tiles[cIdx].state = .present
                    if keyboardStates[char] != .correct {
                        keyboardStates[char] = .present
                    }
                } else {
                    grid[rIdx].tiles[cIdx].state = .absent
                    if keyboardStates[char] == nil {
                        keyboardStates[char] = .absent
                    }
                }
            }
        }
        currentRowIndex = savedGuesses.count
    }

    func saveCoins() {
        UserDefaults.standard.set(coins, forKey: "player_coins")
    }

    private func loadData() {
        coins = UserDefaults.standard.object(forKey: "player_coins") as? Int ?? 100
        revealCharges = UserDefaults.standard.object(forKey: "charges_reveal") as? Int ?? 2
        eliminateCharges = UserDefaults.standard.object(forKey: "charges_eliminate") as? Int ?? 2
        skipCharges = UserDefaults.standard.object(forKey: "charges_skip") as? Int ?? 2

        if let statsData = UserDefaults.standard.data(forKey: "game_stats"),
           let loadedStats = try? JSONDecoder().decode(GameStats.self, from: statsData) {
            self.stats = loadedStats
        }
    }

    private func saveData() {
        if let encoded = try? JSONEncoder().encode(stats) {
            UserDefaults.standard.set(encoded, forKey: "game_stats")
        }
    }

    private func saveCharges() {
        UserDefaults.standard.set(revealCharges, forKey: "charges_reveal")
        UserDefaults.standard.set(eliminateCharges, forKey: "charges_eliminate")
        UserDefaults.standard.set(skipCharges, forKey: "charges_skip")
    }

    func resetAllData() {
        UserDefaults.standard.removeObject(forKey: "game_stats")
        UserDefaults.standard.removeObject(forKey: "player_coins")
        UserDefaults.standard.removeObject(forKey: "charges_reveal")
        UserDefaults.standard.removeObject(forKey: "charges_eliminate")
        UserDefaults.standard.removeObject(forKey: "charges_skip")
        coins = 100
        revealCharges = 2
        eliminateCharges = 2
        skipCharges = 2
        stats = GameStats()
        score = 0
        startNewGame(mode: gameMode, force: true)
    }
}
