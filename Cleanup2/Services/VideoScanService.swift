import Foundation
import AVFoundation
import UIKit

@MainActor
class VideoScanService: ObservableObject {
    @Published var isProcessing = false
    @Published var extractedFrameCount = 0
    @Published var recordingDuration = 0

    private var captureSession: AVCaptureSession?
    private var movieOutput: AVCaptureMovieFileOutput?
    private var recordingDelegate: RecordingDelegate?
    private var tempVideoURL: URL?
    private var timer: Timer?

    private var scansDirectory: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dir = docs.appendingPathComponent("Scans")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    func startRecording() {
        recordingDuration = 0
        let session = AVCaptureSession()
        session.sessionPreset = .medium

        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
              session.canAddInput(videoInput) else {
            print("VideoScanService: Cannot access camera")
            return
        }
        session.addInput(videoInput)

        let output = AVCaptureMovieFileOutput()
        guard session.canAddOutput(output) else { return }
        session.addOutput(output)

        captureSession = session
        movieOutput = output

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mov")
        tempVideoURL = tempURL

        let delegate = RecordingDelegate()
        recordingDelegate = delegate

        session.startRunning()
        output.startRecording(to: tempURL, recordingDelegate: delegate)

        // Timer for duration display
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.recordingDuration += 1
            }
        }
    }

    func stopRecording(completion: @escaping (Bool) -> Void) {
        timer?.invalidate()
        timer = nil

        guard let delegate = recordingDelegate else {
            completion(false)
            return
        }

        delegate.onFinished = { [weak self] success in
            Task { @MainActor in
                self?.captureSession?.stopRunning()
                self?.captureSession = nil
                completion(success)
            }
        }

        movieOutput?.stopRecording()
    }

    func frameURLs(roomId: Int64) -> [URL] {
        let roomDir = scansDirectory.appendingPathComponent("room_\(roomId)")
        guard let files = try? FileManager.default.contentsOfDirectory(at: roomDir, includingPropertiesForKeys: nil) else {
            return []
        }
        return files.filter { $0.pathExtension == "jpg" }.sorted { $0.lastPathComponent < $1.lastPathComponent }
    }

    func extractFrames(roomId: Int64, completion: @escaping () -> Void) {
        guard let videoURL = tempVideoURL else {
            completion()
            return
        }

        isProcessing = true
        extractedFrameCount = 0

        Task.detached { [scansDirectory] in
            let asset = AVURLAsset(url: videoURL)
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            generator.maximumSize = CGSize(width: 1280, height: 960)

            let duration = try? await asset.load(.duration)
            let totalSeconds = Int(CMTimeGetSeconds(duration ?? .zero))
            guard totalSeconds > 0 else {
                await MainActor.run {
                    self.isProcessing = false
                    completion()
                }
                return
            }

            // Clean previous scans for this room
            let roomDir = scansDirectory.appendingPathComponent("room_\(roomId)")
            try? FileManager.default.removeItem(at: roomDir)
            try? FileManager.default.createDirectory(at: roomDir, withIntermediateDirectories: true)

            var count = 0
            // Extract 1 frame per second
            for second in stride(from: 0, to: totalSeconds, by: 1) {
                let time = CMTime(seconds: Double(second), preferredTimescale: 600)
                do {
                    let (cgImage, _) = try await generator.image(at: time)
                    let uiImage = UIImage(cgImage: cgImage)
                    if let data = uiImage.jpegData(compressionQuality: 0.7) {
                        let filename = String(format: "frame_%04d.jpg", count)
                        let fileURL = roomDir.appendingPathComponent(filename)
                        try data.write(to: fileURL)
                        count += 1
                    }
                } catch {
                    // Skip frames that fail to extract
                    continue
                }
            }

            // Clean up temp video
            try? FileManager.default.removeItem(at: videoURL)

            await MainActor.run {
                self.extractedFrameCount = count
                self.isProcessing = false
                completion()
            }
        }
    }
}

// MARK: - Recording Delegate

private class RecordingDelegate: NSObject, AVCaptureFileOutputRecordingDelegate {
    var onFinished: ((Bool) -> Void)?

    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        onFinished?(error == nil)
    }
}
