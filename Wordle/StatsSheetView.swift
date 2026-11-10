//
//  StatsSheetView.swift
//  Wordle
//
//  Created by Fikir on 11/9/26.
//

import SwiftUI

struct StatsSheetView: View {
    @Bindable var viewModel: GameViewModel
    var onDismiss: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var copiedToClipboard = false

    private var activePalette: ThemePalette {
        SettingsManager.shared.themePalette
    }

    var body: some View {
        ZStack {
            AppSurface.canvas(for: colorScheme)
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header Bar
                    HStack(spacing: 16) {
                        CircularPillButton(icon: "chevron.left", size: 40) {
                            onDismiss()
                        }

                        Text("Player Statistics")
                            .font(.system(size: 24, weight: .heavy, design: .rounded))
                            .foregroundStyle(AppSurface.primaryText(for: colorScheme))

                        Spacer()
                    }

                    // 4 Key Stats Cards
                    HStack(spacing: 12) {
                        statCard(value: "\(viewModel.stats.gamesPlayed)", label: "Played")
                        statCard(value: "\(viewModel.stats.winRatePercent)%", label: "Win %")
                        statCard(value: "\(viewModel.stats.currentStreak)", label: "Streak")
                        statCard(value: "\(viewModel.stats.maxStreak)", label: "Max Streak")
                    }

                    // Guess Distribution Bar Chart
                    VStack(alignment: .leading, spacing: 14) {
                        Text("GUESS DISTRIBUTION")
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                            .tracking(1.2)
                            .foregroundStyle(AppSurface.secondaryText(for: colorScheme))

                        let maxGuessCount = viewModel.stats.guessDistribution.values.max() ?? 1

                        VStack(spacing: 8) {
                            ForEach(1...6, id: \.self) { guessNum in
                                let count = viewModel.stats.guessDistribution[guessNum, default: 0]
                                let ratio = maxGuessCount > 0 ? CGFloat(count) / CGFloat(max(1, maxGuessCount)) : 0

                                HStack(spacing: 10) {
                                    Text("\(guessNum)")
                                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                                        .foregroundStyle(AppSurface.secondaryText(for: colorScheme))
                                        .frame(width: 14)

                                    GeometryReader { geo in
                                        let barWidth = max(28, geo.size.width * ratio)

                                        HStack {
                                            ZStack(alignment: .trailing) {
                                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                                    .fill(
                                                        count > 0
                                                            ? activePalette.accentPrimary
                                                            : AppSurface.recessed(for: colorScheme)
                                                    )
                                                    .frame(width: barWidth, height: 26)

                                                Text("\(count)")
                                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                                    .foregroundStyle(count > 0 ? Color.white : AppSurface.secondaryText(for: colorScheme))
                                                    .padding(.trailing, 8)
                                            }
                                            Spacer()
                                        }
                                    }
                                    .frame(height: 26)
                                }
                            }
                        }
                    }
                    .padding(18)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(AppSurface.card(for: colorScheme))
                    )

                    // Classic Mode High Score
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Classic High Score")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(AppSurface.secondaryText(for: colorScheme))
                            Text("\(viewModel.stats.classicHighScore) consecutive words")
                                .font(.system(size: 18, weight: .heavy, design: .rounded))
                                .foregroundStyle(AppSurface.primaryText(for: colorScheme))
                        }

                        Spacer()

                        Image(systemName: "crown.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(Color(red: 0.96, green: 0.62, blue: 0.04))
                    }
                    .padding(18)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(AppSurface.card(for: colorScheme))
                    )

                    // Share Results Button
                    Button(action: {
                        shareStats()
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: copiedToClipboard ? "checkmark" : "square.and.arrow.up")
                                .font(.system(size: 16, weight: .bold))

                            Text(copiedToClipboard ? "Copied to Clipboard!" : "Share Statistics")
                                .font(.system(size: 16, weight: .heavy, design: .rounded))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(activePalette.accentPrimary)
                        )
                    }
                    .padding(.top, 6)
                }
                .padding(.horizontal, 20)
                .padding(.top, 36)
                .padding(.bottom, 28)
            }
        }
    }

    private func statCard(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundStyle(AppSurface.primaryText(for: colorScheme))

            Text(label)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(AppSurface.secondaryText(for: colorScheme))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(AppSurface.card(for: colorScheme))
        )
    }

    private func shareStats() {
        let text = """
        Wordle Tactile 🟩
        Games Played: \(viewModel.stats.gamesPlayed)
        Win Rate: \(viewModel.stats.winRatePercent)%
        Current Streak: \(viewModel.stats.currentStreak) 🔥
        High Score: \(viewModel.stats.classicHighScore)
        """
        UIPasteboard.general.string = text
        HapticsManager.shared.keyTap()
        withAnimation {
            copiedToClipboard = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            copiedToClipboard = false
        }
    }
}
