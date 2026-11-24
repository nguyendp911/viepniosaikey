import SwiftUI
import PhotosUI
import Vision
import Speech
import AVFoundation
import EventKit
import UIKit
import LocalAuthentication

/// Recording is explicit, and transient audio is deleted when transcription ends.
@MainActor
final class VoiceTranscriber: ObservableObject {
    @Published var recording = false
    @Published var errorText = ""
    private var recorder: AVAudioRecorder?
    private let file = FileManager.default.temporaryDirectory
        .appendingPathComponent("viepnaikey-voice.m4a")

    func begin() async {
        errorText = ""
        let auth = await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
            AVAudioSession.sharedInstance().requestRecordPermission {
                continuation.resume(returning: $0)
            }
        }
        guard auth else { errorText = "Chưa cấp quyền microphone."; return }
        guard SFSpeechRecognizer.authorizationStatus() != .denied else {
            errorText = "Chưa cấp quyền nhận dạng giọng nói."; return
        }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .default, options: [])
            try session.setActive(true)
            recorder = try AVAudioRecorder(url: file, settings: [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 16000,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue
            ])
            recording = recorder?.record() ?? false
            if !recording { errorText = "Không thể bắt đầu thu âm." }
        } catch {
            errorText = error.localizedDescription
        }
    }

    func finish() async -> String? {
        recorder?.stop()
        recorder = nil
        recording = false
        defer {
            try? FileManager.default.removeItem(at: file)
            try? AVAudioSession.sharedInstance().setActive(false)
        }
        let allowed = await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
        guard allowed else { errorText = "Bạn chưa cấp quyền nhận dạng giọng nói."; return nil }
        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "vi-VN")),
              recognizer.isAvailable else {
            errorText = "Nhận dạng giọng nói không khả dụng."; return nil
        }
        let request = SFSpeechURLRecognitionRequest(url: file)
        request.shouldReportPartialResults = false
        return await withCheckedContinuation { (continuation: CheckedContinuation<String?, Never>) in
            var completed = false
            _ = recognizer.recognitionTask(with: request) { [weak self] result, error in
                if completed { return }
                if error != nil || result?.isFinal == true {
                    completed = true
                    let transcription = result?.bestTranscription.formattedString
                    if let error {
                        Task { @MainActor in self?.errorText = error.localizedDescription }
                    }
                    continuation.resume(returning: transcription)
                }
            }
        }
    }
}
