import SwiftUI

struct SettingsView: View {
  let staff: StaffUserModel
  let session: SessionViewModel
  @EnvironmentObject var container: DependencyContainer

  var body: some View {
    NavigationStack {
      List {
        Section("Account") {
          if let email = staff.email {
            LabeledContent("Email", value: email)
          }
          LabeledContent("Name", value: staff.displayName ?? "\u{2014}")
          LabeledContent("Role", value: staff.role.capitalized)
          LabeledContent("Facility ID", value: staff.facilityId.uuidString.prefix(8).description)
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
    }
  }

}
