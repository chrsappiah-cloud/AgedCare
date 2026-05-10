import SwiftUI

struct LoginView: View {
  @EnvironmentObject var session: SessionViewModel
  @State private var email = ""
  @State private var password = ""

  var body: some View {
    VStack(spacing: 24) {
      Spacer()

      Image(systemName: "person.fill.badge.shield.checkmark")
        .font(.system(size: 60))
        .foregroundStyle(.tint)
        .accessibilityHidden(true)

      Text("Staff Sign In")
        .font(.title.bold())
        .accessibilityAddTraits(.isHeader)

      TextField("Email", text: $email)
        .textContentType(.emailAddress)
        .autocapitalization(.none)
        .keyboardType(.emailAddress)
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .accessibilityLabel("Email address")
        .accessibilityHint("Enter your email address to sign in")

      SecureField("Password", text: $password)
        .textContentType(.password)
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .accessibilityLabel("Password")
        .accessibilityHint("Enter your password")

      if let error = session.loginError {
        Text(error)
          .foregroundColor(.red)
          .font(.callout)
          .accessibilityLabel("Login error: \(error)")
      }

      Button(action: {
        Task { await session.login(email: email, password: password) }
      }) {
        Text("Sign In")
          .font(.headline)
          .padding()
          .frame(maxWidth: .infinity)
      }
      .buttonStyle(.borderedProminent)
      .disabled(email.isEmpty || password.isEmpty)
      .accessibilityHint("Signs you in with your email and password")
      .accessibilityIdentifier("sign_in_button")

      Text("Demo Access")
        .font(.subheadline.bold())
        .foregroundColor(.secondary)
        .padding(.top, 8)
        .accessibilityAddTraits(.isHeader)

      VStack(spacing: 10) {
        DemoButton(title: "Admin — Dr. Sarah Chen", email: "admin@gvcare.com", password: "password", session: session)
        DemoButton(title: "Nurse — John Smith", email: "nurse@gvcare.com", password: "password", session: session)
        DemoButton(title: "Carer — Emma Davis", email: "carer@gvcare.com", password: "password", session: session)
      }
      .accessibilityLabel("Demo accounts")

      Button(action: { session.state = .onboarding }) {
        Text("Back")
          .font(.subheadline)
      }
      .accessibilityHint("Returns to the setup screen")

      Spacer()
    }
    .padding(32)
    .accessibilityElement(children: .contain)
  }
}

private struct DemoButton: View {
  let title: String
  let email: String
  let password: String
  let session: SessionViewModel

  var body: some View {
    Button(action: {
      Task { await session.login(email: email, password: password) }
    }) {
      HStack {
        Image(systemName: "person.circle.fill")
          .font(.caption)
          .accessibilityHidden(true)
        Text(title)
          .font(.caption)
        Spacer()
        Text("Tap")
          .font(.caption2.bold())
          .padding(.horizontal, 10)
          .padding(.vertical, 4)
          .background(Color.accentColor.opacity(0.2))
          .cornerRadius(6)
          .accessibilityHidden(true)
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 8)
      .background(Color(.systemGray6))
      .cornerRadius(8)
    }
    .buttonStyle(.plain)
    .accessibilityLabel("Sign in as \(title)")
    .accessibilityHint("Instantly signs in with a demo account")
    .accessibilityIdentifier("demo_\(title.prefix(5))")
  }
}
