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
        Section {
          HStack(spacing: 14) {
            ZStack {
              if let img = profileImage {
                Image(uiImage: img)
                  .resizable()
                  .scaledToFill()
                  .frame(width: 60, height: 60)
                  .clipShape(Circle())
                  .overlay(Circle().stroke(AppTheme.emeraldGreen, lineWidth: 2))
              } else {
                ProfileImageView(name: staff.displayName ?? staff.role, imageURL: nil, size: .medium)
                  .overlay(Circle().stroke(AppTheme.emeraldGreen, lineWidth: 2))
              }
            }
            .onTapGesture { showCamera = true }
            .accessibilityLabel("Profile photo")
            .accessibilityHint("Tap to change your profile photo")

            VStack(alignment: .leading, spacing: 2) {
              Text(staff.displayName ?? staff.role.capitalized)
                .font(.headline)
                .foregroundColor(AppTheme.textPrimary)
              Text(staff.role.capitalized)
                .font(.caption)
                .foregroundColor(AppTheme.textSecondary)
            }
          }

          if let email = staff.email {
            LabeledContent("Email", value: email)
              .foregroundColor(AppTheme.textPrimary)
          }
          LabeledContent("Facility ID", value: staff.facilityId.uuidString.prefix(8).description)
            .foregroundColor(AppTheme.textPrimary)
        } header: {
          Text("Account").sectionHeaderStyle()
        }
        .listRowBackground(AppTheme.surface)

        Section {
          NavigationLink(destination: UpcomingPlansView()) {
            Label("Plans & Pricing", systemImage: "creditcard.fill")
              .foregroundColor(AppTheme.emeraldGreen)
          }
          .accessibilityLabel("Plans and pricing")
          .accessibilityHint("View subscription plans, waitlist, and pilot request options")

          NavigationLink(destination: SocialLinksView()) {
            Label("Share & Follow Us", systemImage: "square.and.arrow.up")
              .foregroundColor(AppTheme.emeraldGreen)
          }
          .accessibilityLabel("Share and social media links")
        } header: {
          Text("Subscriptions & Marketing").sectionHeaderStyle()
        }
        .listRowBackground(AppTheme.surface)

        Section {
          NavigationLink(destination: WatchPreviewView()) {
            Label("Watch Preview", systemImage: "applewatch")
              .foregroundColor(AppTheme.emeraldGreen)
          }
          .accessibilityLabel("Apple Watch Preview")
          .accessibilityHint("Opens a simulated Apple Watch interface to test watch features")
        } header: {
          Text("Developer").sectionHeaderStyle()
        }
        .listRowBackground(AppTheme.surface)

        Section {
          NavigationLink(destination: VStack(spacing: 16) {
            Image(systemName: "exclamationmark.bubble.fill")
              .font(.system(size: 40))
              .foregroundColor(AppTheme.emeraldRed)
            Text("Report a problem")
              .font(.title2.bold())
              .foregroundColor(AppTheme.textPrimary)
            Text("Contact support at support@agedcare.app or call 1-800-AGEDCARE")
              .multilineTextAlignment(.center)
              .foregroundColor(AppTheme.textSecondary)
          }
          .padding()
          .background(AppTheme.background)) {
            Label("Report a problem", systemImage: "exclamationmark.bubble")
              .foregroundColor(AppTheme.textPrimary)
          }
          .accessibilityLabel("Report a problem")

          NavigationLink(destination: VStack(spacing: 16) {
            Image(systemName: "shield.fill")
              .font(.system(size: 40))
              .foregroundColor(AppTheme.emeraldGreen)
            Text("Legal & Privacy")
              .font(.title2.bold())
              .foregroundColor(AppTheme.textPrimary)
            Text("AgedCare App v1.0\n© 2026 AgedCare Inc.\n\nYour data is encrypted and stored securely. HealthKit data never leaves your device without your consent.")
              .multilineTextAlignment(.center)
              .foregroundColor(AppTheme.textSecondary)
          }
          .padding()
          .background(AppTheme.background)) {
            Label("Legal & privacy", systemImage: "shield")
              .foregroundColor(AppTheme.textPrimary)
          }
          .accessibilityLabel("Legal and privacy information")

          Button(action: { session.logout() }) {
            Label("Sign out", systemImage: "arrow.backward.circle")
              .foregroundColor(AppTheme.danger)
          }
          .accessibilityHint("Signs out and returns to the setup screen")
        } header: {
          Text("Support").sectionHeaderStyle()
        }
        .listRowBackground(AppTheme.surface)
      }
      .scrollContentBackground(.hidden)
      .background(AppTheme.gradientDiamond.ignoresSafeArea())
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
