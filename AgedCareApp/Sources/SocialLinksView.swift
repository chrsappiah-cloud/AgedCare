import SwiftUI

struct SocialLinksView: View {
    @Environment(\.openURL) private var openURL
    @State private var showShareSheet = false
    @State private var shareText = ""
    @State private var selectedCategory: String? = nil

    private var categories: [String] {
        Array(Set(WCSMarketingConfig.appProducts.map(\.category))).sorted()
    }

    private var filteredApps: [WCSAppProduct] {
        if let cat = selectedCategory {
            return WCSMarketingConfig.appProducts.filter { $0.category == cat }
        }
        return WCSMarketingConfig.appProducts
    }

    var body: some View {
        List {
            headerSection
            socialMediaSection
            categoryFilter
            appProductsSection
            paymentSection
            founderSection
            footerSection
        }
        .scrollContentBackground(.hidden)
        .background(AppTheme.gradientDiamond.ignoresSafeArea())
        .navigationTitle("Apps & Marketing")
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [shareText])
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        Section {
            VStack(spacing: 10) {
                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(AppTheme.emeraldRed)
                Text("WCS App Suite")
                    .font(.title2.bold())
                Text("12 apps • TestFlight • Subscriptions")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button {
                    openURL(WCSMarketingConfig.allAppsURL)
                } label: {
                    Text("wcs-full.vercel.app/apps")
                        .font(.caption)
                        .foregroundColor(AppTheme.emeraldGreen)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .listRowBackground(Color.clear)
        }
    }

    // MARK: - Social Media

    private var socialMediaSection: some View {
        Section("Follow & Share") {
            ForEach(WCSMarketingConfig.socialLinks, id: \.name) { link in
                Button {
                    openURL(link.url)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: link.icon)
                            .font(.title3)
                            .foregroundColor(AppTheme.emeraldGreen)
                            .frame(width: 28)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(link.name)
                                .foregroundColor(AppTheme.textPrimary)
                            Text(link.handle)
                                .font(.caption2)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
            }

            Button {
                shareText = """
                Check out WCS — 12 apps on TestFlight!

                \(WCSMarketingConfig.allAppsURL.absoluteString)

                Follow us:
                \(WCSMarketingConfig.socialLinks.map { "\($0.name): \($0.url.absoluteString)" }.joined(separator: "\n"))

                #WCS #TestFlight #iOS #Apps
                """
                showShareSheet = true
            } label: {
                Label("Share All Social Links", systemImage: "square.and.arrow.up")
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .foregroundColor(AppTheme.emeraldGreen)
            }
        }
    }

    // MARK: - Category Filter

    private var categoryFilter: some View {
        Section("Filter by Category") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    CategoryChip(name: "All", isSelected: selectedCategory == nil) {
                        selectedCategory = nil
                    }
                    ForEach(categories, id: \.self) { cat in
                        CategoryChip(name: cat, isSelected: selectedCategory == cat) {
                            selectedCategory = (selectedCategory == cat) ? nil : cat
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
        }
    }

    // MARK: - App Products

    private var appProductsSection: some View {
        Section("TestFlight Apps (\(filteredApps.count))") {
            ForEach(filteredApps) { app in
                AppProductRow(app: app, onShare: {
                    shareText = WCSMarketingConfig.appShareText(for: app)
                    showShareSheet = true
                })
            }
        }
    }

    // MARK: - Payment

    private var paymentSection: some View {
        Section("Payment & Subscriptions") {
            ForEach(WCSMarketingConfig.appProducts) { app in
                Button {
                    openURL(app.paymentLink)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: app.icon)
                            .foregroundColor(AppTheme.emeraldGreen)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(app.name)
                                .font(.subheadline)
                                .foregroundColor(AppTheme.textPrimary)
                            Text("\(app.tier) • \(app.price)")
                                .font(.caption2)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                        Spacer()
                        Text("Pay")
                            .font(.caption.bold())
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(AppTheme.emeraldGreen)
                            .foregroundColor(.white)
                            .cornerRadius(6)
                    }
                }
            }

            Button {
                openURL(WCSMarketingConfig.donateURL)
            } label: {
                HStack {
                    Image(systemName: "gift.fill")
                        .foregroundColor(AppTheme.emeraldRed)
                        .frame(width: 24)
                    Text("Donate / Support All Projects")
                        .foregroundColor(AppTheme.textPrimary)
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
        }
    }

    // MARK: - Founder

    private var founderSection: some View {
        Section("Founder & Creator") {
            HStack(spacing: 12) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.title)
                    .foregroundColor(AppTheme.emeraldGreen)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Dr Christopher Appiah-Thompson")
                        .font(.subheadline.bold())
                        .foregroundColor(AppTheme.textPrimary)
                    Text("CEO, World Class Scholars")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Button {
                openURL(WCSMarketingConfig.personalLinkURL)
            } label: {
                HStack {
                    Image(systemName: "link")
                        .foregroundColor(AppTheme.emeraldGreen)
                    Text("christopherappiahthompson.link")
                        .foregroundColor(AppTheme.textPrimary)
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Button {
                openURL(WCSMarketingConfig.gumroadURL)
            } label: {
                HStack {
                    Image(systemName: "bag.fill")
                        .foregroundColor(AppTheme.emeraldGreen)
                    Text("Gumroad — Art & Digital Works")
                        .foregroundColor(AppTheme.textPrimary)
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Button {
                openURL(WCSMarketingConfig.twineURL)
            } label: {
                HStack {
                    Image(systemName: "briefcase.fill")
                        .foregroundColor(AppTheme.emeraldGreen)
                    Text("Twine — Professional Portfolio")
                        .foregroundColor(AppTheme.textPrimary)
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Button {
                openURL(WCSMarketingConfig.myworldclassURL)
            } label: {
                HStack {
                    Image(systemName: "graduationcap.fill")
                        .foregroundColor(AppTheme.emeraldGreen)
                    Text("myworldclass.org")
                        .foregroundColor(AppTheme.textPrimary)
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - Footer

    private var footerSection: some View {
        Section {
            Button {
                openURL(WCSMarketingConfig.websiteURL)
            } label: {
                Label("wcs-full.vercel.app", systemImage: "globe")
                    .frame(maxWidth: .infinity)
                    .foregroundColor(AppTheme.emeraldGreen)
            }

            Button {
                if let url = URL(string: "mailto:\(WCSMarketingConfig.supportEmail)?subject=WCS%20App%20Suite%20Inquiry") {
                    openURL(url)
                }
            } label: {
                Label(WCSMarketingConfig.supportEmail, systemImage: "envelope.fill")
                    .font(.caption)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(AppTheme.emeraldGreen)
            }

            HStack(spacing: 16) {
                Button("Privacy") { openURL(WCSMarketingConfig.privacyPolicyURL) }
                Button("Terms") { openURL(WCSMarketingConfig.termsURL) }
                Button("Pricing") { openURL(WCSMarketingConfig.pricingPageURL) }
            }
            .font(.caption2)
            .foregroundColor(AppTheme.textSecondary)
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - App Product Row

private struct AppProductRow: View {
    let app: WCSAppProduct
    let onShare: () -> Void
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: app.icon)
                    .font(.title2)
                    .foregroundColor(AppTheme.emeraldGreen)
                    .frame(width: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text(app.name)
                        .font(.subheadline.bold())
                        .foregroundColor(AppTheme.textPrimary)
                    Text(app.category)
                        .font(.caption2)
                        .foregroundColor(AppTheme.emeraldGreen)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(app.price)
                        .font(.caption.bold())
                        .foregroundColor(AppTheme.emeraldGreen)
                    Text(app.platform)
                        .font(.caption2)
                        .foregroundColor(AppTheme.textSecondary)
                }
            }

            Text(app.tagline)
                .font(.caption)
                .foregroundColor(AppTheme.textSecondary)
                .lineLimit(2)

            HStack(spacing: 8) {
                MiniButton(label: "TestFlight", icon: "airplane") {
                    openURL(app.testFlightLink)
                }
                MiniButton(label: "Pay", icon: "creditcard") {
                    openURL(app.paymentLink)
                }
                MiniButton(label: "Details", icon: "info.circle") {
                    openURL(app.websitePage)
                }
                MiniButton(label: "Feedback", icon: "bubble.left") {
                    openURL(app.feedbackLink)
                }

                Spacer()

                Button(action: onShare) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.caption)
                        .foregroundColor(AppTheme.emeraldGreen)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

private struct MiniButton: View {
    let label: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                Text(label)
            }
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(AppTheme.emeraldGreen.opacity(0.12))
            .foregroundColor(AppTheme.emeraldGreen)
            .cornerRadius(4)
        }
    }
}

private struct CategoryChip: View {
    let name: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(name)
                .font(.caption.bold())
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? AppTheme.emeraldGreen : AppTheme.emeraldGreen.opacity(0.12))
                .foregroundColor(isSelected ? .white : AppTheme.emeraldGreen)
                .cornerRadius(16)
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
