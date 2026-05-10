import SwiftUI

struct SettingsView: View {
  let staff: StaffUserModel
  let session: SessionViewModel
  @EnvironmentObject var container: DependencyContainer

  @State private var showCamera = false
  @State private var showPhotoLibrary = false
  @State private var profileImage: UIImage?

  var body: some View {
    NavigationStack {
      List {
        Section("Account") {
          HStack(spacing: 12) {
            ZStack {
              if let img = profileImage {
                Image(uiImage: img)
                  .resizable()
                  .scaledToFill()
                  .frame(width: 60, height: 60)
                  .clipShape(Circle())
              } else {
                ProfileImageView(name: staff.displayName ?? staff.role, imageURL: nil, size: .medium)
              }
            }
            .onTapGesture { showCamera = true }

            VStack(alignment: .leading, spacing: 2) {
              Text(staff.displayName ?? staff.role.capitalized)
                .font(.headline)
              Text(staff.role.capitalized)
                .font(.caption)
                .foregroundColor(.secondary)
            }
          }

          if let email = staff.email {
            LabeledContent("Email", value: email)
          }
          LabeledContent("Facility ID", value: staff.facilityId.uuidString.prefix(8).description)
        }

        Section("Developer") {
          NavigationLink(destination: WatchPreviewView()) {
            Label("Watch Preview", systemImage: "applewatch")
          }
        }

        Section {
          NavigationLink(destination: Text("Report a problem – contact support\nsupport@agedcare.app")
            .multilineTextAlignment(.center)
            .padding()) {
            Label("Report a problem", systemImage: "exclamationmark.bubble")
          }
          NavigationLink(destination: Text("Legal & Privacy\n\nAgedCare App v1.0\n© 2026 AgedCare Inc.")
            .multilineTextAlignment(.center)
            .padding()) {
            Label("Legal & privacy", systemImage: "shield")
          }
          Button("Sign out", systemImage: "arrow.backward.circle", role: .destructive) {
            session.logout()
          }
        }
      }
      .navigationTitle("Settings")
      .confirmationDialog("Change profile photo", isPresented: $showCamera) {
        Button("Camera") { showCamera = true }
        Button("Photo Library") { showPhotoLibrary = true }
        Button("Cancel", role: .cancel) {}
      }
      .sheet(isPresented: $showPhotoLibrary) {
        ImagePicker(sourceType: .photoLibrary, onPick: { image in
          profileImage = image
        }, onCancel: {})
      }
      .sheet(isPresented: $showCamera) {
        ImagePicker(sourceType: .camera, onPick: { image in
          profileImage = image
        }, onCancel: {})
      }
    }
  }
}
