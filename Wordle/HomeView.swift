//
//  HomeView.swift
//  Wordle
//
//  Created by Fikir on 11/9/26.
//

import SwiftUI

struct HomeView: View {
    @Bindable var viewModel: GameViewModel
    @Bindable var settings: SettingsManager
    var onSelectMode: (GameMode) -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var showingSettingsSheet = ProcessInfo.processInfo.arguments.contains("-showSettings")

    private var activePalette: ThemePalette {
        settings.themePalette
    }

    var body: some View {
        ZStack {
            // Background Canvas (Pure surface color)
            AppSurface.canvas(for: colorScheme)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Bar: Monogram left, Settings right only
                topBar
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 12)

                // Central Daily Hero Card
                dailyHeroCard
                    .padding(.horizontal, 20)

                Spacer(minLength: 12)

                // Classic Endless Mode Row
                classicEndlessRow
                    .padding(.horizontal, 20)

                Spacer(minLength: 12)

                // Calendar Week Strip
                calendarWeekStrip
                    .padding(.horizontal, 20)
                    .padding(.bottom, 10)
            }
        }
        .sheet(isPresented: $showingSettingsSheet) {
            SettingsSheetView(settings: settings, viewModel: viewModel, onDismiss: {
                showingSettingsSheet = false
            })
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .preferredColorScheme(settings.appearanceMode.colorScheme)
        }
        .onAppear {
            viewModel.refreshDailyStatus()
            if ProcessInfo.processInfo.arguments.contains("-openSettings") {
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 400_000_000)
                    showingSettingsSheet = true
                }
            }
        }
    }

    // MARK: - Top Bar
    private var topBar: some View {
        HStack {
            // Brand Monogram Badge (Surface color, no border, no shadow)
            BrandLogoBadge(
                size: 42,
                iconColor: .white,
                backgroundColor: activePalette.accentPrimary
            )

            Spacer()

            // In-Game Currency Balance Pill (No border, no shadow)
            CoinBadgeView(coins: viewModel.coins)

            // Settings button (No border, no shadow)
            CircularPillButton(icon: "gearshape.fill", size: 42) {
                showingSettingsSheet = true
            }
        }
    }

    // MARK: - Daily Hero Card
    private var dailyHeroCard: some View {
        Button(action: {
            HapticsManager.shared.keyTap()
            onSelectMode(.daily)
        }) {
            VStack(spacing: 0) {
                Spacer(minLength: 16)

                // Stacked Header: Day of week above bold date (1:1 Sudoku Style)
                VStack(spacing: 6) {
                    VStack(spacing: -10) {
                        Text(currentDayOfWeek)
                            .font(.system(size: 42, weight: .bold, design: .default))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        AppSurface.primaryText(for: colorScheme).opacity(0.45),
                                        AppSurface.primaryText(for: colorScheme).opacity(0.08)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )

                        Text(currentMonthAndDay)
                            .font(.system(size: 38, weight: .heavy, design: .default))
                            .foregroundStyle(AppSurface.primaryText(for: colorScheme))
                    }

                    // Subtitle / Live status (Only shown when not completed to eliminate redundancy with solved CTA)
                    if !viewModel.dailyCompletedToday {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color(red: 0.38, green: 0.82, blue: 0.28))
                                .frame(width: 6, height: 6)

                            Text("Daily Wordle • 5 Letters • Puzzle #\(dayOfYear)")
                                .font(.system(size: 13, weight: .medium, design: .default))
                                .foregroundStyle(AppSurface.secondaryText(for: colorScheme))
                        }
                    }
                }

                Spacer(minLength: 14)

                // Board Preview (Enlarged preview, pure surface contrast, no borders)
                dailyBoardPreview

                Spacer(minLength: 16)

                // Play / Solved CTA Button (No border, no shadow)
                dailyPlayButton

                Spacer(minLength: 16)
            }
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(AppSurface.card(for: colorScheme))
            )
        }
        .buttonStyle(PressableCardStyle(pressedScale: 0.98))
    }

    /// True when a daily game was started today but not finished (resumable).
    private var isDailyInProgress: Bool {
        viewModel.gameMode == .daily && !viewModel.isGameOver && viewModel.guessesUsed > 0
    }

    // MARK: - Daily Board Preview
    private var dailyBoardPreview: some View {
        VStack(spacing: 5) {
            ForEach(0..<6, id: \.self) { row in
                HStack(spacing: 5) {
                    ForEach(0..<5, id: \.self) { col in
                        dailyTileView(row: row, col: col)
                    }
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(AppSurface.recessed(for: colorScheme))
        )
    }

    @ViewBuilder
    private func dailyTileView(row: Int, col: Int) -> some View {
        let (fill, letter) = dailyTileData(row: row, col: col)

        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(fill)
            .overlay(
                Group {
                    if let letter {
                        Text(String(letter))
                            .font(.system(size: 21, weight: .heavy, design: .default))
                            .foregroundStyle(.white)
                    }
                }
            )
            .frame(width: 46, height: 46)
            .animation(.easeInOut(duration: 0.3).delay(Double(row * 5 + col) * 0.015), value: viewModel.dailyCompletedToday)
    }

    private func dailyTileData(row: Int, col: Int) -> (fill: Color, letter: Character?) {
        // If daily completed, display the player's actual solved board
        if viewModel.dailyCompletedToday && row < viewModel.dailyGrid.count {
            let tile = viewModel.dailyGrid[row].tiles[col]
            switch tile.state {
            case .correct:
                return (activePalette.correctColor, tile.letter)
            case .present:
                return (activePalette.presentColor, tile.letter)
            case .absent:
                let absentFill = colorScheme == .dark
                    ? Color(red: 0.22, green: 0.22, blue: 0.25)
                    : Color(red: 0.78, green: 0.78, blue: 0.81)
                return (absentFill, tile.letter)
            case .empty, .typing:
                break
            }
        }

        // Clean, pristine tile slots defined by card surface contrast
        return (AppSurface.card(for: colorScheme), nil)
    }

    // MARK: - Daily Play Button (Clean, less rounded button, no border, no shadow)
    private var dailyPlayButton: some View {
        HStack(spacing: 8) {
            if viewModel.dailyCompletedToday {
                Image(systemName: viewModel.dailyWinToday ? "checkmark" : "eye.fill")
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(viewModel.dailyWinToday ? activePalette.correctColor : AppSurface.primaryText(for: colorScheme))

                Text(viewModel.dailyWinToday ? "Solved in \(viewModel.dailyGuessesToday)" : "View Board")
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundStyle(AppSurface.primaryText(for: colorScheme))
            } else {
                Image(systemName: "play.fill")
                    .font(.system(size: 14, weight: .black))

                Text(isDailyInProgress ? "Continue" : "Play Daily")
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
            }
        }
        .foregroundStyle(viewModel.dailyCompletedToday ? AppSurface.primaryText(for: colorScheme) : Color.white)
        .padding(.horizontal, 32)
        .frame(height: 48)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(viewModel.dailyCompletedToday ? AppSurface.recessed(for: colorScheme) : activePalette.accentPrimary)
        )
    }

    // MARK: - Classic Endless Button (Simplified, less rounded, pure surface contrast)
    private var classicEndlessRow: some View {
        Button(action: {
            HapticsManager.shared.keyTap()
            onSelectMode(.classic)
        }) {
            HStack(spacing: 14) {
                Image(systemName: "infinity")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(activePalette.accentPrimary)

                Text("Classic Endless")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(AppSurface.primaryText(for: colorScheme))

                Spacer()

                if viewModel.score > 0 {
                    Text("Score \(viewModel.score)")
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundStyle(AppSurface.secondaryText(for: colorScheme))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(AppSurface.recessed(for: colorScheme))
                        )
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(AppSurface.secondaryText(for: colorScheme))
            }
            .padding(.horizontal, 20)
            .frame(height: 72)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(AppSurface.card(for: colorScheme))
            )
        }
        .buttonStyle(PressableCardStyle())
    }

    // MARK: - Calendar Week Strip (No borders, no shadows)
    private var calendarWeekStrip: some View {
        HStack(spacing: 8) {
            ForEach(recentDays) { item in
                VStack(spacing: 4) {
                    Text(item.dayAbbrev)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(AppSurface.secondaryText(for: colorScheme))

                    Text(item.dayNumber)
                        .font(.system(size: 19, weight: item.isToday ? .heavy : .bold, design: .rounded))
                        .foregroundStyle(AppSurface.primaryText(for: colorScheme))

                    if item.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .black))
                            .foregroundStyle(activePalette.correctColor)
                    } else if item.isToday {
                        Circle()
                            .fill(activePalette.accentPrimary)
                            .frame(width: 8, height: 8)
                            .padding(4)
                    } else {
                        Circle()
                            .fill(AppSurface.secondaryText(for: colorScheme).opacity(0.3))
                            .frame(width: 6, height: 6)
                            .padding(5)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 72)
                .background {
                    if item.isToday {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(AppSurface.card(for: colorScheme))
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if item.isToday {
                        HapticsManager.shared.keyTap()
                        onSelectMode(.daily)
                    }
                }
            }

            // Next Puzzle Countdown (Column 4)
            VStack(spacing: 4) {
                Text("Next in")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(AppSurface.secondaryText(for: colorScheme))

                Text("\(hoursUntilMidnight) hrs")
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundStyle(AppSurface.primaryText(for: colorScheme))

                Image(systemName: "clock")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AppSurface.secondaryText(for: colorScheme))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 72)
        }
    }

    // MARK: - Date Helpers
    private struct DayItem: Identifiable {
        let id = UUID()
        let dayAbbrev: String
        let dayNumber: String
        let isToday: Bool
        let isCompleted: Bool
    }

    private var recentDays: [DayItem] {
        let calendar = Calendar.current
        let today = Date()
        var items: [DayItem] = []

        for offset in (-2...0) {
            if let date = calendar.date(byAdding: .day, value: offset, to: today) {
                let dayFormatter = DateFormatter()
                dayFormatter.dateFormat = "EEE"
                let dayAbbrev = dayFormatter.string(from: date)

                let numFormatter = DateFormatter()
                numFormatter.dateFormat = "d"
                let dayNum = numFormatter.string(from: date)

                let key = GameViewModel.dateKey(for: date)

                let isToday = (offset == 0)
                let isCompleted = UserDefaults.standard.data(forKey: "daily_record_\(key)") != nil

                items.append(DayItem(
                    dayAbbrev: dayAbbrev,
                    dayNumber: dayNum,
                    isToday: isToday,
                    isCompleted: isCompleted
                ))
            }
        }
        return items
    }

    private var hoursUntilMidnight: Int {
        let calendar = Calendar.current
        let now = Date()
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) else { return 2 }
        let hours = calendar.dateComponents([.hour], from: now, to: tomorrow).hour ?? 2
        return max(1, hours)
    }

    private var currentDayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: Date())
    }

    private var currentMonthAndDay: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d"
        return formatter.string(from: Date())
    }

    private var dayOfYear: Int {
        Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
    }
}
