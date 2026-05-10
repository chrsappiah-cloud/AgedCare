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
          }
        }
      }
      .onAppear {
        vm.alertsRepository = container.alertsRepository
      }
      .task {
        await vm.loadAlerts()
      }
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
  }

  private func filterChip(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      Text(title)
        .font(.caption)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(selected ? Color.accentColor : Color(.secondarySystemBackground))
        .foregroundColor(selected ? .white : .primary)
        .cornerRadius(999)
    }
  }

  private var alertList: some View {
    List(vm.filteredAlerts) { alert in
      NavigationLink {
        AlertDetailView(alert: alert, staff: staff)
      } label: {
        RichAlertRow(alert: alert)
      }
    }
    .overlay {
      if vm.isLoading { ProgressView("Loading\u{2026}") }
      else if let error = vm.loadError { Text(error).foregroundColor(.red).padding() }
      else if vm.filteredAlerts.isEmpty { Text("No alerts").foregroundColor(.secondary) }
    }
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
          Spacer()
          Text(alert.createdAt, style: .time)
            .font(.caption)
            .foregroundColor(.secondary)
        }
        Text(alert.typeDisplay)
          .font(.subheadline)
      }
    }
    .padding(.vertical, 6)
  }

  private var priorityIndicator: some View {
    RoundedRectangle(cornerRadius: 4)
      .fill(alert.priorityColor)
      .frame(width: 6)
  }
}

extension AlertModel {
  var typeDisplay: String {
    switch type.lowercased() {
    case "fall": return "Possible fall"
    case "vitaltrend": return "Vital sign trend"
    default: return type.capitalized
    }
  }

  var priorityColor: Color {
    switch priority {
    case 3: return .red
    case 2: return .orange
    default: return .yellow
    }
  }
}

