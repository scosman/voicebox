//
//  VBSwiftListener.swift
//  voicebox
//
//  Created by Steve Cosman on 2024-04-03.
//

import Foundation
import WhisperKit

@objc
public class VBSwiftListener: NSObject {
    ///
    private var whisperKit: WhisperKit?
    private var isRecording: Bool = false
    private var isTranscribing: Bool = false
    private var transcriptionTask: Task<Void, Never>? = nil
    private var useVAD: Bool = true
    private var lastBufferSize: Int = 0
    private var silenceThreshold: Double = 0.3
    private var currentText = ""
    private var requiredSegmentsForConfirmation: Int = 2
    private var lastConfirmedSegmentEndSeconds: Float = 0
    private var sampleLength: Double = 224
    private var confirmedSegments: [TranscriptionSegment] = []
    private var unconfirmedSegments: [TranscriptionSegment] = []
    private var unconfirmedText: [String] = []
    private var currentFallbacks: Int = 0
    private var compressionCheckWindow: Double = 20
    
    /*private var confirmedText: String = ""
    private var hypothesisWords: [WordTiming] = []*/
    
    @objc
    public func start() async throws {
        Task(priority: .userInitiated) {
            // TODO concurrency
            if whisperKit == nil {
                whisperKit = try? await WhisperKit()
            }
            if isRecording {
                return
            }
            guard let whisperKit = self.whisperKit else { return }
            try? whisperKit.audioProcessor.startRecordingLive { _ in
                /*DispatchQueue.main.async {
                    var energyToDisplay: [EnergyValue] = []
                    for (idx, val) in whisperKit.audioProcessor.relativeEnergy.suffix(energyToDisplayCount).enumerated() {
                        energyToDisplay.append(EnergyValue(index: idx, value: val))
                    }
                    bufferEnergy = energyToDisplay
                }*/
            }
            
            // Delay the timer start by 1 second
            isRecording = true
            isTranscribing = true
            realtimeLoop()
        }
    }
    
    public func stop() {
        guard let whisperKit = whisperKit else { return }
        whisperKit.audioProcessor.stopRecording()
    }
    
    func realtimeLoop() {
        transcriptionTask = Task {
            while isRecording && isTranscribing {
                do {
                    try await transcribeCurrentBuffer()
                } catch {
                    print("Error: \(error.localizedDescription)")
                    break
                }
            }
        }
    }
    
    func transcribeCurrentBuffer() async throws {
        guard let whisperKit = whisperKit else { return }

        // Retrieve the current audio buffer from the audio processor
        let currentBuffer = whisperKit.audioProcessor.audioSamples

        // Calculate the size and duration of the next buffer segment
        let nextBufferSize = currentBuffer.count - lastBufferSize
        let nextBufferSeconds = Float(nextBufferSize) / Float(WhisperKit.sampleRate)

        // Only run the transcribe if the next buffer has at least 1 second of audio
        guard nextBufferSeconds > 1 else {
            /*await MainActor.run {
                if currentText == "" {
                    currentText = "Waiting for speech..."
                }
            }*/
            try await Task.sleep(nanoseconds: 100_000_000) // sleep for 100ms for next buffer
            return
        }

        if useVAD {
            // Retrieve the current relative energy values from the audio processor
            let currentRelativeEnergy = whisperKit.audioProcessor.relativeEnergy

            // Calculate the number of energy values to consider based on the duration of the next buffer
            // Each energy value corresponds to 1 buffer length (100ms of audio), hence we divide by 0.1
            let energyValuesToConsider = Int(nextBufferSeconds / 0.1)

            // Extract the relevant portion of energy values from the currentRelativeEnergy array
            let nextBufferEnergies = currentRelativeEnergy.suffix(energyValuesToConsider)

            // Determine the number of energy values to check for voice presence
            // Considering up to the last 1 second of audio, which translates to 10 energy values
            let numberOfValuesToCheck = max(10, nextBufferEnergies.count - 10)

            // Check if any of the energy values in the considered range exceed the silence threshold
            // This indicates the presence of voice in the buffer
            let voiceDetected = nextBufferEnergies.prefix(numberOfValuesToCheck).contains { $0 > Float(silenceThreshold) }

            // Only run the transcribe if the next buffer has voice
            guard voiceDetected else {
                /*await MainActor.run {
                    if currentText == "" {
                        currentText = "Waiting for speech..."
                    }
                }*/
                NSLog("Swift: waiting for speech")

                //                if nextBufferSeconds > 30 {
                //                    // This is a completely silent segment of 30s, so we can purge the audio and confirm anything pending
                //                    lastConfirmedSegmentEndSeconds = 0
                //                    whisperKit.audioProcessor.purgeAudioSamples(keepingLast: 2 * WhisperKit.sampleRate) // keep last 2s to include VAD overlap
                //                    currentBuffer = whisperKit.audioProcessor.audioSamples
                //                    lastBufferSize = 0
                //                    confirmedSegments.append(contentsOf: unconfirmedSegments)
                //                    unconfirmedSegments = []
                //                }

                // Sleep for 100ms and check the next buffer
                try await Task.sleep(nanoseconds: 100_000_000)
                return
            }
        }

        // Run transcribe
        lastBufferSize = currentBuffer.count

        let transcription = try await transcribeAudioSamples(Array(currentBuffer))

        // We need to run this next part on the main thread
        await MainActor.run {
            currentText = ""
            unconfirmedText = []
            guard let segments = transcription?.segments else {
                return
            }

//            self.tokensPerSecond = transcription?.timings?.tokensPerSecond ?? 0
//            self.realTimeFactor = transcription?.timings?.realTimeFactor ?? 0
//            self.firstTokenTime = transcription?.timings?.firstTokenTime ?? 0
//            self.pipelineStart = transcription?.timings?.pipelineStart ?? 0
//            self.currentLag = transcription?.timings?.decodingLoop ?? 0

            // Logic for moving segments to confirmedSegments
            if segments.count > requiredSegmentsForConfirmation {
                // Calculate the number of segments to confirm
                let numberOfSegmentsToConfirm = segments.count - requiredSegmentsForConfirmation

                // Confirm the required number of segments
                let confirmedSegmentsArray = Array(segments.prefix(numberOfSegmentsToConfirm))
                let remainingSegments = Array(segments.suffix(requiredSegmentsForConfirmation))

                // Update lastConfirmedSegmentEnd based on the last confirmed segment
                if let lastConfirmedSegment = confirmedSegmentsArray.last, lastConfirmedSegment.end > lastConfirmedSegmentEndSeconds {
                    lastConfirmedSegmentEndSeconds = lastConfirmedSegment.end

                    // Add confirmed segments to the confirmedSegments array
                    if !self.confirmedSegments.contains(confirmedSegmentsArray) {
                        self.confirmedSegments.append(contentsOf: confirmedSegmentsArray)
                    }
                }

                // Update transcriptions to reflect the remaining segments
                self.unconfirmedSegments = remainingSegments
            } else {
                // Handle the case where segments are fewer or equal to required
                self.unconfirmedSegments = segments
            }
        }
    }
    
    
    func transcribeAudioSamples(_ samples: [Float]) async throws -> TranscriptionResult? {
        guard let whisperKit = whisperKit else { return nil }

        let languageCode = "en"
        let task: DecodingTask = .transcribe
        let seekClip = [lastConfirmedSegmentEndSeconds]

        let options = DecodingOptions(
            verbose: false,
            task: task,
            language: languageCode,
            temperatureFallbackCount: 3, // limit fallbacks for realtime
            sampleLength: Int(sampleLength), // reduced sample length for realtime
            skipSpecialTokens: true,
            clipTimestamps: seekClip
        )

        // Early stopping checks
        let decodingCallback: ((TranscriptionProgress) -> Bool?) = { progress in
            DispatchQueue.main.async {
                let fallbacks = Int(progress.timings.totalDecodingFallbacks)
                if progress.text.count < self.currentText.count {
                    if fallbacks == self.currentFallbacks {
                        self.unconfirmedText.append(self.currentText)
                    } else {
                        print("Fallback occured: \(fallbacks)")
                    }
                }
                self.currentText = progress.text
                self.currentFallbacks = fallbacks
            }
            // Check early stopping
            let currentTokens = progress.tokens
            let checkWindow = Int(self.compressionCheckWindow)
            if currentTokens.count > checkWindow {
                let checkTokens: [Int] = currentTokens.suffix(checkWindow)
                let compressionRatio = compressionRatio(of: checkTokens)
                if compressionRatio > options.compressionRatioThreshold! {
                    return false
                }
            }
            if progress.avgLogprob! < options.logProbThreshold! {
                return false
            }

            return nil
        }

        let transcription = try await whisperKit.transcribe(audioArray: samples, decodeOptions: options, callback: decodingCallback)
        return transcription
    }

}
