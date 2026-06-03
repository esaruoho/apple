// Dictation.swift — OnDeviceDictation: the ONE on-device speech-to-text engine
// for the toolbox. Apple Speech framework (SFSpeechRecognizer with
// requiresOnDeviceRecognition) + an AVAudioEngine mic tap. No FoundationModels,
// no network, no Tahoe (macOS 10.15+; on-device flag macOS 13+).
//
// Target-AGNOSTIC by design: it emits transcription strings through callbacks and
// knows nothing about where they go. AppleBar pushes them into a plain NSTextField;
// AppleToolbox's cursor-aware SpeechDictationController can layer its tentative-range
// rendering + audio capture on top of this same core (its `onText`).
//
// This file is the shared unit — both apps compile THIS, instead of each re-rolling
// SFSpeechRecognizer. Extracted 2026-06-03 from topbar/AppleToolbox.swift's
// SpeechDictationController (the working original) to kill a 3rd copy in AppleBar.
//
// FEATURE-CARD >> features/dictation-button.feature
import Foundation
import Speech
import AVFoundation

final class OnDeviceDictation: NSObject {
    private let audioEngine = AVAudioEngine()
    private let recognizer = SFSpeechRecognizer(locale: Locale.current)
        ?? SFSpeechRecognizer(locale: Locale(identifier: "en_US"))
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?

    private(set) var isRunning = false
    /// Prefer on-device recognition (keeps audio local) when the OS + hardware allow.
    var prefersOnDevice = true

    /// Live transcription, always delivered on the main queue: (text, isFinal).
    var onText: ((String, Bool) -> Void)?
    /// start/stop notifications (main queue) — for repainting a mic button.
    var onStateChange: ((Bool) -> Void)?
    /// auth/mic/availability failures, in plain language (main queue).
    var onError: ((String) -> Void)?

    /// Toggle: stop if running, else authorize (speech + mic) then start.
    func toggle() { isRunning ? stop() : authorizeThenStart() }

    /// Request Speech + Microphone permission (one-time prompts), then start.
    func authorizeThenStart() {
        SFSpeechRecognizer.requestAuthorization { [weak self] speechAuth in
            DispatchQueue.main.async {
                guard let self = self else { return }
                guard speechAuth == .authorized else {
                    self.onError?("Speech recognition isn't authorized.\nSystem Settings ▸ Privacy & Security ▸ Speech Recognition.")
                    return
                }
                AVCaptureDevice.requestAccess(for: .audio) { micOK in
                    DispatchQueue.main.async {
                        guard micOK else {
                            self.onError?("Microphone access denied.\nSystem Settings ▸ Privacy & Security ▸ Microphone.")
                            return
                        }
                        self.start()
                    }
                }
            }
        }
    }

    /// Start the mic + recognizer. Safe to call only when not already running.
    func start() {
        guard !isRunning else { return }
        guard let recognizer = recognizer, recognizer.isAvailable else {
            onError?("Speech recognizer unavailable right now."); return
        }
        let req = SFSpeechAudioBufferRecognitionRequest()
        req.shouldReportPartialResults = true
        if #available(macOS 13.0, *), prefersOnDevice, recognizer.supportsOnDeviceRecognition {
            req.requiresOnDeviceRecognition = true   // keep audio on-device
        }
        request = req

        let input = audioEngine.inputNode
        let fmt = input.outputFormat(forBus: 0)
        input.removeTap(onBus: 0)
        input.installTap(onBus: 0, bufferSize: 1024, format: fmt) { [weak self] buf, _ in
            self?.request?.append(buf)
        }
        audioEngine.prepare()
        do { try audioEngine.start() } catch {
            request = nil
            onError?("Couldn't start the microphone: \(error.localizedDescription)")
            return
        }

        task = recognizer.recognitionTask(with: req) { [weak self] result, error in
            guard let self = self else { return }
            DispatchQueue.main.async {
                // Drop callbacks that land AFTER stop() flipped isRunning — otherwise
                // a late final result re-emits the phrase (the duplicate-text bug the
                // AppleToolbox original documented).
                guard self.isRunning else { return }
                if let result = result {
                    self.onText?(result.bestTranscription.formattedString, result.isFinal)
                }
                if error != nil { self.stop() }
            }
        }
        isRunning = true
        onStateChange?(true)
    }

    /// Stop the mic + recognizer. Safe to call when not running (a no-op).
    func stop() {
        let wasRunning = isRunning
        isRunning = false                       // flip FIRST: late callbacks bail (no dupes)
        if audioEngine.isRunning { audioEngine.stop() }
        audioEngine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        task?.finish()
        task = nil
        request = nil
        if wasRunning { onStateChange?(false) }
    }
}
