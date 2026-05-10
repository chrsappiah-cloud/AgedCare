import SwiftUI

struct RootView: View {
  @EnvironmentObject var container: DependencyContainer
  @StateObject private var session = SessionViewModel()
  @StateObject private var accessibilityManager = AccessibilityManager.shared

  var body: some View {
    Group {
      switch session.state {
      case .onboarding:
        RoleSelectionView()
          .environmentObject(session)
          .environmentObject(accessibilityManager)
      case .loading:
        ProgressView("Signing in\u{2026}")
          .accessibilityLabel("Signing in")
      case .resident(let facilityId, let residentId):
        ResidentShellView(facilityId: facilityId, residentId: residentId)
          .environmentObject(container)
          .environmentObject(HandoffService.shared)
      case .staff(let staff):
        StaffShellView(staff: staff, session: session)
          .environmentObject(container)
          .environmentObject(HandoffService.shared)
      }
    }
    .dynamicTypeSize(...DynamicTypeSize.accessibility5)
  }
}

struct RoleSelectionView: View {
  @EnvironmentObject var session: SessionViewModel
  @EnvironmentObject var accessibilityManager: AccessibilityManager
  @State private var showLogin = false
  @State private var showResidentSetup = false

  var body: some View {
    NavigationStack {
      VStack(spacing: 40) {
        Spacer()
        Text("AgedCare")
          .font(.largeTitle.bold())
          .accessibilityAddTraits(.isHeader)
          .accessibilityLabel("Aged Care")

        Text("Set up your device")
          .font(.title3)
          .foregroundColor(.secondary)
          .accessibilityLabel("Set up your device to get started")

        Button(action: { showResidentSetup = true }) {
          Label("Bedside device for a resident", systemImage: "bed.double")
            .font(.headline)
            .padding()
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .accessibilityHint("Sets up this device for a resident room")
        .accessibilityIdentifier("setup_resident")
        .sheet(isPresented: $showResidentSetup) {
          ResidentSetupView()
            .environmentObject(session)
        }

        Button(action: { showLogin = true }) {
          Label("Sign in as staff member", systemImage: "person.fill")
            .font(.headline)
            .padding()
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .accessibilityHint("Opens the staff sign in screen")
        .accessibilityIdentifier("staff_login")
        .sheet(isPresented: $showLogin) {
          LoginView()
            .environmentObject(session)
        }

        Spacer()

        Text("Test accounts: admin@gvcare.com / nurse@gvcare.com / carer@gvcare.com\nPassword: password")
          .font(.caption)
          .foregroundColor(.secondary)
          .multilineTextAlignment(.center)
          .accessibilityLabel("Test accounts available. Admin, nurse, and carer logins with password password")
      }
      .padding(32)
      .accessibilityElement(children: .contain)
    }
  }
}
