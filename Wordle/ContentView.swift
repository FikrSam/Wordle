//
//  ContentView.swift
//  Wordle
//
//  Created by Fikir on 11/9/26.
//

import SwiftUI

enum ScreenDestination {
    case home
    case game(GameMode)
}

struct ContentView: View {
    @State private var viewModel = GameViewModel()
    @State private var settings = SettingsManager.shared
    @State private var destination: ScreenDestination = ProcessInfo.processInfo.arguments.contains("-startInGame") ? .game(.daily) : .home

    var body: some View {
        ZStack {
            switch destination {
            case .home:
                HomeView(
                    viewModel: viewModel,
                    settings: settings,
                    onSelectMode: { mode in
                        withAnimation(.spring(response: 0.38, dampingFraction: 0.8)) {
                            viewModel.startNewGame(mode: mode)
                            destination = .game(mode)
                        }
                    }
                )
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.98)),
                    removal: .opacity.combined(with: .scale(scale: 0.98))
                ))

            case .game:
                GameView(
                    viewModel: viewModel,
                    onDismiss: {
                        withAnimation(.spring(response: 0.38, dampingFraction: 0.8)) {
                            destination = .home
                        }
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .trailing).combined(with: .opacity)
                ))
            }
        }
        .preferredColorScheme(settings.appearanceMode.colorScheme)
        .onAppear {
            if ProcessInfo.processInfo.arguments.contains("-light") {
                settings.appearanceMode = .light
            } else if ProcessInfo.processInfo.arguments.contains("-dark") {
                settings.appearanceMode = .dark
            }

            if ProcessInfo.processInfo.arguments.contains("-startInGame") {
                let isDaily = ProcessInfo.processInfo.arguments.contains("-daily")
                viewModel.startNewGame(mode: isDaily ? .daily : .classic, force: true)
                if ProcessInfo.processInfo.arguments.contains("-testWin") {
                    let word = viewModel.secretWord
                    for ch in word {
                        viewModel.typeLetter(ch)
                    }
                    viewModel.submitGuess()
                } else if ProcessInfo.processInfo.arguments.contains("-testInvalidWord") {
                    for ch in "ABCDE" {
                        viewModel.typeLetter(ch)
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
