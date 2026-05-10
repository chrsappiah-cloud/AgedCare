import SwiftUI

struct UpcomingPlansView: View {
    @StateObject private var subscriptions = SubscriptionService.shared
    @StateObject private var analytics = BetaAnalytics.shared
    @State private var selectedTier: SubscriptionTier?
    @State private var showWaitlist = false
    @State private var showPilotForm = false
    @State private var waitlistEmail = ""
    @State private var showConfirmation = false
    @State private var showFeedback = false
    @Environment(\.openURL) private var openURL

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                currentPhaseBanner
                tierCards
                demandSignalSection
                socialSection
                paymentLinksSection
                founderSection
                footerSection
            }
            .padding()
        }
        .background(AppTheme.gradientDiamond.ignoresSafeArea())
        .navigationTitle("Plans & Pricing")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showWaitlist) { waitlistSheet }
        .sheet(isPresented: $showPilotForm) { pilotFormSheet }
        .sheet(isPresented: $showFeedback) {
            NavigationStack { BetaFeedbackView() }
        }
        .alert("You're on the list!", isPresented: $showConfirmation) {
            Button("OK") {}
        } message: {
            Text("We'll notify you when the plan launches. Thank you for your interest!")
        }
        .task {
            await subscriptions.loadProducts()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "heart.circle.fill")
                .font(.system(size: 44))
                .foregroundStyle(AppTheme.emeraldRed)

            Text("WCS Care Plans")
                .font(.title.bold())
                .foregroundColor(AppTheme.textPrimary)

            Text("Choose the plan that fits your care needs.\nStart free, upgrade when you're ready.")
                .font(.subheadline)
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)

            Text("Simple pricing. Clear value. No pressure.")
                .font(.caption)
                .foregroundColor(AppTheme.emeraldGreen)
        }
        .padding(.bottom, 8)
    }

    // MARK: - Current Phase Banner

    private var currentPhaseBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "airplane")
                .font(.title3)
                .foregroundColor(.white)

            VStack(alignment: .leading, spacing: 2) {
                Text("TestFlight Beta")
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                Text("We're learning from your feedback. All features are free during beta.")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.85))
            }

            Spacer()
        }
        .padding()
        .background(
            LinearGradient(
                colors: [AppTheme.emeraldGreen, AppTheme.emeraldGreen.opacity(0.8)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(14)
    }

    // MARK: - Tier Cards

    private var tierCards: some View {
        VStack(spacing: 16) {
            ForEach(SubscriptionTier.allCases) { tier in
                TierCard(
                    tier: tier,
                    isCurrentPlan: subscriptions.currentTier == tier,
                    tapCount: analytics.planInterestCounts[tier.rawValue] ?? 0,
                    onSelect: { handleTierSelect(tier) }
                )
            }
        }
    }

    // MARK: - Demand Signal Section

    private var demandSignalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Help Us Build What You Need")
                .font(.headline)
                .foregroundColor(AppTheme.textPrimary)

            Text("Tap a plan above to signal your interest. We track demand to decide which features to prioritize.")
                .font(.caption)
                .foregroundColor(.secondary)

            Button {
                showFeedback = true
            } label: {
                HStack {
                    Image(systemName: "bubble.left.and.text.bubble.right.fill")
                        .foregroundColor(AppTheme.emeraldGreen)
                    Text("Share Beta Feedback")
                        .font(.subheadline.bold())
                        .foregroundColor(AppTheme.emeraldGreen)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(12)
                .background(AppTheme.emeraldGreen.opacity(0.1))
                .cornerRadius(10)
            }

            NavigationLink {
                GrowthRoadmapView()
            } label: {
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundColor(AppTheme.emeraldGreen)
                    Text("View 12-Month Growth Roadmap")
                        .font(.subheadline.bold())
                        .foregroundColor(AppTheme.emeraldGreen)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(12)
                .background(AppTheme.emeraldGreen.opacity(0.1))
                .cornerRadius(10)
            }
        }
        .padding()
        .background(AppTheme.surface)
        .cornerRadius(16)
    }

    // MARK: - Social Media

    private var socialSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Follow Us")
                .font(.headline)
                .foregroundColor(AppTheme.textPrimary)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                ForEach(WCSMarketingConfig.socialLinks, id: \.name) { link in
                    Button {
                        openURL(link.url)
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: link.icon)
                                .font(.title3)
                                .frame(width: 38, height: 38)
                                .background(AppTheme.emeraldGreen.opacity(0.15))
                                .foregroundColor(AppTheme.emeraldGreen)
                                .clipShape(Circle())
                            Text(link.handle)
                                .font(.system(size: 8))
                                .foregroundColor(AppTheme.textSecondary)
                                .lineLimit(1)
                        }
                    }
                }
            }
        }
        .padding()
        .background(AppTheme.surface)
        .cornerRadius(16)
    }

    // MARK: - Payment Links

    private var paymentLinksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Payment & Testing")
                .font(.headline)
                .foregroundColor(AppTheme.textPrimary)

            ForEach(WCSMarketingConfig.paymentLinks, id: \.name) { link in
                Button {
                    openURL(link.url)
                } label: {
                    HStack {
                        Image(systemName: "creditcard.fill")
                            .foregroundColor(AppTheme.emeraldGreen)
                        Text(link.name)
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textPrimary)
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
            }

            Button {
                openURL(WCSMarketingConfig.testFlightURL)
            } label: {
                HStack {
                    Image(systemName: "airplane")
                        .foregroundColor(.blue)
                    Text("Invite Testers via TestFlight")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textPrimary)
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
        }
        .padding()
        .background(AppTheme.surface)
        .cornerRadius(16)
    }

    // MARK: - Founder Section

    private var founderSection: some View {
        VStack(spacing: 10) {
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
                Spacer()
            }

            HStack(spacing: 12) {
                Button {
                    openURL(WCSMarketingConfig.personalLinkURL)
                } label: {
                    Text("christopherappiahthompson.link")
                        .font(.caption)
                        .foregroundColor(AppTheme.emeraldGreen)
                }
                Button {
                    openURL(WCSMarketingConfig.gumroadURL)
                } label: {
                    Text("Gumroad")
                        .font(.caption)
                        .foregroundColor(AppTheme.emeraldGreen)
                }
                Button {
                    openURL(WCSMarketingConfig.twineURL)
                } label: {
                    Text("Twine")
                        .font(.caption)
                        .foregroundColor(AppTheme.emeraldGreen)
                }
            }
        }
        .padding()
        .background(AppTheme.surface)
        .cornerRadius(16)
    }

    // MARK: - Footer

    private var footerSection: some View {
        VStack(spacing: 8) {
            Button("Visit wcs-full.vercel.app") {
                openURL(WCSMarketingConfig.websiteURL)
            }
            .font(.subheadline)
            .foregroundColor(AppTheme.emeraldGreen)

            Text("Contact: \(WCSMarketingConfig.supportEmail)")
                .font(.caption)
                .foregroundColor(AppTheme.textSecondary)

            HStack(spacing: 16) {
                Button("Privacy Policy") { openURL(WCSMarketingConfig.privacyPolicyURL) }
                Button("Terms of Service") { openURL(WCSMarketingConfig.termsURL) }
            }
            .font(.caption2)
            .foregroundColor(AppTheme.textSecondary)
        }
        .padding(.top, 8)
    }

    // MARK: - Actions

    private func handleTierSelect(_ tier: SubscriptionTier) {
        subscriptions.trackPlanTap(tier)
        analytics.logPlanInterest(tier.rawValue)
        switch tier {
        case .starter:
            break
        case .carePro:
            showWaitlist = true
        case .careTeam:
            showPilotForm = true
        }
    }

    // MARK: - Waitlist Sheet

    private var waitlistSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "stethoscope")
                    .font(.system(size: 50))
                    .foregroundStyle(AppTheme.emeraldGreen)

                Text("Join the Care Pro Waitlist")
                    .font(.title2.bold())

                Text("Be the first to know when Care Pro launches.\nGet early-access pricing and premium features.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Care Pro includes:")
                        .font(.caption.bold())
                        .foregroundColor(AppTheme.emeraldGreen)
                    ForEach(SubscriptionTier.carePro.features, id: \.self) { f in
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark")
                                .font(.caption2)
                                .foregroundColor(AppTheme.emeraldGreen)
                            Text(f)
                                .font(.caption)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)

                TextField("Your email", text: $waitlistEmail)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)

                Button {
                    analytics.logEvent("waitlist_signup", payload: ["tier": "care_pro", "email": waitlistEmail])
                    showWaitlist = false
                    showConfirmation = true
                } label: {
                    Text("Join Waitlist")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppTheme.emeraldGreen)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                }

                Button("Or sign up at wcs-full.vercel.app/waitlist") {
                    openURL(WCSMarketingConfig.waitlistURL)
                }
                .font(.caption)
                .foregroundColor(AppTheme.emeraldGreen)

                Spacer()
            }
            .padding(24)
            .navigationTitle("Care Pro Waitlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showWaitlist = false }
                }
            }
        }
    }

    // MARK: - Pilot Form Sheet

    private var pilotFormSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "building.2.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(AppTheme.emeraldGreen)

                Text("Request a Pilot")
                    .font(.title2.bold())

                Text("For clinics, residential care groups, and dementia support providers.\n8-12 week structured pilot with clear success criteria.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Pilot includes:")
                        .font(.caption.bold())
                        .foregroundColor(AppTheme.emeraldGreen)
                    ForEach(["Custom onboarding materials", "Dedicated pilot success dashboard", "Staff reporting & shared care plans", "Clear engagement & satisfaction metrics"], id: \.self) { item in
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark")
                                .font(.caption2)
                                .foregroundColor(AppTheme.emeraldGreen)
                            Text(item)
                                .font(.caption)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)

                VStack(spacing: 12) {
                    InfoLinkRow(icon: "globe", text: "Submit pilot request online", url: WCSMarketingConfig.pilotFormURL)
                    InfoLinkRow(icon: "envelope.fill", text: WCSMarketingConfig.supportEmail, url: URL(string: "mailto:\(WCSMarketingConfig.supportEmail)?subject=Care%20Team%20Pilot%20Request")!)
                    InfoLinkRow(icon: "link", text: "christopherappiahthompson.link", url: WCSMarketingConfig.personalLinkURL)
                }

                Spacer()

                Button {
                    analytics.logEvent("pilot_request", payload: ["tier": "care_team"])
                    openURL(WCSMarketingConfig.pilotFormURL)
                    showPilotForm = false
                } label: {
                    Text("Open Pilot Request Form")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppTheme.emeraldGreen)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                }
            }
            .padding(24)
            .navigationTitle("Care Team Pilot")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showPilotForm = false }
                }
            }
        }
    }
}

// MARK: - Tier Card

private struct TierCard: View {
    let tier: SubscriptionTier
    let isCurrentPlan: Bool
    let tapCount: Int
    let onSelect: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: tier.icon)
                    .font(.title2)
                    .foregroundStyle(isCurrentPlan ? AppTheme.emeraldGreen : AppTheme.textSecondary)

                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(tier.name)
                            .font(.headline)
                            .foregroundColor(AppTheme.textPrimary)
                        if isCurrentPlan {
                            Text("CURRENT")
                                .font(.caption2.bold())
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(AppTheme.emeraldGreen)
                                .foregroundColor(.white)
                                .cornerRadius(4)
                        }
                        if tier == .carePro {
                            Text("COMING SOON")
                                .font(.caption2.bold())
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(4)
                        }
                    }
                    Text(tier.subtitle)
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }

                Spacer()

                Text(tier.priceDisplay)
                    .font(.subheadline.bold())
                    .foregroundColor(AppTheme.emeraldGreen)
            }

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                ForEach(tier.features, id: \.self) { feature in
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(AppTheme.emeraldGreen)
                        Text(feature)
                            .font(.caption)
                            .foregroundColor(AppTheme.textPrimary)
                    }
                }
            }

            if !isCurrentPlan && tier != .starter {
                Button(action: onSelect) {
                    Text(tier == .carePro ? "Join Waitlist" : "Request Pilot")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(10)
                        .background(tier == .carePro ? AppTheme.emeraldGreen : AppTheme.emeraldGreen.opacity(0.15))
                        .foregroundColor(tier == .carePro ? .white : AppTheme.emeraldGreen)
                        .cornerRadius(10)
                }

                if tapCount > 0 {
                    Text("\(tapCount) people interested")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding()
        .background(AppTheme.surface)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isCurrentPlan ? AppTheme.emeraldGreen : Color.clear, lineWidth: 2)
        )
    }
}

private struct InfoLinkRow: View {
    let icon: String
    let text: String
    let url: URL
    @Environment(\.openURL) private var openURL

    var body: some View {
        Button {
            openURL(url)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .foregroundColor(AppTheme.emeraldGreen)
                    .frame(width: 24)
                Text(text)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textPrimary)
                Spacer()
                Image(systemName: "arrow.up.right.square")
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
            }
            .padding(10)
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
    }
}
