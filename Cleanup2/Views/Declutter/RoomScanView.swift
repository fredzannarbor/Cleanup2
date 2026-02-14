import SwiftUI
import AVFoundation

struct RoomScanView: View {
    let roomId: Int64
    @Binding var isPresented: Bool
    @StateObject private var scanService = VideoScanService()
    @State private var isRecording = false
    @State private var extractionDone = false
    @State private var showShareSheet = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if extractionDone {
                    // Show extracted frames info
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.green)

                    Text("Frames Extracted!")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("\(scanService.extractedFrameCount) frames ready for analysis")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    Button {
                        showShareSheet = true
                    } label: {
                        Label("Share Frames via AirDrop", systemImage: "square.and.arrow.up")
                            .font(.headline)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.indigo)

                    Text("AirDrop frames to your Mac, then run\n`/cleanup2 scan` from Claude Code")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Button("Done") {
                        isPresented = false
                    }
                    .buttonStyle(.bordered)
                } else if scanService.isProcessing {
                    ProgressView("Extracting frames...")
                        .padding()
                } else {
                    // Recording UI
                    Image(systemName: "video.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.indigo)

                    Text("Room Walkthrough")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("Record a slow walkthrough of the room. The video will be processed into frames for AI analysis.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    if isRecording {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(.red)
                                .frame(width: 12, height: 12)
                            Text("Recording... \(scanService.recordingDuration)s")
                                .font(.headline)
                        }

                        Button {
                            stopRecording()
                        } label: {
                            Label("Stop Recording", systemImage: "stop.circle.fill")
                                .font(.headline)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                    } else {
                        Button {
                            startRecording()
                        } label: {
                            Label("Start Recording", systemImage: "record.circle")
                                .font(.headline)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.indigo)
                    }
                }
            }
            .padding()
            .navigationTitle("Scan Room")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                let urls = scanService.frameURLs(roomId: roomId)
                ActivityViewController(activityItems: urls)
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func startRecording() {
        scanService.startRecording()
        isRecording = true
    }

    private func stopRecording() {
        isRecording = false
        scanService.stopRecording { success in
            if success {
                scanService.extractFrames(roomId: roomId) {
                    extractionDone = true
                }
            }
        }
    }
}

// MARK: - UIActivityViewController wrapper

struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
