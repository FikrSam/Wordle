//
//  SoundManager.swift
//  Wordle
//
//  Minimal procedural sound engine. Only three moments make a sound — a win,
//  a loss, and a rejected guess — everything else relies on haptics alone.
//  Effects are synthesized once into PCM buffers (no audio assets) using pure
//  sine tones with slow attacks so they stay soft and quiet.
//

import AVFoundation

final class SoundManager {
    static let shared = SoundManager()

    enum Effect: Hashable, CaseIterable {
        case wrongGuess
        case victory
        case defeat
    }

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let sampleRate: Double = 44_100
    private lazy var format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
    private var buffers: [Effect: AVAudioPCMBuffer] = [:]
    private var isReady = false
    private var didPrepare = false

    /// Overall loudness. Kept low on purpose; individual sounds peak well below this.
    private let masterVolume: Float = 0.45

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

        engine.attach(player)
        do {
            try engine.connectNode(player, to: engine.mainMixerNode, format: format)
        } catch {
            return
        }
        engine.mainMixerNode.outputVolume = masterVolume

        renderAll()

        do {
            try engine.start()
            try player.playAudio()
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
        if !didPrepare { prepare() }
        restartEngineIfNeeded()
        guard isReady, let buffer = buffers[effect] else { return }

        // A new sound replaces whatever is still ringing, so effects never pile up.
        player.scheduleBuffer(buffer, at: nil, options: .interrupts)
        if !player.isPlaying { try? player.playAudio() }
    }

    private func restartEngineIfNeeded() {
        guard isReady, !engine.isRunning else { return }
        try? engine.start()
        try? player.playAudio()
    }

    // MARK: - Sound Design

    private func renderAll() {
        // Rejected guess: a gentle two-note "uh-uh" falling a minor third.
        buffers[.wrongGuess] = render(duration: 0.42) { t in
            self.softNote(329.63, t, start: 0.0, gain: 0.16, attack: 0.012, decay: 0.07)
                + self.softNote(277.18, t, start: 0.13, gain: 0.16, attack: 0.012, decay: 0.09)
        }

        // Win: a slow, rising C-major arpeggio with soft chime tails.
        let victoryNotes: [(Double, Double)] = [(523.25, 0.0), (659.25, 0.13), (783.99, 0.26), (1046.5, 0.42)]
        buffers[.victory] = render(duration: 1.7) { t in
            victoryNotes.reduce(0.0) { sum, note in
                sum + self.chime(note.0, t, start: note.1, gain: 0.11, decay: 0.38)
            }
        }

        // Loss: a quiet descending phrase that settles on a low note.
        let defeatNotes: [(Double, Double)] = [(392.0, 0.0), (349.23, 0.22), (293.66, 0.44)]
        buffers[.defeat] = render(duration: 1.5) { t in
            defeatNotes.reduce(0.0) { sum, note in
                sum + self.softNote(note.0, t, start: note.1, gain: 0.13, attack: 0.03, decay: 0.3)
            }
        }
    }

    // MARK: - Synthesis Primitives

    private func render(duration: Double, _ sample: (Double) -> Double) -> AVAudioPCMBuffer {
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount
        let data = buffer.floatChannelData![0]
        let fadeFrames = Int(0.03 * sampleRate)
        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            var v = sample(t)
            // Fade the tail so a sound never ends with a click.
            let remaining = Int(frameCount) - i
            if remaining < fadeFrames { v *= Double(remaining) / Double(fadeFrames) }
            data[i] = Float(max(-1, min(1, v)))
        }
        return buffer
    }

    private func env(_ t: Double, attack: Double, decay: Double) -> Double {
        if t < 0 { return 0 }
        if t < attack {
            // Smooth (raised-cosine) attack instead of a linear ramp — no hard onset.
            return 0.5 - 0.5 * cos(.pi * t / attack)
        }
        return exp(-(t - attack) / decay)
    }

    private func sine(_ f: Double, _ t: Double) -> Double { sin(2 * .pi * f * t) }

    /// A pure sine note with a soft attack.
    private func softNote(_ f: Double, _ t: Double, start: Double, gain: Double, attack: Double, decay: Double) -> Double {
        let lt = t - start
        guard lt >= 0 else { return 0 }
        return gain * sine(f, lt) * env(lt, attack: attack, decay: decay)
    }

    /// A rounded chime: mostly fundamental with a faint, quickly fading octave.
    private func chime(_ f: Double, _ t: Double, start: Double, gain: Double, decay: Double) -> Double {
        let lt = t - start
        guard lt >= 0 else { return 0 }
        let e = env(lt, attack: 0.015, decay: decay)
        return gain * e * (sine(f, lt) + 0.18 * sine(2 * f, lt) * exp(-lt / (decay * 0.4)))
    }
}
