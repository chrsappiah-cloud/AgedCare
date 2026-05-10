import SwiftUI

struct RootView: View {
  @EnvironmentObject var container: DependencyContainer
  @StateObject private var session = SessionViewModel()

  var body: some View {
    Group {
      switch session.state {
      case .onboarding:
        RoleSelectionView()
          .environmentObject(session)
      case .loading:
        ProgressView("Signing in\u{2026}")
      case .resident(let facilityId, let residentId):
        ResidentShellView(facilityId: facilityId, residentId: residentId)
          .environmentObject(container)
      case .staff(let staff):
        StaffShellView(staff: staff, session: session)
          .environmentObject(container)
      }
    }
  }
}

struct RoleSelectionView: View {
  @EnvironmentObject var session: SessionViewModel
  @State private var showLogin = false
  @State private var showResidentSetup = false

  var body: some View {
    NavigationStack {
      VStack(spacing: 40) {
        Spacer()
        Text("AgedCare")
          .font(.largeTitle.bold())
        Text("Set up your device")
          .font(.title3)
          .foregroundColor(.secondary)

        Button(action: { showResidentSetup = true }) {
          Label("Bedside device for a resident", systemImage: "bed.double")
            .font(.headline)
            .padding()
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
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
        .sheet(isPresented: $showLogin) {
          LoginView()
            .environmentObject(session)
        }

        Spacer()

        Text("Test accounts: admin@gvcare.com / nurse@gvcare.com / carer@gvcare.com\nPassword: password")
          .font(.caption)
          .foregroundColor(.secondary)
          .multilineTextAlignment(.center)
      }
      .padding(32)
    }
  }
}
