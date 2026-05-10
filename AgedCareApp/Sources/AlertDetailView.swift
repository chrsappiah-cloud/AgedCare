import SwiftUI
import AgedCareShared
import UserNotifications

struct AlertDetailView: View {
  let alert: AlertModel
  let staff: StaffUserModel
  @EnvironmentObject var container: DependencyContainer
  @State private var isAcknowledged = false
  @State private var isClosing = false
  @State private var notes: String = ""
  @State private var errorMessage: String?
  @State private var attachments: [MediaAttachment] = []
  @State private var showImagePicker = false
  @State private var showCamera = false
  @State private var showAudioRecorder = false
  @State private var pickedImage: UIImage?

  var body: some View {
    Form {
      Section("Alert") {
        HStack {
          Text("Type")
          Spacer()
          Text(alert.typeDisplay)
            .foregroundColor(.secondary)
        }
        HStack {
          Text("Priority")
          Spacer()
          Text("P\(alert.priority)")
            .foregroundColor(alert.priorityColor)
        }
        HStack {
          Text("Created")
          Spacer()
          Text(alert.createdAt.formatted(date: .abbreviated, time: .shortened))
            .foregroundColor(.secondary)
        }
        HStack {
          Text("Status")
          Spacer()
          Text(alert.status.capitalized)
            .foregroundColor(.secondary)
        }
      }

      if !attachments.isEmpty {
        Section("Attachments") {
          MediaAttachmentView(attachments: attachments)
        }
      }

      Section("Actions") {
        Button {
          Task { await acknowledge() }
        } label: {
          Label("Acknowledge", systemImage: "checkmark.circle")
        }
        .disabled(isAcknowledged || alert.status != "open")

        Button(role: .destructive) {
          Task { await closeAlert() }
        } label: {
          Label("Mark as resolved", systemImage: "xmark.circle")
        }
        .disabled(isClosing || alert.status == "closed")
      }

      Section("Notes") {
        TextEditor(text: $notes)
          .frame(minHeight: 100)

        HStack(spacing: 12) {
          Button(action: { showCamera = true }) {
            Label("Photo", systemImage: "camera")
          }
          .buttonStyle(.bordered)
          .disabled(isClosing || alert.status == "closed")

          Button(action: { showImagePicker = true }) {
            Label("Gallery", systemImage: "photo.on.rectangle")
          }
          .buttonStyle(.bordered)
          .disabled(isClosing || alert.status == "closed")

          Button(action: { showAudioRecorder = true }) {
            Label("Voice", systemImage: "mic")
          }
          .buttonStyle(.bordered)
          .disabled(isClosing || alert.status == "closed")
        }
        .labelStyle(.iconOnly)
      }

      if let error = errorMessage {
        Section {
          Text(error).foregroundColor(.red)
        }
      }
    }
    .navigationTitle("Alert details")
    .sheet(isPresented: $showImagePicker) {
      ImagePicker(sourceType: .photoLibrary, onPick: { image in
        saveImage(image)
      }, onCancel: {})
    }
    .sheet(isPresented: $showCamera) {
      ImagePicker(sourceType: .camera, onPick: { image in
        saveImage(image)
      }, onCancel: {})
    }
    .sheet(isPresented: $showAudioRecorder) {
      AudioRecorderView { url in
        saveAudio(url)
      }
    }
  }

  private func saveImage(_ image: UIImage) {
    guard let data = image.jpegData(compressionQuality: 0.7) else { return }
    let filename = "photo_\(UUID().uuidString.prefix(8)).jpg"
    let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(filename)
    try? data.write(to: url)
    let attachment = MediaAttachment(type: .photo, localURL: url)
    attachments.append(attachment)
  }

  private func saveAudio(_ url: URL) {
    let attachment = MediaAttachment(type: .audio, localURL: url)
    attachments.append(attachment)
  }

  private func acknowledge() async {
    SoundManager.shared.playAcknowledgement()
    do {
      try await container.alertsRepository.acknowledgeAlert(alertId: alert.id, staffId: staff.id)
      isAcknowledged = true
    } catch {
      errorMessage = error.localizedDescription
    }
  }

  private func closeAlert() async {
    SoundManager.shared.playAcknowledgement()
    do {
      try await container.alertsRepository.closeAlert(alertId: alert.id, notes: notes)
      isClosing = true
    } catch {
      errorMessage = error.localizedDescription
    }
  }
}
