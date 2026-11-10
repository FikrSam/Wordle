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

    var body: some View {
        ZStack {
            AppSurface.canvas(for: colorScheme)
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    Text("Settings")
                        .font(.system(size: 26, weight: .heavy, design: .rounded))
                        .foregroundStyle(AppSurface.primaryText(for: colorScheme))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // 1. Appearance Segmented Pill
                    SegmentedPillPicker(selectedMode: $settings.appearanceMode)

                    // 2. Theme Accent Selector
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Theme")
                            .font(.system(size: 15, weight: .heavy, design: .rounded))
                            .foregroundStyle(AppSurface.secondaryText(for: colorScheme))

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(ThemePalette.allCases) { palette in
                                    themeCard(palette: palette)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }

                    // 3. Toggles
                    VStack(spacing: 10) {
                        toggleRow(
                            icon: "iphone.radiowaves.left.and.right",
                            iconColor: settings.themePalette.accentPrimary,
                            title: "Haptic Feedback",
                            isOn: $settings.hapticsEnabled
                        )
                    }

                    // 4. Statistics Button
                    Button(action: { showingStatsSheet = true }) {
                        HStack(spacing: 12) {
                            Image(systemName: "chart.bar.fill")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundStyle(activePalette.accentPrimary)
                                .frame(width: 28)

                            Text("Statistics")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(AppSurface.primaryText(for: colorScheme))

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(AppSurface.secondaryText(for: colorScheme))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(AppSurface.card(for: colorScheme))
                        )
                    }
                    .buttonStyle(.plain)

                    // 5. Reset Data
                    Button(action: { showingResetAlert = true }) {
                        Text("Reset All Data")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(red: 0.96, green: 0.25, blue: 0.37))
                            .padding(.top, 4)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 36)
                .padding(.bottom, 28)
            }
        }
        .alert("Reset All Data?", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                viewModel.resetAllData()
                onDismiss()
            }
        } message: {
            Text("This will reset all streaks, scores, and power-up charges.")
        }
        .sheet(isPresented: $showingStatsSheet) {
            StatsSheetView(viewModel: viewModel, onDismiss: {
                showingStatsSheet = false
            })
            .presentationDetents([.medium, .large])
            .presentationCornerRadius(20)
            .presentationDragIndicator(.visible)
            .preferredColorScheme(settings.appearanceMode.colorScheme)
        }
    }

    private var activePalette: ThemePalette {
        settings.themePalette
    }

    // Toggle Row
    private func toggleRow(icon: String, iconColor: Color, title: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(iconColor)
                .frame(width: 28)

            Text(title)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(AppSurface.primaryText(for: colorScheme))

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(activePalette.accentPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(AppSurface.card(for: colorScheme))
        )
    }

    // Theme Card
    private func themeCard(palette: ThemePalette) -> some View {
        let isSelected = settings.themePalette == palette

        return Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                settings.themePalette = palette
                HapticsManager.shared.keyTap()
            }
        }) {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 8) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(palette.accentPrimary)
                            .frame(width: 52, height: 52)

                        WordleLogoShape()
                            .fill(.white)
                            .frame(width: 28, height: 22)
                    }

                    Text(palette.rawValue)
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundStyle(AppSurface.primaryText(for: colorScheme))
                        .lineLimit(1)
                }
                .frame(width: 88, height: 100)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(isSelected ? AppSurface.recessed(for: colorScheme) : AppSurface.card(for: colorScheme))
                )

                if isSelected {
                    Circle()
                        .fill(AppSurface.primaryText(for: colorScheme))
                        .frame(width: 20, height: 20)
                        .overlay(
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .black))
                                .foregroundStyle(AppSurface.card(for: colorScheme))
                        )
                        .offset(x: 4, y: -4)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
