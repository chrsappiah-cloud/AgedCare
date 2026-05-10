import SwiftUI
import AgedCareShared

struct AlertsHomeView: View {
  let staff: StaffUserModel
  @EnvironmentObject var container: DependencyContainer
  @StateObject private var vm: AlertViewModel

  init(staff: StaffUserModel) {
    self.staff = staff
    _vm = StateObject(wrappedValue: AlertViewModel(
      facilityId: staff.facilityId,
      staffId: staff.id
    ))
  }

  var body: some View {
    NavigationStack {
      VStack(spacing: 8) {
        filterStrip
        alertList
      }
      .navigationTitle("Open Alerts")
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button { Task { await vm.loadAlerts() } } label: {
            Image(systemName: "arrow.clockwise")
              .foregroundColor(AppTheme.emeraldGreen)
          }
          .accessibilityLabel("Refresh alerts")
          .accessibilityHint("Reloads the alert list")
        }
      }
      .onAppear {
        vm.alertsRepository = container.alertsRepository
      }
      .task {
        await vm.loadAlerts()
      }
      .background(AppTheme.background)
      .accessibilityElement(children: .contain)
    }
  }

  private var filterStrip: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 8) {
        filterChip("All", selected: vm.filter == .all) { vm.filter = .all }
        filterChip("My alerts", selected: vm.filter == .assignedToMe) { vm.filter = .assignedToMe }
        filterChip("Falls", selected: vm.filter == .falls) { vm.filter = .falls }
        filterChip("Vitals", selected: vm.filter == .vitals) { vm.filter = .vitals }
      }
      .padding(.horizontal)
    }
    .accessibilityLabel("Alert filters")
    .accessibilityHint("Filter which alerts are shown")
  }

  private func filterChip(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      Text(title)
        .font(.caption.bold())
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(selected ? AppTheme.emeraldGreen : AppTheme.diamondSilver.opacity(0.4))
        .foregroundColor(selected ? AppTheme.textOnPrimary : AppTheme.textSecondary)
        .cornerRadius(20)
        .overlay(
          RoundedRectangle(cornerRadius: 20)
            .stroke(selected ? AppTheme.emeraldGreen : Color.clear, lineWidth: 1)
        )
    }
    .accessibilityLabel("\(title) filter")
    .accessibilityValue(selected ? "Selected" : "Not selected")
    .accessibilityHint("Shows \(title.lowercased()) alerts")
  }

  private var alertList: some View {
    List(vm.filteredAlerts) { alert in
      NavigationLink {
        AlertDetailView(alert: alert, staff: staff)
      } label: {
        RichAlertRow(alert: alert)
      }
    }
    .scrollContentBackground(.hidden)
    .overlay {
      if vm.isLoading {
        ProgressView("Loading\u{2026}")
          .tint(AppTheme.emeraldGreen)
          .accessibilityLabel("Loading alerts")
      } else if let error = vm.loadError {
        VStack(spacing: 8) {
          Image(systemName: "exclamationmark.triangle.fill")
            .font(.title2)
            .foregroundColor(AppTheme.danger)
          Text(error)
            .foregroundColor(AppTheme.danger)
            .padding()
        }
        .accessibilityLabel("Error loading alerts: \(error)")
      } else if vm.filteredAlerts.isEmpty {
        VStack(spacing: 8) {
          Image(systemName: "checkmark.circle.fill")
            .font(.title2)
            .foregroundColor(AppTheme.emeraldGreen)
          Text("No alerts")
            .foregroundColor(AppTheme.textSecondary)
        }
        .accessibilityLabel("No alerts to show")
      }
    }
    .accessibilityLabel("Alert list")
  }
}

struct RichAlertRow: View {
  let alert: AlertModel

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      priorityIndicator
      VStack(alignment: .leading, spacing: 4) {
        HStack {
          Text("Resident \(alert.residentId.uuidString.prefix(6))")
            .font(.headline)
            .foregroundColor(AppTheme.textPrimary)
          Spacer()
          Text(alert.createdAt, style: .time)
            .font(.caption)
            .foregroundColor(AppTheme.textSecondary)
        }
        Text(alert.typeDisplay)
          .font(.subheadline)
          .foregroundColor(AppTheme.textSecondary)
      }
    }
    .padding(.vertical, 6)
    .accessibilityElement(children: .combine)
    .accessibilityLabel("\(alert.typeDisplay) alert, priority \(alert.priority), resident identifier \(alert.residentId.uuidString.prefix(8))")
    .accessibilityValue("Status: \(alert.status), created at \(alert.createdAt.formatted(date: .omitted, time: .shortened))")
    .accessibilityHint("Opens alert details")
  }

  private var priorityIndicator: some View {
    RoundedRectangle(cornerRadius: 4)
      .fill(priorityColor)
      .frame(width: 6)
      .accessibilityHidden(true)
  }

  private var priorityColor: Color {
    switch alert.priority {
    case 3: return AppTheme.emeraldRed
    case 2: return AppTheme.warning
    default: return AppTheme.emeraldGreen
    }
  }
}

extension AlertModel {
  var typeDisplay: String {
    switch type.lowercased() {
    case "fall": return "Possible fall"
    case "vitaltrend": return "Vital sign trend"
    case "handoff_request": return "Staff assistance"
    default: return type.capitalized
    }
  }

  var priorityColor: Color {
    switch priority {
    case 3: return Color.red
    case 2: return Color.orange
    default: return Color.yellow
    }
  }
}
