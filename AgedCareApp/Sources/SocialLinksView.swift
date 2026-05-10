import SwiftUI

struct SocialLinksView: View {
    @Environment(\.openURL) private var openURL
    @State private var showShareSheet = false

    var body: some View {
        List {
            Section {
                VStack(spacing: 12) {
                    Image(systemName: "heart.circle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(AppTheme.emeraldRed)
                    Text("WCS Care")
                        .font(.title2.bold())
                    Text("Compassionate care, connected")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .listRowBackground(Color.clear)
            }

            Section("Social Media") {
                ForEach(WCSMarketingConfig.socialLinks, id: \.name) { link in
                    Button {
                        openURL(link.url)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: link.icon)
                                .font(.title3)
                                .foregroundColor(AppTheme.emeraldGreen)
                                .frame(width: 28)
                            Text(link.name)
                                .foregroundColor(AppTheme.textPrimary)
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }
                }
            }

            Section("Payment Links") {
                ForEach(WCSMarketingConfig.paymentLinks, id: \.name) { link in
                    Button {
                        openURL(link.url)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "creditcard.fill")
                                .foregroundColor(AppTheme.emeraldGreen)
                                .frame(width: 28)
                            Text(link.name)
                                .foregroundColor(AppTheme.textPrimary)
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }
                }
            }

            Section("TestFlight Apps") {
                ForEach(WCSMarketingConfig.testFlightApps, id: \.bundleId) { app in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(app.name)
                                .font(.subheadline.bold())
                                .foregroundColor(AppTheme.textPrimary)
                            Text(app.bundleId)
                                .font(.caption2)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                        Spacer()
                        Text("ID: \(app.appId)")
                            .font(.caption2)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
            }

            Section {
                Button {
                    showShareSheet = true
                } label: {
                    Label("Share WCS Care", systemImage: "square.and.arrow.up")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(AppTheme.emeraldGreen)
                }

                Button {
                    openURL(WCSMarketingConfig.websiteURL)
                } label: {
                    Label("Visit wcs-full.vercel.app", systemImage: "globe")
                        .frame(maxWidth: .infinity)
                        .foregroundColor(AppTheme.emeraldGreen)
                }

                Button {
                    if let url = URL(string: "mailto:\(WCSMarketingConfig.supportEmail)?subject=WCS%20Care%20Inquiry") {
                        openURL(url)
                    }
                } label: {
                    Label(WCSMarketingConfig.supportEmail, systemImage: "envelope.fill")
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(AppTheme.emeraldGreen)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppTheme.gradientDiamond.ignoresSafeArea())
        .navigationTitle("Share & Follow")
        .sheet(isPresented: $showShareSheet) {
            let shareText = """
            Check out WCS Care — compassionate aged care, connected.

            \(WCSMarketingConfig.websiteURL.absoluteString)

            Join our TestFlight beta: \(WCSMarketingConfig.testFlightURL.absoluteString)

            #WCSCare #AgedCare #Dementia #CaregiverSupport
            """
            ShareSheet(items: [shareText])
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
