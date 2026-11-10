//
//  SoundManager.swift
//  Wordle
//
//  Lightweight procedural sound engine. All effects are synthesized once into
//  PCM buffers at launch (no audio assets needed) and played through a small
//  pool of player nodes so overlapping sounds (e.g. staggered tile flips) mix.
//

import AVFoundation

final class SoundManager {
    static let shared = SoundManager()

    enum Effect: Hashable {
        case keyTap
        case keyDelete
        case uiTap
        case flip(TileEvaluationState, index: Int)
        case invalid
        case victory
        case defeat
        case coin
        case reveal
        case eliminate
        case skip
        case denied
    }

    private let engine = AVAudioEngine()
    private let sampleRate: Double = 44_100
    private lazy var format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
    private var players: [AVAudioPlayerNode] = []
    private var nextPlayer = 0
    private var buffers: [Effect: AVAudioPCMBuffer] = [:]
    private var keyTapVariants: [AVAudioPCMBuffer] = []
    private var isReady = false
    private var didPrepare = false

    private var isEnabled: Bool { SettingsManager.shared.soundEffectsEnabled }

    private init() {}

    /// Configures the audio session and pre-renders every effect. Safe to call repeatedly.
    func prepare() {
        guard !didPrepare else { return }
        didPrepare = true

        // .ambient respects the silent switch and mixes with the user's music.
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)

        for _ in 0..<10 {
            let node = AVAudioPlayerNode()
            engine.attach(node)
            do {
                try engine.connectNode(node, to: engine.mainMixerNode, format: format)
                players.append(node)
            } catch {
                engine.detach(node)
            }
        }
        engine.mainMixerNode.outputVolume = 0.85

        renderAll()

        do {
            guard !players.isEmpty else { return }
            try engine.start()
            players.forEach { try? $0.playAudio() }
            isReady = true
        } catch {
            isReady = false
        }

        NotificationCenter.default.addObserver(
            forName: .AVAudioEngineConfigurationChange,
            object: engine,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.restartEngineIfNeeded()
            }
        }
    }

    func play(_ effect: Effect) {
        guard isEnabled else { return }
        if !isReady { prepare() }
        restartEngineIfNeeded()
        guard isReady else { return }

        let buffer: AVAudioPCMBuffer?
        if effect == .keyTap, !keyTapVariants.isEmpty {
            buffer = keyTapVariants.randomElement()
        } else {
            buffer = buffers[effect]
        }
        guard let buffer else { return }

        let node = players[nextPlayer]
        nextPlayer = (nextPlayer + 1) % players.count
        node.scheduleBuffer(buffer, at: nil, options: .interrupts)
        if !node.isPlaying { try? node.playAudio() }
    }

    private func restartEngineIfNeeded() {
        guard isReady, !engine.isRunning else { return }
        try? engine.start()
        players.forEach { try? $0.playAudio() }
    }

    // MARK: - Sound Design

    private func renderAll() {
        // Pentatonic ladder so each successive tile flip climbs in pitch.
        let ladder: [Double] = [523.25, 587.33, 659.25, 783.99, 880.00] // C5 D5 E5 G5 A5

        keyTapVariants = [1.0, 1.06, 0.94].map { m in
            render(duration: 0.05) { t in
                0.22 * self.noise() * self.env(t, attack: 0.001, decay: 0.008)
                    + 0.30 * self.sine(1150 * m, t) * self.env(t, attack: 0.001, decay: 0.018)
            }
        }
        buffers[.keyTap] = keyTapVariants.first

        buffers[.keyDelete] = render(duration: 0.08) { t in
            let f = 620 - 1800 * t
            return 0.32 * self.triangle(f, t) * self.env(t, attack: 0.002, decay: 0.03)
        }

        buffers[.uiTap] = render(duration: 0.06) { t in
            0.28 * self.sine(880, t) * self.env(t, attack: 0.001, decay: 0.02)
        }

        for (i, f) in ladder.enumerated() {
            buffers[.flip(.correct, index: i)] = render(duration: 0.45) { t in
                self.bell(f, t, gain: 0.30, decay: 0.16)
            }
            buffers[.flip(.present, index: i)] = render(duration: 0.30) { t in
                0.26 * self.triangle(f * 0.75, t) * self.env(t, attack: 0.003, decay: 0.08)
            }
            buffers[.flip(.absent, index: i)] = render(duration: 0.14) { t in
                let f0 = 210 - 8 * Double(i)
                return 0.34 * self.sine(f0 - 300 * t, t) * self.env(t, attack: 0.002, decay: 0.04)
                    + 0.06 * self.noise() * self.env(t, attack: 0.001, decay: 0.01)
            }
        }

        buffers[.invalid] = render(duration: 0.26) { t in
            let gate = (t < 0.09 || (t > 0.13 && t < 0.22)) ? 1.0 : 0.0
            return 0.18 * self.softSquare(150, t) * gate * self.env(t, attack: 0.004, decay: 0.2)
        }

        buffers[.denied] = render(duration: 0.2) { t in
            let f = t < 0.08 ? 330.0 : 247.0
            return 0.24 * self.triangle(f, t) * self.env(t, attack: 0.003, decay: 0.09)
        }

        // C major arpeggio + octave sparkle
        let victoryNotes: [(Double, Double)] = [(523.25, 0.0), (659.25, 0.09), (783.99, 0.18), (1046.5, 0.27), (1318.5, 0.40)]
        buffers[.victory] = render(duration: 1.3) { t in
            var s = 0.0
            for (f, start) in victoryNotes where t >= start {
                s += self.bell(f, t - start, gain: 0.20, decay: 0.32)
            }
            return s
        }

        let defeatNotes: [(Double, Double)] = [(392.0, 0.0), (329.63, 0.18), (261.63, 0.36)]
        buffers[.defeat] = render(duration: 1.0) { t in
            var s = 0.0
            for (f, start) in defeatNotes where t >= start {
                let lt = t - start
                s += 0.22 * self.triangle(f, lt) * self.env(lt, attack: 0.01, decay: 0.22)
            }
            return s
        }

        buffers[.coin] = render(duration: 0.4) { t in
            let f = t < 0.07 ? 987.77 : 1318.51 // B5 -> E6
            let lt = t < 0.07 ? t : t - 0.07
            return 0.20 * self.softSquare(f, t) * self.env(lt, attack: 0.002, decay: t < 0.07 ? 0.05 : 0.12)
        }

        buffers[.reveal] = render(duration: 0.5) { t in
            let sweep = 0.24 * self.sineSweep(from: 420, to: 1500, duration: 0.22, t) * self.env(t, attack: 0.01, decay: 0.12)
            let sparkle = t > 0.18 ? self.bell(1760, t - 0.18, gain: 0.14, decay: 0.12) : 0
            return sweep + sparkle
        }

        buffers[.eliminate] = render(duration: 0.12) { t in
            0.30 * self.sine(780 - 3200 * t, t) * self.env(t, attack: 0.001, decay: 0.035)
        }

        buffers[.skip] = render(duration: 0.4) { t in
            let swell = sin(min(t / 0.4, 1) * .pi)
            return 0.16 * self.noise() * swell * swell
                + 0.16 * self.sineSweep(from: 900, to: 260, duration: 0.35, t) * swell
        }
    }

    // MARK: - Synthesis Primitives

    private func render(duration: Double, _ sample: (Double) -> Double) -> AVAudioPCMBuffer {
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount
        let data = buffer.floatChannelData![0]
        let fadeFrames = Int(0.004 * sampleRate)
        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            var v = sample(t)
            // Short fade-out tail to avoid clicks at buffer end
            let remaining = Int(frameCount) - i
            if remaining < fadeFrames { v *= Double(remaining) / Double(fadeFrames) }
            data[i] = Float(max(-1, min(1, v)))
        }
        return buffer
    }

    private func env(_ t: Double, attack: Double, decay: Double) -> Double {
        if t < attack { return t / attack }
        return exp(-(t - attack) / decay)
    }

    private func sine(_ f: Double, _ t: Double) -> Double { sin(2 * .pi * f * t) }

    private func triangle(_ f: Double, _ t: Double) -> Double {
        let p = (f * t).truncatingRemainder(dividingBy: 1)
        return 4 * abs(p - 0.5) - 1
    }

    /// Band-limited-ish square (first few odd harmonics) — retro but not harsh.
    private func softSquare(_ f: Double, _ t: Double) -> Double {
        sine(f, t) + sine(3 * f, t) / 3 + sine(5 * f, t) / 5
    }

    private func bell(_ f: Double, _ t: Double, gain: Double, decay: Double) -> Double {
        let e = env(t, attack: 0.002, decay: decay)
        return gain * e * (sine(f, t) + 0.35 * sine(2 * f, t) * exp(-t / (decay * 0.5)) + 0.12 * sine(3.01 * f, t) * exp(-t / (decay * 0.3)))
    }

    private func sineSweep(from f0: Double, to f1: Double, duration: Double, _ t: Double) -> Double {
        let tt = min(t, duration)
        let k = (f1 - f0) / duration
        let phase = 2 * .pi * (f0 * tt + 0.5 * k * tt * tt) + (t > duration ? 2 * .pi * f1 * (t - duration) : 0)
        return sin(phase)
    }

    private func noise() -> Double { Double.random(in: -1...1) }
}
