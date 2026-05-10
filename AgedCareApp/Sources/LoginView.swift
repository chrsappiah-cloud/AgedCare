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

      Button(action: { session.state = .onboarding }) {
        Text("Back")
          .font(.subheadline)
      }

      Spacer()
    }
    .padding(32)
  }
}
