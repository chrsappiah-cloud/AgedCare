import SwiftUI

struct GrowthRoadmapView: View {
    @State private var selectedPhase: GrowthPhase = .foundation
    @State private var selectedTrack: BetaTrack?
    @Environment(\.openURL) private var openURL

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerSection
                phaseSelector
                phaseDetail
                betaTracksSection
                metricsSection
                contentRhythmSection
                validationSection
                linksSection
            }
            .padding()
        }
        .background(AppTheme.gradientDiamond.ignoresSafeArea())
        .navigationTitle("Growth Roadmap")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 40))
                .foregroundStyle(AppTheme.emeraldGreen)

            Text("12-Month Growth Plan")
                .font(.title2.bold())
                .foregroundColor(AppTheme.textPrimary)

            Text("Ship small, finished slices. Learn from real users.\nGrowth comes from consistent small improvements.")
                .font(.caption)
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Phase Selector

    private var phaseSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(GrowthPhase.allCases) { phase in
                    Button {
                        withAnimation { selectedPhase = phase }
                    } label: {
                        VStack(spacing: 4) {
                            Text(phase.months)
                                .font(.caption2.bold())
                            Text(phase.rawValue.replacingOccurrences(of: "Phase \\d: ", with: "", options: .regularExpression))
                                .font(.caption)
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(selectedPhase == phase ? AppTheme.emeraldGreen : AppTheme.emeraldGreen.opacity(0.12))
                        .foregroundColor(selectedPhase == phase ? .white : AppTheme.emeraldGreen)
                        .cornerRadius(12)
                    }
                }
            }
        }
    }

    // MARK: - Phase Detail

    private var phaseDetail: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(selectedPhase.rawValue)
                        .font(.headline)
                        .foregroundColor(AppTheme.textPrimary)
                    Text(selectedPhase.months)
                        .font(.caption)
                        .foregroundColor(AppTheme.emeraldGreen)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Target Testers")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(selectedPhase.testerTarget)
                        .font(.subheadline.bold())
                        .foregroundColor(AppTheme.emeraldGreen)
                }
            }

            Divider()

            ForEach(selectedPhase.goals, id: \.self) { goal in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "checkmark.circle")
                        .font(.caption)
                        .foregroundColor(AppTheme.emeraldGreen)
                        .padding(.top, 2)
                    Text(goal)
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textPrimary)
                }
            }
        }
        .padding()
        .background(AppTheme.surface)
        .cornerRadius(16)
    }

    // MARK: - Beta Tracks

    private var betaTracksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Beta Tracks")
                .font(.headline)
                .foregroundColor(AppTheme.textPrimary)

            ForEach(BetaTrack.allCases) { track in
                Button {
                    withAnimation { selectedTrack = (selectedTrack == track) ? nil : track }
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(track.rawValue)
                                .font(.subheadline.bold())
                                .foregroundColor(AppTheme.textPrimary)
                            Spacer()
                            Text("\(WCSMarketingConfig.apps(for: track).count) apps")
                                .font(.caption)
                                .foregroundColor(AppTheme.emeraldGreen)
                            Image(systemName: selectedTrack == track ? "chevron.up" : "chevron.down")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Text(track.targetAudience)
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if selectedTrack == track {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("North Star:")
                                    .font(.caption.bold())
                                    .foregroundColor(AppTheme.emeraldGreen)
                                Text(track.northStar)
                                    .font(.caption)
                                    .foregroundColor(AppTheme.textPrimary)

                                Divider()

                                ForEach(WCSMarketingConfig.apps(for: track)) { app in
                                    HStack(spacing: 8) {
                                        Image(systemName: app.icon)
                                            .font(.caption)
                                            .foregroundColor(AppTheme.emeraldGreen)
                                        Text(app.name)
                                            .font(.caption)
                                            .foregroundColor(AppTheme.textPrimary)
                                        Spacer()
                                        Text(app.price)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding(.top, 4)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(AppTheme.surface)
        .cornerRadius(16)
    }

    // MARK: - Metrics

    private var metricsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Success Metrics")
                .font(.headline)
                .foregroundColor(AppTheme.textPrimary)

            ForEach(WCSMarketingConfig.successMetrics, id: \.name) { metric in
                HStack(spacing: 10) {
                    Image(systemName: "chart.bar.fill")
                        .font(.caption)
                        .foregroundColor(AppTheme.emeraldGreen)
                        .frame(width: 20)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(metric.name)
                            .font(.subheadline.bold())
                            .foregroundColor(AppTheme.textPrimary)
                        Text(metric.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(AppTheme.surface)
        .cornerRadius(16)
    }

    // MARK: - Content Rhythm

    private var contentRhythmSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Content Rhythm")
                .font(.headline)
                .foregroundColor(AppTheme.textPrimary)

            ForEach(WCSMarketingConfig.weeklyContentRhythm, id: \.self) { item in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.caption)
                        .foregroundColor(AppTheme.emeraldGreen)
                        .padding(.top, 2)
                    Text(item)
                        .font(.caption)
                        .foregroundColor(AppTheme.textPrimary)
                }
            }
        }
        .padding()
        .background(AppTheme.surface)
        .cornerRadius(16)
    }

    // MARK: - Validation

    private var validationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Revenue Validation Questions")
                .font(.headline)
                .foregroundColor(AppTheme.textPrimary)

            ForEach(Array(WCSMarketingConfig.revenueValidationQuestions.enumerated()), id: \.offset) { idx, question in
                HStack(alignment: .top, spacing: 10) {
                    Text("\(idx + 1)")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .frame(width: 22, height: 22)
                        .background(AppTheme.emeraldGreen)
                        .clipShape(Circle())
                    Text(question)
                        .font(.caption)
                        .foregroundColor(AppTheme.textPrimary)
                }
            }
        }
        .padding()
        .background(AppTheme.surface)
        .cornerRadius(16)
    }

    // MARK: - Links

    private var linksSection: some View {
        VStack(spacing: 10) {
            linkButton("View Case Studies", icon: "doc.text.fill", url: WCSMarketingConfig.caseStudiesURL)
            linkButton("Partner Onboarding", icon: "person.2.fill", url: WCSMarketingConfig.partnerOnboardingURL)
            linkButton("Changelog", icon: "list.bullet.rectangle", url: WCSMarketingConfig.changelogURL)
            linkButton("christopherappiahthompson.link", icon: "link", url: WCSMarketingConfig.personalLinkURL)
        }
    }

    private func linkButton(_ label: String, icon: String, url: URL) -> some View {
        Button {
            openURL(url)
        } label: {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(AppTheme.emeraldGreen)
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textPrimary)
                Spacer()
                Image(systemName: "arrow.up.right.square")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .background(AppTheme.surface)
            .cornerRadius(10)
        }
    }
}
