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
        ZStack {
          AppTheme.background.ignoresSafeArea()
          VStack(spacing: 16) {
            ProgressView()
              .tint(AppTheme.emeraldGreen)
              .scaleEffect(1.3)
            Text("Signing in\u{2026}")
              .foregroundColor(AppTheme.textSecondary)
              .accessibilityLabel("Signing in")
          }
        }
      case .resident(let facilityId, let residentId):
        UnifiedShellView(
          mode: .resident(facilityId: facilityId, residentId: residentId),
          session: session
        )
        .environmentObject(container)
        .environmentObject(HandoffService.shared)
      case .staff(let staff):
        UnifiedShellView(
          mode: .staff(staff),
          session: session
        )
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

        VStack(spacing: 4) {
          Image(systemName: "heart.circle.fill")
            .font(.system(size: 50))
            .foregroundColor(AppTheme.emeraldRed)
            .accessibilityHidden(true)

          Text("AgedCare")
            .font(.largeTitle.bold())
            .foregroundColor(AppTheme.textPrimary)
            .accessibilityAddTraits(.isHeader)
            .accessibilityLabel("Aged Care")

          Text("Compassionate care, connected")
            .font(.subheadline)
            .foregroundColor(AppTheme.darkChocolateLight)
        }

        Text("Set up your device")
          .font(.title3)
          .foregroundColor(AppTheme.textSecondary)
          .accessibilityLabel("Set up your device to get started")

        Button(action: { showResidentSetup = true }) {
          Label("Bedside device for a resident", systemImage: "bed.double")
            .primaryButtonStyle()
        }
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
            .background(AppTheme.surface)
            .foregroundColor(AppTheme.textPrimary)
            .cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.emeraldGreen, lineWidth: 2))
        }
        .accessibilityHint("Opens the staff sign in screen")
        .accessibilityIdentifier("staff_login")
        .sheet(isPresented: $showLogin) {
          LoginView()
            .environmentObject(session)
        }

        Spacer()

        Text("Test accounts: admin@gvcare.com / nurse@gvcare.com / carer@gvcare.com\nPassword: password")
          .font(.caption)
          .foregroundColor(AppTheme.textSecondary)
          .multilineTextAlignment(.center)
          .accessibilityLabel("Test accounts available. Admin, nurse, and carer logins with password password")
      }
      .padding(32)
      .background(AppTheme.gradientDiamond.ignoresSafeArea())
      .accessibilityElement(children: .contain)
    }
  }
}
