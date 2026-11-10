//
//  GameView.swift
//  Wordle
//
//  Created by Fikir on 11/9/26.
//

import SwiftUI

struct GameView: View {
    @Bindable var viewModel: GameViewModel
    var onDismiss: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var activePalette: ThemePalette {
        SettingsManager.shared.themePalette
    }

    private let keyboardRow1: [Character] = Array("QWERTYUIOP")
    private let keyboardRow2: [Character] = Array("ASDFGHJKL")
    private let keyboardRow3: [Character] = Array("ZXCVBNM")

    var body: some View {
        ZStack {
            // Background Canvas
            AppSurface.canvas(for: colorScheme)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // ZONE A: Top Utility Bar
                topUtilityBar
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 4)

                Spacer(minLength: 6)

                // ZONE B: The 6x5 Tactile Grid
                tactileGrid
                    .padding(.horizontal, 28)

                Spacer(minLength: 10)

                // ZONE C: Physical 3D QWERTY Keyboard
                keyboardZone
                    .padding(.horizontal, 4)

                // ZONE D: Bottom Action & Power-Up Dock
                bottomActionDock
                    .padding(.horizontal, 14)
                    .padding(.top, 8)
                    .padding(.bottom, 8)
            }

            // Confetti Overlay on Victory
            if viewModel.showConfetti {
                ConfettiBurstView()
                    .ignoresSafeArea()
                    .zIndex(50)
            }

            // Victory & Game Over Centered Modal Overlay
            if viewModel.showCelebration {
                ZStack {
                    // Dimmed backdrop
                    Color.black.opacity(colorScheme == .dark ? 0.65 : 0.45)
                        .ignoresSafeArea()
                        .transition(.opacity)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
                                viewModel.showCelebration = false
                            }
                        }

                    // Centered Modal Dialog
                    CelebrationModalView(viewModel: viewModel, onDismiss: {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
                            viewModel.showCelebration = false
                        }
                    })
                    .padding(.horizontal, 24)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.88).combined(with: .opacity),
                        removal: .scale(scale: 0.92).combined(with: .opacity)
                    ))
                }
                .zIndex(150)
            }

            // Floating Toast Banner
            if let toast = viewModel.toastMessage {
                VStack {
                    ToastBannerView(message: toast, icon: viewModel.toastIcon)
                        .padding(.top, 60)
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(200)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: viewModel.showCelebration)
    }

    // MARK: - Zone A: Top Utility Bar
    private var topUtilityBar: some View {
        HStack(spacing: 12) {
            // Back chevron
            CircularPillButton(icon: "chevron.left", size: 40) {
                onDismiss()
            }

            Spacer()

            // Center: Mode readout (clean, minimal)
            if viewModel.gameMode == .classic {
                HStack(spacing: 6) {
                    Text("SCORE")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .tracking(1.0)
                        .foregroundStyle(AppSurface.secondaryText(for: colorScheme))

                    Text("\(viewModel.score)")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundStyle(AppSurface.primaryText(for: colorScheme))
                        .contentTransition(.numericText(value: Double(viewModel.score)))
                        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: viewModel.score)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(AppSurface.card(for: colorScheme))
                )
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(activePalette.accentPrimary)

                    Text("DAILY")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .tracking(1.0)
                        .foregroundStyle(AppSurface.primaryText(for: colorScheme))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(AppSurface.card(for: colorScheme))
                )
            }

            Spacer()

            // In-game Currency Coin Badge (top right)
            CoinBadgeView(coins: viewModel.coins)
        }
    }

    // MARK: - Zone B: 6x5 Tactile Grid
    private var tactileGrid: some View {
        VStack(spacing: 6) {
            ForEach(0..<6, id: \.self) { rowIndex in
                let row = viewModel.grid[rowIndex]
                HStack(spacing: 6) {
                    ForEach(0..<5, id: \.self) { colIndex in
                        let tile = row.tiles[colIndex]
                        tactileTileView(tile: tile, isCurrentRow: rowIndex == viewModel.currentRowIndex)
                    }
                }
                .offset(x: row.shakeOffset)
            }
        }
        .frame(maxWidth: 340)
    }

    // Individual Tactile Squircle Tile
    private func tactileTileView(tile: WordleTile, isCurrentRow: Bool) -> some View {
        ZStack {
            // Tile Background Squircle (Pure surface contrast, no border)
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(tileFillColor(for: tile.state))

            // Letter
            if let letter = tile.letter {
                Text(String(letter))
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                    .foregroundStyle(tileTextColor(for: tile.state))
                    .transition(.scale(scale: 0.4).combined(with: .opacity))
            }

            // Power-Up Revealed Indicator
            if tile.isRevealed {
                VStack {
                    HStack {
                        Spacer()
                        Circle()
                            .fill(activePalette.revealColor)
                            .frame(width: 6, height: 6)
                            .padding(4)
                    }
                    Spacer()
                }
            }
        }
        .aspectRatio(1.0, contentMode: .fit)
        .scaleEffect(tile.scale)
        .rotation3DEffect(
            .degrees(tile.flipAngle),
            axis: (x: 1.0, y: 0.0, z: 0.0),
            perspective: 0.6
        )
        .offset(y: tile.bounceOffset)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(tileAccessibilityLabel(tile))
    }

    private func tileAccessibilityLabel(_ tile: WordleTile) -> String {
        guard let letter = tile.letter else { return "Empty" }
        switch tile.state {
        case .correct: return "\(letter), correct"
        case .present: return "\(letter), in the word, wrong spot"
        case .absent: return "\(letter), not in the word"
        case .empty, .typing: return tile.isRevealed ? "\(letter), revealed" : String(letter)
        }
    }

    private func tileFillColor(for state: TileEvaluationState) -> Color {
        switch state {
        case .empty:
            return AppSurface.recessed(for: colorScheme)
        case .typing:
            return AppSurface.card(for: colorScheme)
        case .correct:
            return activePalette.correctColor
        case .present:
            return activePalette.presentColor
        case .absent:
            return colorScheme == .dark
                ? Color(red: 0.16, green: 0.16, blue: 0.18)
                : Color(red: 0.83, green: 0.83, blue: 0.85)
        }
    }

    private func tileBorderColor(for state: TileEvaluationState, isRevealed: Bool, isCurrentRow: Bool) -> Color {
        if isRevealed {
            return activePalette.revealColor
        }
        switch state {
        case .empty:
            return AppSurface.border(for: colorScheme)
        case .typing:
            return colorScheme == .dark ? Color.white.opacity(0.35) : Color.black.opacity(0.2)
        case .correct, .present, .absent:
            return Color.clear
        }
    }

    private func tileTextColor(for state: TileEvaluationState) -> Color {
        switch state {
        case .empty, .typing:
            return AppSurface.primaryText(for: colorScheme)
        case .correct, .present:
            return Color.white
        case .absent:
            return colorScheme == .dark ? Color.white.opacity(0.45) : Color.black.opacity(0.4)
        }
    }

    // MARK: - Zone C: Physical 3D Keyboard
    private var keyboardZone: some View {
        VStack(spacing: 5) {
            // Row 1: Q - P
            HStack(spacing: 4) {
                ForEach(keyboardRow1, id: \.self) { char in
                    TactileKeycapButton(
                        title: String(char),
                        state: viewModel.keyboardStates[char] ?? .empty,
                        isEliminated: viewModel.eliminatedKeys.contains(char)
                    ) {
                        viewModel.typeLetter(char)
                    }
                }
            }

            // Row 2: A - L (indented)
            HStack(spacing: 4) {
                Spacer(minLength: 12)
                ForEach(keyboardRow2, id: \.self) { char in
                    TactileKeycapButton(
                        title: String(char),
                        state: viewModel.keyboardStates[char] ?? .empty,
                        isEliminated: viewModel.eliminatedKeys.contains(char)
                    ) {
                        viewModel.typeLetter(char)
                    }
                }
                Spacer(minLength: 12)
            }

            // Row 3: Z - M + Backspace
            HStack(spacing: 4) {
                Spacer(minLength: 6)
                ForEach(keyboardRow3, id: \.self) { char in
                    TactileKeycapButton(
                        title: String(char),
                        state: viewModel.keyboardStates[char] ?? .empty,
                        isEliminated: viewModel.eliminatedKeys.contains(char)
                    ) {
                        viewModel.typeLetter(char)
                    }
                }

                // Backspace Keycap
                TactileKeycapButton(
                    title: "",
                    icon: "delete.left.fill",
                    width: 48,
                    state: .empty
                ) {
                    viewModel.deleteLetter()
                }
                Spacer(minLength: 6)
            }
        }
    }

    // MARK: - Zone D: Bottom Action & Power-Up Dock (Currency Cost Based)
    private var bottomActionDock: some View {
        HStack(spacing: 8) {
            // Power-Up 1: Reveal Letter (50 Coins)
            TactilePowerUpButton(
                powerUp: .reveal,
                coinCost: PowerUpType.reveal.coinCost,
                playerCoins: viewModel.coins,
                accentColor: activePalette.revealColor
            ) {
                viewModel.useRevealLetter()
            }

            // Power-Up 2: Eliminate 3 Letters (35 Coins)
            TactilePowerUpButton(
                powerUp: .eliminate,
                coinCost: PowerUpType.eliminate.coinCost,
                playerCoins: viewModel.coins,
                customIcon: "scope",
                accentColor: activePalette.eliminateColor
            ) {
                viewModel.useEliminateLetters()
            }

            // Primary SUBMIT Button — green when valid word, red when not a word, grey when incomplete
            let submitState: SubmitButtonState = {
                if viewModel.isGameOver {
                    return .proceed(viewModel.gameMode == .classic ? "NEXT WORD" : "RESULTS")
                }
                guard viewModel.currentRowIndex < 6 && !viewModel.isEvaluating else {
                    return .busy
                }
                let row = viewModel.grid[viewModel.currentRowIndex]
                guard row.isComplete else {
                    return .incomplete
                }
                return viewModel.isCurrentWordValid ? .valid : .invalid
            }()

            TactileSubmitButton(state: submitState) {
                if viewModel.isGameOver {
                    // After dismissing the result modal, the dock offers a way forward
                    // instead of leaving the player on a dead board.
                    if viewModel.gameMode == .classic {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            viewModel.startNewGame(mode: .classic)
                        }
                    } else {
                        viewModel.showCelebration = true
                    }
                } else {
                    viewModel.submitGuess()
                }
            }

            // Skip Word (Classic Mode only - 25 Coins)
            if viewModel.gameMode == .classic {
                TactilePowerUpButton(
                    powerUp: .skip,
                    coinCost: PowerUpType.skip.coinCost,
                    playerCoins: viewModel.coins,
                    accentColor: activePalette.skipColor
                ) {
                    viewModel.useSkipWord()
                }
            }
        }
        .frame(height: 56)
    }
}

// MARK: - Celebration Bottom Sheet
// MARK: - Victory & Game Over Modal Dialog (Centered modal, zero borders, pure surface contrast)
private struct CelebrationModalView: View {
    @Bindable var viewModel: GameViewModel
    var onDismiss: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var appeared = false
    @State private var displayedCoins = 0
    private var activePalette: ThemePalette {
        SettingsManager.shared.themePalette
    }

    var body: some View {
        VStack(spacing: 16) {
            // Header icon badge (less rounded squircle)
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(viewModel.isVictory ? activePalette.correctColor.opacity(0.15) : Color(red: 0.96, green: 0.25, blue: 0.37).opacity(0.15))
                    .frame(width: 54, height: 54)

                Image(systemName: viewModel.isVictory ? "trophy.fill" : "xmark")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(viewModel.isVictory ? activePalette.correctColor : Color(red: 0.96, green: 0.25, blue: 0.37))
                    .symbolEffect(.bounce, value: appeared)
            }
            .scaleEffect(appeared ? 1 : 0.4)
            .rotationEffect(.degrees(appeared ? 0 : -25))
            .padding(.top, 4)

            // Title & Word
            VStack(spacing: 4) {
                Text(viewModel.isVictory ? "Magnificent!" : "Puzzle Ended")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundStyle(AppSurface.primaryText(for: colorScheme))

                Text(viewModel.secretWord)
                    .font(.system(size: 19, weight: .black, design: .rounded))
                    .tracking(2.5)
                    .foregroundStyle(activePalette.accentPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(AppSurface.recessed(for: colorScheme))
                    )
            }

            // Stats
            HStack(spacing: 10) {
                statPill(title: "Guesses", value: viewModel.isVictory ? "\(viewModel.guessesUsed)/6" : "X/6")
                statPill(title: "Streak", value: "\(viewModel.stats.currentStreak)")
                if viewModel.gameMode == .classic {
                    statPill(title: "Score", value: "\(viewModel.score)")
                }
            }

            // Performance Currency Rewards (Pure surface contrast, no borders, no shadows)
            if viewModel.lastCoinsEarned > 0 {
                VStack(spacing: 7) {
                    HStack {
                        HStack(spacing: 6) {
                            Image(systemName: "circle.circle.fill")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(Color(red: 0.98, green: 0.72, blue: 0.15))
                            Text("Performance Rewards")
                                .font(.system(size: 13, weight: .heavy, design: .rounded))
                                .foregroundStyle(AppSurface.primaryText(for: colorScheme))
                        }
                        Spacer()
                        HStack(spacing: 4) {
                            Text("+\(displayedCoins)")
                                .font(.system(size: 14, weight: .heavy, design: .rounded))
                                .foregroundStyle(Color(red: 0.98, green: 0.72, blue: 0.15))
                                .contentTransition(.numericText(value: Double(displayedCoins)))
                                .monospacedDigit()
                            Image(systemName: "circle.circle.fill")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Color(red: 0.98, green: 0.72, blue: 0.15))
                        }
                    }

                    ForEach(Array(viewModel.lastRewardBreakdown.enumerated()), id: \.element.id) { index, reward in
                        HStack {
                            HStack(spacing: 6) {
                                Image(systemName: reward.icon)
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(AppSurface.secondaryText(for: colorScheme))
                                Text(reward.title)
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundStyle(AppSurface.secondaryText(for: colorScheme))
                            }
                            Spacer()
                            Text("+\(reward.amount)")
                                .font(.system(size: 12, weight: .heavy, design: .rounded))
                                .foregroundStyle(AppSurface.primaryText(for: colorScheme))
                        }
                        .opacity(appeared ? 1 : 0)
                        .offset(x: appeared ? 0 : -14)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.25 + Double(index) * 0.08), value: appeared)
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(AppSurface.recessed(for: colorScheme))
                )
            }

            // Action Button
            Button(action: {
                HapticsManager.shared.submitTap()
                SoundManager.shared.play(.uiTap)
                onDismiss()
                if viewModel.gameMode == .classic {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        viewModel.startNewGame(mode: .classic)
                    }
                }
            }) {
                Text(viewModel.gameMode == .classic ? "Next Word" : "Done")
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(activePalette.accentPrimary)
                    )
            }
            .buttonStyle(PressableCardStyle(pressedScale: 0.96))
            .padding(.top, 4)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppSurface.card(for: colorScheme))
        )
        .frame(maxWidth: 330)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.55).delay(0.08)) {
                appeared = true
            }
            // Count the reward total up once the rows have landed
            let target = viewModel.lastCoinsEarned
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                withAnimation(.easeOut(duration: 0.6)) {
                    displayedCoins = target
                }
            }
        }
    }

    private func statPill(title: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundStyle(AppSurface.primaryText(for: colorScheme))
            Text(title)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(AppSurface.secondaryText(for: colorScheme))
        }
        .frame(minWidth: 64)
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(AppSurface.recessed(for: colorScheme))
        )
    }
}
