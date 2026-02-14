import SwiftUI
import PhotosUI

struct AddItemView: View {
    let roomId: Int64
    @Binding var isPresented: Bool
    @EnvironmentObject var declutterManager: DeclutterManager
    @EnvironmentObject var roomManager: RoomManager

    @State private var name = ""
    @State private var category: ItemCategory = .uncategorized
    @State private var isFurniture = false
    @State private var notes = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var capturedImage: UIImage?
    @State private var showCamera = false
    @StateObject private var speechService = SpeechService()
    @State private var isRecording = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Item Details") {
                    HStack {
                        TextField("Item name", text: $name)
                        Button {
                            toggleVoice()
                        } label: {
                            Image(systemName: isRecording ? "mic.fill" : "mic")
                                .foregroundStyle(isRecording ? .red : .secondary)
                        }
                    }

                    if isRecording {
                        Text(speechService.transcript)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Picker("Category", selection: $category) {
                        ForEach(ItemCategory.allCases) { cat in
                            Label(cat.label, systemImage: cat.icon)
                                .tag(cat)
                        }
                    }

                    Toggle(isOn: $isFurniture) {
                        Label("Furniture", systemImage: "chair.lounge.fill")
                    }

                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3)
                }

                Section("Photo") {
                    if let image = capturedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        Button("Remove Photo", role: .destructive) {
                            capturedImage = nil
                        }
                    } else {
                        Button {
                            showCamera = true
                        } label: {
                            Label("Take Photo", systemImage: "camera")
                        }

                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            Label("Choose from Library", systemImage: "photo")
                        }
                    }
                }
            }
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addItem()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onChange(of: selectedPhoto) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        capturedImage = image
                    }
                }
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraView(image: $capturedImage)
            }
        }
        .presentationDetents([.large])
    }

    private func toggleVoice() {
        if isRecording {
            speechService.stopTranscribing()
            isRecording = false
            if name.isEmpty {
                name = speechService.transcript
            } else {
                name += ", " + speechService.transcript
            }
            speechService.transcript = ""
        } else {
            speechService.startTranscribing()
            isRecording = true
        }
    }

    private func addItem() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        var photoPath: String?
        if let image = capturedImage {
            photoPath = PhotoStorageService.shared.savePhoto(image)
        }

        let trimmedNotes = notes.trimmingCharacters(in: .whitespaces)

        declutterManager.addItem(
            roomId: roomId,
            name: trimmedName,
            category: category,
            isFurniture: isFurniture,
            photoPath: photoPath,
            notes: trimmedNotes.isEmpty ? nil : trimmedNotes
        )
        roomManager.loadRooms()
        isPresented = false
    }
}

// MARK: - Camera View (UIImagePickerController wrapper)

struct CameraView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView

        init(_ parent: CameraView) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            parent.image = info[.originalImage] as? UIImage
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
