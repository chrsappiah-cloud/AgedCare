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

      Text("Staff Sign In")
        .font(.title.bold())

      TextField("Email", text: $email)
        .textContentType(.emailAddress)
        .autocapitalization(.none)
        .keyboardType(.emailAddress)
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(10)

      SecureField("Password", text: $password)
        .textContentType(.password)
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(10)

      if let error = session.loginError {
        Text(error)
          .foregroundColor(.red)
          .font(.callout)
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

      Text("Demo Access")
        .font(.subheadline.bold())
        .foregroundColor(.secondary)
        .padding(.top, 8)

      VStack(spacing: 10) {
        DemoButton(title: "Admin — Dr. Sarah Chen", email: "admin@gvcare.com", password: "password", session: session)
        DemoButton(title: "Nurse — John Smith", email: "nurse@gvcare.com", password: "password", session: session)
        DemoButton(title: "Carer — Emma Davis", email: "carer@gvcare.com", password: "password", session: session)
      }

      Button(action: { session.state = .onboarding }) {
        Text("Back")
          .font(.subheadline)
      }

      Spacer()
    }
    .padding(32)
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
        Text(title)
          .font(.caption)
        Spacer()
        Text("Tap")
          .font(.caption2.bold())
          .padding(.horizontal, 10)
          .padding(.vertical, 4)
          .background(Color.accentColor.opacity(0.2))
          .cornerRadius(6)
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 8)
      .background(Color(.systemGray6))
      .cornerRadius(8)
    }
    .buttonStyle(.plain)
  }
}
