//
//  TactileComponents.swift
//  Wordle
//
//  Created by Fikir on 11/9/26.
//

import SwiftUI

// MARK: - App Color System
enum AppSurface {
    /// Canvas grouped background
    static func canvas(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(red: 0.07, green: 0.07, blue: 0.08) // Deep matte obsidian #121214
            : Color(red: 0.95, green: 0.95, blue: 0.97) // Warm light-gray #F2F2F7
    }

    /// Elevated card surface
    static func card(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(red: 0.11, green: 0.11, blue: 0.12) // Elevated charcoal #1C1C1E
            : Color.white                               // Pure white #FFFFFF
    }

    /// Recessed slot or empty tile fill
    static func recessed(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(red: 0.15, green: 0.15, blue: 0.17) // Soft recessed dark #27272A
            : Color(red: 0.90, green: 0.90, blue: 0.92) // Soft recessed off-white #E5E5EA
    }

    /// Subtle muted borders
    static func border(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(red: 0.17, green: 0.17, blue: 0.18) // Muted border #2C2C2E
            : Color(red: 0.85, green: 0.85, blue: 0.87) // Soft border #D8D8DC
    }

    /// Primary text
    static func primaryText(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white : Color(red: 0.11, green: 0.11, blue: 0.12)
    }

    /// Secondary muted text
    static func secondaryText(for colorScheme: ColorScheme) -> Color {
        Color(red: 0.56, green: 0.56, blue: 0.58) // Mid-gray #8E8E93
    }
}

// MARK: - Tactile 3D Keycap Button
struct TactileKeycapButton: View {
    let title: String
    var icon: String? = nil
    var width: CGFloat? = nil
    var state: TileEvaluationState = .empty
    var isEliminated: Bool = false
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var isPressed: Bool = false

    private var activePalette: ThemePalette {
        SettingsManager.shared.themePalette
    }

    // Top face background color based on state
    private var keyFaceColor: Color {
        if isEliminated {
            return colorScheme == .dark
                ? Color(red: 0.12, green: 0.12, blue: 0.13)
                : Color(red: 0.88, green: 0.88, blue: 0.90)
        }

        switch state {
        case .correct:
            return activePalette.correctColor
        case .present:
            return activePalette.presentColor
        case .absent:
            return colorScheme == .dark
                ? Color(red: 0.18, green: 0.18, blue: 0.20)
                : Color(red: 0.80, green: 0.80, blue: 0.82)
        case .typing, .empty:
            return colorScheme == .dark
                ? Color(red: 0.23, green: 0.23, blue: 0.25)
                : Color.white
        }
    }

    // Darker bottom lip for physical 3D button effect
    private var keyLipColor: Color {
        if isEliminated {
            return colorScheme == .dark
                ? Color(red: 0.08, green: 0.08, blue: 0.09)
                : Color(red: 0.78, green: 0.78, blue: 0.80)
        }

        switch state {
        case .correct:
            return activePalette.correctColor.opacity(0.8)
        case .present:
            return activePalette.presentColor.opacity(0.8)
        case .absent:
            return colorScheme == .dark
                ? Color(red: 0.12, green: 0.12, blue: 0.14)
                : Color(red: 0.70, green: 0.70, blue: 0.72)
        case .typing, .empty:
            return colorScheme == .dark
                ? Color(red: 0.14, green: 0.14, blue: 0.15)
                : Color(red: 0.78, green: 0.78, blue: 0.80)
        }
    }

    private var keyTextColor: Color {
        if isEliminated {
            return AppSurface.secondaryText(for: colorScheme).opacity(0.4)
        }

        switch state {
        case .correct, .present:
            return .white
        case .absent:
            return colorScheme == .dark ? Color.white.opacity(0.4) : Color.black.opacity(0.35)
        case .typing, .empty:
            return AppSurface.primaryText(for: colorScheme)
        }
    }

    var body: some View {
        Button(action: {
            guard !isEliminated else { return }
            HapticsManager.shared.keyTap()
            action()
        }) {
            ZStack(alignment: .bottom) {
                // Bottom lip shadow layer (fixed underneath)
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(keyLipColor)
                    .frame(height: 50)
                    .offset(y: 2.5)

                // Depressible top face
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(keyFaceColor)
                    .overlay(
                        Group {
                            if let icon {
                                Image(systemName: icon)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(keyTextColor)
                            } else {
                                Text(title)
                                    .font(.system(size: 19, weight: .bold, design: .rounded))
                                    .foregroundStyle(keyTextColor)
                            }
                        }
                    )
                    .frame(height: 48)
                    .offset(y: isPressed ? 2.5 : 0)
            }
            .frame(height: 52)
            .frame(maxWidth: width ?? .infinity)
            .opacity(isEliminated ? 0.38 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isPressed)
            .animation(.easeInOut(duration: 0.25), value: state)
            .animation(.easeInOut(duration: 0.25), value: isEliminated)
        }
        .buttonStyle(KeycapButtonStyle(isPressed: $isPressed))
        .disabled(isEliminated)
    }
}

// Custom button style to capture press state
private struct KeycapButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { _, newValue in
                isPressed = newValue
            }
    }
}

// MARK: - Currency Badge
struct CoinBadgeView: View {
    let coins: Int
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "circle.circle.fill")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color(red: 0.98, green: 0.72, blue: 0.15))

            Text("\(coins)")
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundStyle(AppSurface.primaryText(for: colorScheme))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(AppSurface.recessed(for: colorScheme))
        )
    }
}

// MARK: - Zone D: Power-Up Button (Cost-based currency)
struct TactilePowerUpButton: View {
    let powerUp: PowerUpType
    let coinCost: Int
    let playerCoins: Int
    var customIcon: String? = nil
    var accentColor: Color
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var isPressed: Bool = false

    private var isAffordable: Bool {
        playerCoins >= coinCost
    }

    var body: some View {
        Button(action: {
            HapticsManager.shared.powerUpTrigger()
            action()
        }) {
            ZStack(alignment: .bottom) {
                // Bottom lip
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(accentColor.opacity(isAffordable ? 0.75 : 0.15))
                    .frame(width: 58, height: 52)
                    .offset(y: 2)

                // Top face
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isAffordable ? accentColor : AppSurface.recessed(for: colorScheme))
                    .frame(width: 58, height: 50)
                    .overlay(
                        VStack(spacing: 2) {
                            Image(systemName: customIcon ?? powerUp.iconName)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(isAffordable ? Color.white : AppSurface.secondaryText(for: colorScheme))

                            HStack(spacing: 3) {
                                Image(systemName: "circle.circle.fill")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundStyle(isAffordable ? Color(red: 1.0, green: 0.90, blue: 0.40) : AppSurface.secondaryText(for: colorScheme))
                                Text("\(coinCost)")
                                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                                    .foregroundStyle(isAffordable ? Color.white.opacity(0.95) : AppSurface.secondaryText(for: colorScheme))
                            }
                        }
                    )
                    .offset(y: isPressed ? 2 : 0)
            }
            .frame(width: 60, height: 54)
            .scaleEffect(isPressed ? 0.94 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.65), value: isPressed)
        }
        .buttonStyle(KeycapButtonStyle(isPressed: $isPressed))
    }
}

// MARK: - Submit Button State
enum SubmitButtonState: Equatable {
    case incomplete  // < 5 letters entered (grey / recessed)
    case valid       // 5 letters entered & verified valid word (green / accent)
    case invalid     // 5 letters entered & NOT in word list (red / matte crimson)
}

// MARK: - Zone D: Wide Plump SUBMIT Button
struct TactileSubmitButton: View {
    let state: SubmitButtonState
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var isPressed: Bool = false

    private var activePalette: ThemePalette {
        SettingsManager.shared.themePalette
    }

    private var faceColor: Color {
        switch state {
        case .valid:
            return activePalette.accentPrimary
        case .invalid:
            return Color(red: 0.92, green: 0.26, blue: 0.26) // Matte Crimson Red
        case .incomplete:
            return AppSurface.recessed(for: colorScheme)
        }
    }

    private var lipColor: Color {
        switch state {
        case .valid:
            return activePalette.accentPrimary.opacity(0.8)
        case .invalid:
            return Color(red: 0.72, green: 0.18, blue: 0.18) // Darker Red lip
        case .incomplete:
            return AppSurface.border(for: colorScheme)
        }
    }

    private var textColor: Color {
        switch state {
        case .valid, .invalid:
            return .white
        case .incomplete:
            return AppSurface.secondaryText(for: colorScheme)
        }
    }

    var body: some View {
        Button(action: {
            guard state != .incomplete else { return }
            HapticsManager.shared.submitTap()
            action()
        }) {
            ZStack(alignment: .bottom) {
                // Bottom lip
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(lipColor)
                    .frame(height: 52)
                    .offset(y: 2.5)

                // Top face
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(faceColor)
                    .frame(height: 50)
                    .overlay(
                        HStack(spacing: 8) {
                            Text("SUBMIT")
                                .font(.system(size: 18, weight: .heavy, design: .rounded))
                                .tracking(1.0)
                                .foregroundStyle(textColor)
                        }
                    )
                    .offset(y: isPressed ? 2.5 : 0)
            }
            .frame(height: 54)
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: state)
            .animation(.spring(response: 0.2, dampingFraction: 0.65), value: isPressed)
        }
        .buttonStyle(KeycapButtonStyle(isPressed: $isPressed))
    }
}

// MARK: - Continuous Pill Wrapper (Top Utility Bar & Hub)
struct ContinuousPill<Content: View>: View {
    var paddingH: CGFloat = 14
    var paddingV: CGFloat = 8
    var backgroundColor: Color? = nil
    var borderColor: Color? = nil
    @ViewBuilder let content: () -> Content

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        content()
            .padding(.horizontal, paddingH)
            .padding(.vertical, paddingV)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(backgroundColor ?? AppSurface.card(for: colorScheme))
            )
    }
}

// MARK: - Circular / Squircle Pill Button
struct CircularPillButton: View {
    let icon: String
    var size: CGFloat = 44
    var isAccent: Bool = false
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var isPressed: Bool = false

    private var activePalette: ThemePalette {
        SettingsManager.shared.themePalette
    }

    var body: some View {
        Button(action: {
            HapticsManager.shared.keyTap()
            action()
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isAccent ? activePalette.accentPrimary : AppSurface.card(for: colorScheme))

                Image(systemName: icon)
                    .font(.system(size: size * 0.42, weight: .bold))
                    .foregroundStyle(isAccent ? Color.white : AppSurface.primaryText(for: colorScheme))
            }
            .frame(width: size, height: size)
            .scaleEffect(isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.65), value: isPressed)
        }
        .buttonStyle(KeycapButtonStyle(isPressed: $isPressed))
    }
}

// MARK: - Reference Sudoku Segmented Pill Picker
struct SegmentedPillPicker: View {
    @Binding var selectedMode: AppearanceMode
    @Namespace private var animationNamespace
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppearanceMode.allCases) { mode in
                let isSelected = selectedMode == mode

                Button(action: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        selectedMode = mode
                        HapticsManager.shared.keyTap()
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: mode.iconName)
                            .font(.system(size: 14, weight: .semibold))

                        if isSelected {
                            Text(mode.rawValue)
                                .font(.system(size: 14, weight: .bold, design: .default))
                        }
                    }
                    .foregroundStyle(
                        isSelected
                            ? AppSurface.primaryText(for: colorScheme)
                            : AppSurface.secondaryText(for: colorScheme)
                    )
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .background {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(AppSurface.card(for: colorScheme))
                                .matchedGeometryEffect(id: "ActivePillSegment", in: animationNamespace)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(AppSurface.recessed(for: colorScheme))
        )
    }
}

// MARK: - Toast Banner Notification
struct ToastBannerView: View {
    let message: String
    var icon: String = "info.circle.fill"

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.white)

            Text(message)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(red: 0.12, green: 0.12, blue: 0.14))
        )
        .transition(.move(edge: .top).combined(with: .opacity).combined(with: .scale(scale: 0.9)))
    }
}

// MARK: - Confetti Particle Burst
struct ConfettiBurstView: View {
    @State private var particles: [ConfettiParticle] = []

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                for particle in particles {
                    let rect = CGRect(
                        x: particle.x,
                        y: particle.y,
                        width: particle.size,
                        height: particle.size * 0.6
                    )
                    var shapeContext = context
                    shapeContext.translateBy(x: rect.midX, y: rect.midY)
                    shapeContext.rotate(by: Angle(degrees: particle.rotation))
                    shapeContext.fill(
                        RoundedRectangle(cornerRadius: 2, style: .continuous).path(
                            in: CGRect(x: -rect.width / 2, y: -rect.height / 2, width: rect.width, height: rect.height)
                        ),
                        with: .color(particle.color)
                    )
                }
            }
        }
        .onAppear {
            generateParticles()
        }
        .allowsHitTesting(false)
    }

    private func generateParticles() {
        let colors: [Color] = [
            Color(red: 0.18, green: 0.74, blue: 0.52),
            Color(red: 0.31, green: 0.27, blue: 0.90),
            Color(red: 0.96, green: 0.62, blue: 0.04),
            Color(red: 0.96, green: 0.25, blue: 0.37),
            Color(red: 0.65, green: 0.33, blue: 0.97),
            Color(red: 0.20, green: 0.70, blue: 0.95)
        ]

        var newParticles: [ConfettiParticle] = []
        for _ in 0..<80 {
            let p = ConfettiParticle(
                x: CGFloat.random(in: 40...350),
                y: CGFloat.random(in: 50...250),
                size: CGFloat.random(in: 8...14),
                color: colors.randomElement() ?? .yellow,
                rotation: Double.random(in: 0...360)
            )
            newParticles.append(p)
        }
        particles = newParticles
    }
}

private struct ConfettiParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var color: Color
    var rotation: Double
}
