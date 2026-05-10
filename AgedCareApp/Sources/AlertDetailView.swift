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
      }

      if let error = errorMessage {
        Section {
          Text(error).foregroundColor(.red)
        }
      }
    }
    .navigationTitle("Alert details")
  }

  private func acknowledge() async {
    do {
      try await container.alertsRepository.acknowledgeAlert(alertId: alert.id, staffId: staff.id)
      isAcknowledged = true
    } catch {
      errorMessage = error.localizedDescription
    }
  }

  private func closeAlert() async {
    do {
      try await container.alertsRepository.closeAlert(alertId: alert.id, notes: notes)
      isClosing = true
    } catch {
      errorMessage = error.localizedDescription
    }
  }
}
