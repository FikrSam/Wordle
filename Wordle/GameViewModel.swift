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
    var grid: [WordleRow] = (0..<6).map { _ in WordleRow() }
    var dailyGrid: [WordleRow] = (0..<6).map { _ in WordleRow() }
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

    /// Identifies the current game. Every delayed callback captures it and bails out
    /// if a new game has started in the meantime, so stale flip/bounce/finalize
    /// timers can never mutate (or score) a different board.
    private var gameID = UUID()
    private var toastID = UUID()

    /// Number of rows the player has submitted in the current game.
    var guessesUsed: Int {
        grid.filter { row in row.tiles.contains { [.correct, .present, .absent].contains($0.state) } }.count
    }

    init() {
        loadData()
        startNewGame(mode: .classic)
        SoundManager.shared.prepare()
    }

    /// Schedules work on the main queue that is dropped if the game changes first.
    private func after(_ delay: Double, _ work: @escaping () -> Void) {
        let id = gameID
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self, self.gameID == id else { return }
            work()
        }
    }

    // MARK: - Enter Game (resume if possible)
    /// Resumes an unfinished game of the same mode instead of throwing the board away.
    /// (Previously, backing out and re-entering silently discarded progress, which also
    /// let players dodge a loss.)
    func enterGame(mode: GameMode) {
        let canResume = mode == gameMode
            && !isGameOver
            && !secretWord.isEmpty
            && (mode == .classic || secretWord == WordProvider.dailyWord())
        if !canResume {
            startNewGame(mode: mode)
        }
    }

    // MARK: - Start Game
    func startNewGame(mode: GameMode, force: Bool = false) {
        self.gameID = UUID()
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
                if record.word.count == 5 { self.secretWord = record.word.uppercased() }
                restoreBoard(from: record)
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
            HapticsManager.shared.keyTap()
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
            SoundManager.shared.play(.wrongGuess)
            return
        }

        // Valid word -> Staggered Evaluation
        evaluateRow(guess: guess)
    }

    // MARK: - Evaluation with 3D Flip
    /// Standard two-pass Wordle scoring that handles duplicate letters correctly.
    static func evaluate(guess: String, target: String) -> [TileEvaluationState] {
        let guessChars = Array(guess.uppercased())
        let targetChars = Array(target.uppercased())
        guard guessChars.count == 5, targetChars.count == 5 else {
            return Array(repeating: .absent, count: 5)
        }

        var remaining: [Character: Int] = [:]
        var results: [TileEvaluationState] = Array(repeating: .absent, count: 5)

        // Pass 1: exact matches; count the unmatched target letters
        for i in 0..<5 {
            if guessChars[i] == targetChars[i] {
                results[i] = .correct
            } else {
                remaining[targetChars[i], default: 0] += 1
            }
        }

        // Pass 2: present letters, consuming the remaining counts
        for i in 0..<5 where results[i] != .correct {
            let c = guessChars[i]
            if let n = remaining[c], n > 0 {
                results[i] = .present
                remaining[c] = n - 1
            }
        }
        return results
    }

    private func evaluateRow(guess: String) {
        isEvaluating = true
        isCurrentWordValid = false // Reset during evaluation
        let rowIndex = currentRowIndex
        let guessChars = Array(guess)
        let results = Self.evaluate(guess: guess, target: secretWord)

        // Staggered 3D Flip Animation (0.12s per tile)
        for i in 0..<5 {
            let delay = Double(i) * 0.12
            let char = guessChars[i]
            let evaluatedState = results[i]

            after(delay) { [weak self] in
                guard let self else { return }

                // Flip to 90 degrees
                withAnimation(.easeIn(duration: 0.14)) {
                    self.grid[rowIndex].tiles[i].flipAngle = 90
                }

                // Midpoint: swap color & update keyboard
                self.after(0.14) { [weak self] in
                    guard let self else { return }
                    self.grid[rowIndex].tiles[i].state = evaluatedState
                    withAnimation(.easeInOut(duration: 0.25)) {
                        self.updateKeyboardState(for: char, with: evaluatedState)
                    }
                    HapticsManager.shared.flipTick(index: i)

                    // Flip from 90 to 0 degrees
                    withAnimation(.easeOut(duration: 0.14)) {
                        self.grid[rowIndex].tiles[i].flipAngle = 0
                    }
                }
            }
        }

        // Finish evaluation after all 5 flips complete
        let totalFlipTime = 4 * 0.12 + 0.28 + 0.08
        after(totalFlipTime) { [weak self] in
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
            SoundManager.shared.play(.victory)
            after(4.0) { [weak self] in self?.showConfetti = false }

            // Trigger Joyful Wave Bounce on winning row
            let winRow = currentRowIndex
            for i in 0..<5 {
                let bounceDelay = Double(i) * 0.08
                after(bounceDelay) { [weak self] in
                    guard let self else { return }
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.5)) {
                        self.grid[winRow].tiles[i].bounceOffset = -18
                        self.grid[winRow].tiles[i].scale = 1.08
                    }
                    self.after(0.16) { [weak self] in
                        guard let self else { return }
                        withAnimation(.spring(response: 0.24, dampingFraction: 0.6)) {
                            self.grid[winRow].tiles[i].bounceOffset = 0
                            self.grid[winRow].tiles[i].scale = 1.0
                        }
                    }
                }
            }

            let guessesUsed = currentRowIndex + 1

            recordWin(guesses: guessesUsed)
            calculatePerformanceReward(guessesUsed: guessesUsed)

            if gameMode == .daily {
                saveDailyRecord(didWin: true, guesses: guessesUsed)
                after(1.2) { [weak self] in
                    self?.showCelebration = true
                }
            } else {
                score += 1
                if score > stats.classicHighScore {
                    stats.classicHighScore = score
                    saveData()
                }
                after(1.2) { [weak self] in
                    self?.showCelebration = true
                }
            }

        } else if currentRowIndex == 5 {
            // GAME OVER - Loss
            isGameOver = true
            HapticsManager.shared.gameOver()
            SoundManager.shared.play(.defeat)
            showToast("The word was \(secretWord)", icon: "xmark.circle.fill")
            recordLoss()
            calculateLossReward()

            if gameMode == .daily {
                saveDailyRecord(didWin: false, guesses: 6)
            } else {
                score = 0
            }

            after(1.6) { [weak self] in
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
            denyPurchase("Need \(cost) Coins for Reveal Letter")
            return
        }

        let targetChars = Array(secretWord.uppercased())
        var row = grid[currentRowIndex]

        // Columns the player has already solved (green) on an earlier row — revealing
        // those again would waste coins, so prefer columns that are still unknown.
        let knownColumns = Set((0..<5).filter { c in
            grid.prefix(currentRowIndex).contains { $0.tiles[c].state == .correct }
        })
        let unresolved = (0..<5).filter { c in
            row.tiles[c].letter != targetChars[c] && !row.tiles[c].isRevealed
        }

        guard let col = unresolved.first(where: { !knownColumns.contains($0) }) ?? unresolved.first else {
            showToast("Letters already match!", icon: "sparkles")
            return
        }

        coins -= cost
        hintsUsedInCurrentGame += 1
        saveCoins()

        let correctChar = targetChars[col]
        row.tiles[col].letter = correctChar
        row.tiles[col].isRevealed = true
        row.tiles[col].state = .typing
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
            denyPurchase("Need \(cost) Coins to Eliminate Letters")
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
        HapticsManager.shared.powerUpTrigger()

        for (idx, char) in toEliminate.enumerated() {
            after(Double(idx) * 0.15) { [weak self] in
                guard let self else { return }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    _ = self.eliminatedKeys.insert(char)
                }
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
            denyPurchase("Need \(cost) Coins to Skip Word")
            return
        }

        coins -= cost
        hintsUsedInCurrentGame += 1
        saveCoins()

        // Lock input during the hand-off so taps can't land on the outgoing board
        isEvaluating = true

        HapticsManager.shared.powerUpTrigger()
        let oldWord = secretWord
        showToast("-\(cost) Coins • Skipped! Word was \(oldWord)", icon: "forward.end.fill")

        after(0.6) { [weak self] in
            guard let self else { return }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                self.startNewGame(mode: .classic)
            }
        }
    }

    private func denyPurchase(_ message: String) {
        HapticsManager.shared.invalidWordError()
        showToast(message, icon: "exclamationmark.circle.fill")
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

        after(0.3) { [weak self] in
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
        let id = UUID()
        toastID = id
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            self.toastMessage = message
            self.toastIcon = icon
        }

        // Keyed by ID (not message text) so a repeated toast isn't dismissed early
        // by the previous one's timer.
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) { [weak self] in
            guard let self, self.toastID == id else { return }
            withAnimation(.easeInOut(duration: 0.25)) {
                self.toastMessage = nil
            }
        }
    }

    // MARK: - Shake Animation
    private func triggerShake() {
        let row = currentRowIndex
        let offsets: [CGFloat] = [-12, 12, -8, 8, -4, 4, 0]
        for (index, offset) in offsets.enumerated() {
            after(Double(index) * 0.04) { [weak self] in
                guard let self, row < self.grid.count else { return }
                withAnimation(.linear(duration: 0.04)) {
                    self.grid[row].shakeOffset = offset
                }
            }
        }
    }

    // MARK: - Persistence & Stats
    /// Fixed Gregorian/POSIX formatter so the key is stable regardless of the
    /// user's calendar or locale settings.
    static let dateKeyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static func dateKey(for date: Date) -> String {
        dateKeyFormatter.string(from: date)
    }

    private func todayDateKey() -> String {
        Self.dateKey(for: Date())
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
        self.dailyGrid = self.grid
    }

    private func loadDailyRecord(for key: String) -> DailyGameRecord? {
        guard let data = UserDefaults.standard.data(forKey: "daily_record_\(key)"),
              let record = try? JSONDecoder().decode(DailyGameRecord.self, from: data) else {
            return nil
        }
        return record
    }

    private func restoreBoard(from record: DailyGameRecord, applyToGame: Bool = true) {
        let target = record.word.count == 5 ? record.word.uppercased() : WordProvider.dailyWord()
        var restored = (0..<6).map { _ in WordleRow() }

        for (rIdx, guess) in record.guesses.prefix(6).enumerated() {
            let chars = Array(guess.uppercased())
            guard chars.count == 5 else { continue }
            let states = Self.evaluate(guess: guess, target: target)
            for c in 0..<5 {
                restored[rIdx].tiles[c].letter = chars[c]
                restored[rIdx].tiles[c].state = states[c]
            }
        }

        dailyGrid = restored

        if applyToGame && gameMode == .daily {
            grid = restored
            keyboardStates.removeAll()
            for row in restored {
                for tile in row.tiles {
                    if let ch = tile.letter { updateKeyboardState(for: ch, with: tile.state) }
                }
            }
            currentRowIndex = min(record.guesses.count, 6)
        }
    }

    /// Re-reads today's daily status. Call when the app becomes active or the home
    /// screen appears so the card doesn't show yesterday's result after midnight.
    func refreshDailyStatus() {
        if let record = loadDailyRecord(for: todayDateKey()), record.isCompleted {
            dailyCompletedToday = true
            dailyWinToday = record.didWin
            dailyGuessesToday = record.guessesCount
            restoreBoard(from: record, applyToGame: false)
        } else {
            dailyCompletedToday = false
            dailyWinToday = false
            dailyGuessesToday = 0
            dailyGrid = (0..<6).map { _ in WordleRow() }
        }
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

        // Check if daily puzzle is already completed today
        refreshDailyStatus()
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
        // Also clear saved daily boards; otherwise today's puzzle stayed "completed"
        // (and the week strip kept its checkmarks) after a full reset.
        for key in UserDefaults.standard.dictionaryRepresentation().keys where key.hasPrefix("daily_record_") {
            UserDefaults.standard.removeObject(forKey: key)
        }
        refreshDailyStatus()
        coins = 100
        revealCharges = 2
        eliminateCharges = 2
        skipCharges = 2
        stats = GameStats()
        score = 0
        startNewGame(mode: gameMode, force: true)
    }
}
