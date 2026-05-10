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
          Button("Report a problem", systemImage: "exclamationmark.bubble") {
            reportProblem()
          }
          Button("Legal & privacy", systemImage: "shield") {}
          Button("Sign out", systemImage: "arrow.backward.circle", role: .destructive) {
            session.logout()
          }
        }
      }
      .navigationTitle("Settings")
    }
  }

  private func reportProblem() {
    Task {
      try? await container.alertsRepository.createFallAlert(
        facilityId: staff.facilityId,
        residentId: UUID(),
        priority: 1
      )
    }
  }
}
