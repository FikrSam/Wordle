//
//  SettingsSheetView.swift
//  Wordle
//
//  Created by Fikir on 11/9/26.
//

import SwiftUI

struct SettingsSheetView: View {
    @Bindable var settings: SettingsManager
    @Bindable var viewModel: GameViewModel
    var onDismiss: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var showingResetAlert = false
    @State private var showingStatsSheet = false

    private var activePalette: ThemePalette {
        settings.themePalette
    }

    var body: some View {
        ZStack {
            AppSurface.canvas(for: colorScheme)
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header Bar with Title and Close Button
                    headerBar

                    // 1. Appearance Mode Pill Switcher
                    SegmentedPillPicker(selectedMode: $settings.appearanceMode)

                    // 2. Theme Palettes (2x2 Contextual Wordle Grid)
                    themeSection

                    // 3. Gameplay & Feedback
                    gameplaySection

                    // 4. Progress & In-Game Economy
                    progressSection

                    // 5. Data Management (Reset)
                    dataSection

                    // 6. Minimalist Footer
                    footerSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 36)
            }
        }
        .alert("Reset All Data?", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                viewModel.resetAllData()
                onDismiss()
            }
        } message: {
            Text("This will permanently clear all streaks, game statistics, and coin balances.")
        }
        .sheet(isPresented: $showingStatsSheet) {
            StatsSheetView(viewModel: viewModel, onDismiss: {
                showingStatsSheet = false
            })
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .preferredColorScheme(settings.appearanceMode.colorScheme)
        }
    }

    // MARK: - Header Bar
    private var headerBar: some View {
        HStack(alignment: .center) {
            Text("Settings")
                .font(.system(size: 28, weight: .heavy, design: .default))
                .foregroundStyle(AppSurface.primaryText(for: colorScheme))

            Spacer()

            CircularPillButton(icon: "xmark", size: 36) {
                HapticsManager.shared.keyTap()
                onDismiss()
            }
        }
    }

    // MARK: - Theme Palettes Section (2x2 Contextual Grid)
    private var themeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("THEME PALETTE")
                .font(.system(size: 12, weight: .bold, design: .default))
                .foregroundStyle(AppSurface.secondaryText(for: colorScheme))
                .padding(.horizontal, 4)

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 10),
                    GridItem(.flexible(), spacing: 10)
                ],
                spacing: 10
            ) {
                ForEach(ThemePalette.allCases) { palette in
                    themeCard(palette: palette)
                }
            }
        }
    }

    private func themeCard(palette: ThemePalette) -> some View {
        let isSelected = settings.themePalette == palette

        return Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                settings.themePalette = palette
                HapticsManager.shared.keyTap()
            }
        }) {
            VStack(alignment: .leading, spacing: 12) {
                // Top row: Palette name & selection indicator
                HStack(alignment: .center) {
                    Text(palette.rawValue)
                        .font(.system(size: 13, weight: .bold, design: .default))
                        .foregroundStyle(
                            isSelected
                                ? AppSurface.primaryText(for: colorScheme)
                                : AppSurface.secondaryText(for: colorScheme)
                        )
                        .lineLimit(1)

                    Spacer(minLength: 4)

                    if isSelected {
                        Circle()
                            .fill(palette.accentPrimary)
                            .frame(width: 18, height: 18)
                            .overlay(
                                Image(systemName: "checkmark")
                                    .font(.system(size: 9, weight: .black))
                                    .foregroundStyle(.white)
                            )
                    } else {
                        Circle()
                            .fill(AppSurface.recessed(for: colorScheme))
                            .frame(width: 18, height: 18)
                    }
                }

                // Bottom row: "W I N" 3-tile Wordle sample showing palette evaluation states
                HStack(spacing: 6) {
                    miniTile(letter: "W", fill: palette.correctColor)
                    miniTile(letter: "I", fill: palette.presentColor)
                    miniTile(
                        letter: "N",
                        fill: colorScheme == .dark
                            ? Color(red: 0.22, green: 0.22, blue: 0.25)
                            : Color(red: 0.78, green: 0.78, blue: 0.81)
                    )
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? AppSurface.card(for: colorScheme) : AppSurface.card(for: colorScheme).opacity(0.55))
            )
        }
        .buttonStyle(.plain)
    }

    private func miniTile(letter: Character, fill: Color) -> some View {
        RoundedRectangle(cornerRadius: 5, style: .continuous)
            .fill(fill)
            .overlay(
                Text(String(letter))
                    .font(.system(size: 11, weight: .heavy, design: .default))
                    .foregroundStyle(.white)
            )
            .frame(width: 26, height: 26)
    }

    // MARK: - Gameplay Section
    private var gameplaySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("GAMEPLAY & FEEDBACK")
                .font(.system(size: 12, weight: .bold, design: .default))
                .foregroundStyle(AppSurface.secondaryText(for: colorScheme))
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                // Haptic Feedback Row
                HStack(spacing: 12) {
                    settingIconBadge(icon: "iphone.radiowaves.left.and.right", color: activePalette.accentPrimary)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Haptic Feedback")
                            .font(.system(size: 15, weight: .semibold, design: .default))
                            .foregroundStyle(AppSurface.primaryText(for: colorScheme))

                        Text("Tactile keypress vibrations")
                            .font(.system(size: 12, weight: .regular, design: .default))
                            .foregroundStyle(AppSurface.secondaryText(for: colorScheme))
                    }

                    Spacer()

                    Toggle("", isOn: $settings.hapticsEnabled)
                        .labelsHidden()
                        .tint(activePalette.accentPrimary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                // Divider
                rowDivider

                // Sound Effects Row
                HStack(spacing: 12) {
                    settingIconBadge(icon: "speaker.wave.2.fill", color: activePalette.presentColor)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Sound Effects")
                            .font(.system(size: 15, weight: .semibold, design: .default))
                            .foregroundStyle(AppSurface.primaryText(for: colorScheme))

                        Text("Wins, losses and invalid words")
                            .font(.system(size: 12, weight: .regular, design: .default))
                            .foregroundStyle(AppSurface.secondaryText(for: colorScheme))
                    }

                    Spacer()

                    Toggle("", isOn: $settings.soundEffectsEnabled)
                        .labelsHidden()
                        .tint(activePalette.accentPrimary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(AppSurface.card(for: colorScheme))
            )
        }
    }

    // MARK: - Progress & Economy Section
    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PROGRESS & ECONOMY")
                .font(.system(size: 12, weight: .bold, design: .default))
                .foregroundStyle(AppSurface.secondaryText(for: colorScheme))
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                // Statistics Row
                Button(action: {
                    HapticsManager.shared.keyTap()
                    showingStatsSheet = true
                }) {
                    HStack(spacing: 12) {
                        settingIconBadge(icon: "chart.bar.fill", color: activePalette.accentPrimary)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Game Statistics")
                                .font(.system(size: 15, weight: .semibold, design: .default))
                                .foregroundStyle(AppSurface.primaryText(for: colorScheme))

                            Text("\(viewModel.stats.gamesPlayed) played • \(viewModel.stats.winRatePercent)% win rate")
                                .font(.system(size: 12, weight: .regular, design: .default))
                                .foregroundStyle(AppSurface.secondaryText(for: colorScheme))
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(AppSurface.secondaryText(for: colorScheme))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)

                // Divider
                rowDivider

                // Coin Balance Row
                HStack(spacing: 12) {
                    settingIconBadge(icon: "circle.circle.fill", color: Color(red: 0.98, green: 0.76, blue: 0.15))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Coin Balance")
                            .font(.system(size: 15, weight: .semibold, design: .default))
                            .foregroundStyle(AppSurface.primaryText(for: colorScheme))

                        Text("Earned through clean & fast solves")
                            .font(.system(size: 12, weight: .regular, design: .default))
                            .foregroundStyle(AppSurface.secondaryText(for: colorScheme))
                    }

                    Spacer()

                    HStack(spacing: 5) {
                        Image(systemName: "circle.circle.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color(red: 0.98, green: 0.76, blue: 0.15))

                        Text("\(viewModel.coins)")
                            .font(.system(size: 16, weight: .heavy, design: .default))
                            .foregroundStyle(AppSurface.primaryText(for: colorScheme))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(AppSurface.recessed(for: colorScheme))
                    )
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(AppSurface.card(for: colorScheme))
            )
        }
    }

    // MARK: - Data Management Section
    private var dataSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("DATA MANAGEMENT")
                .font(.system(size: 12, weight: .bold, design: .default))
                .foregroundStyle(AppSurface.secondaryText(for: colorScheme))
                .padding(.horizontal, 4)

            Button(action: {
                HapticsManager.shared.keyTap()
                showingResetAlert = true
            }) {
                HStack(spacing: 12) {
                    settingIconBadge(icon: "trash.fill", color: Color(red: 0.96, green: 0.25, blue: 0.37))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Reset All Data")
                            .font(.system(size: 15, weight: .semibold, design: .default))
                            .foregroundStyle(Color(red: 0.96, green: 0.25, blue: 0.37))

                        Text("Clear streaks, guesses, and coins")
                            .font(.system(size: 12, weight: .regular, design: .default))
                            .foregroundStyle(AppSurface.secondaryText(for: colorScheme))
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(AppSurface.secondaryText(for: colorScheme))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(AppSurface.card(for: colorScheme))
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Minimalist Footer
    private var footerSection: some View {
        VStack(spacing: 4) {
            Text("Wordle • Swiss Minimalist Edition")
                .font(.system(size: 12, weight: .medium, design: .default))
                .foregroundStyle(AppSurface.secondaryText(for: colorScheme))

            Text("Version 1.0 • All data stored locally")
                .font(.system(size: 11, weight: .regular, design: .default))
                .foregroundStyle(AppSurface.secondaryText(for: colorScheme).opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    // MARK: - Helper Views
    private func settingIconBadge(icon: String, color: Color) -> some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(AppSurface.recessed(for: colorScheme))
            .frame(width: 32, height: 32)
            .overlay(
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(color)
            )
    }

    private var rowDivider: some View {
        Rectangle()
            .fill(AppSurface.recessed(for: colorScheme))
            .frame(height: 1)
            .padding(.leading, 60)
    }
}
