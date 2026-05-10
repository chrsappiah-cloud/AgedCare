import SwiftUI
import Combine

struct BetaFeedbackView: View {
    @State private var selectedFeeling: FeedbackFeeling?
    @State private var confusionText = ""
    @State private var wishText = ""
    @State private var showConfirmation = false
    @State private var selectedFeatures: Set<String> = []
    @Environment(\.openURL) private var openURL
    @Environment(\.dismiss) private var dismiss

    enum FeedbackFeeling: String, CaseIterable {
        case great = "Great"
        case okay = "Okay"
        case confused = "Confused"
        case frustrated = "Frustrated"

        var icon: String {
            switch self {
            case .great: return "hand.thumbsup.fill"
            case .okay: return "hand.raised.fill"
            case .confused: return "questionmark.circle.fill"
            case .frustrated: return "exclamationmark.triangle.fill"
            }
        }

        var color: Color {
            switch self {
            case .great: return .green
            case .okay: return .blue
            case .confused: return .orange
            case .frustrated: return .red
            }
        }
    }

    private let featureOptions = [
        "Routines & Reminders",
        "Mood & Check-ins",
        "Calming Activities",
        "Reports & Summaries",
        "Care Profiles",
        "Notifications",
        "Navigation & UI",
        "Onboarding",
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                feelingSection
                confusionSection
                wishSection
                featureSection
                submitSection
                externalFeedbackSection
            }
            .padding()
        }
        .background(AppTheme.gradientDiamond.ignoresSafeArea())
        .navigationTitle("Beta Feedback")
        .navigationBarTitleDisplayMode(.large)
        .alert("Thank you!", isPresented: $showConfirmation) {
            Button("Done") { dismiss() }
        } message: {
            Text("Your feedback helps us build something genuinely useful. We review every response.")
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "bubble.left.and.text.bubble.right.fill")
                .font(.system(size: 40))
                .foregroundStyle(AppTheme.emeraldGreen)

            Text("How's Your Experience?")
                .font(.title2.bold())
                .foregroundColor(AppTheme.textPrimary)

            Text("Quick feedback helps us improve. This is an early version — your patience and honesty are valued.")
                .font(.caption)
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Feeling

    private var feelingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How do you feel about the app today?")
                .font(.subheadline.bold())
                .foregroundColor(AppTheme.textPrimary)

            HStack(spacing: 12) {
                ForEach(FeedbackFeeling.allCases, id: \.self) { feeling in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            selectedFeeling = feeling
                        }
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: feeling.icon)
                                .font(.title2)
                                .frame(width: 50, height: 50)
                                .background(selectedFeeling == feeling ? feeling.color.opacity(0.2) : Color(.systemGray6))
                                .foregroundColor(selectedFeeling == feeling ? feeling.color : .secondary)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(selectedFeeling == feeling ? feeling.color : .clear, lineWidth: 2)
                                )
                            Text(feeling.rawValue)
                                .font(.caption2)
                                .foregroundColor(selectedFeeling == feeling ? feeling.color : .secondary)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(AppTheme.surface)
        .cornerRadius(16)
    }

    // MARK: - Confusion

    private var confusionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What's the most confusing part so far?")
                .font(.subheadline.bold())
                .foregroundColor(AppTheme.textPrimary)

            TextEditor(text: $confusionText)
                .frame(minHeight: 80)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .overlay(
                    Group {
                        if confusionText.isEmpty {
                            Text("e.g. 'I couldn't find how to add a routine' or 'The alerts were unclear'")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(12)
                        }
                    },
                    alignment: .topLeading
                )
        }
        .padding()
        .background(AppTheme.surface)
        .cornerRadius(16)
    }

    // MARK: - Wish

    private var wishSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What do you wish this app did for you today?")
                .font(.subheadline.bold())
                .foregroundColor(AppTheme.textPrimary)

            TextEditor(text: $wishText)
                .frame(minHeight: 80)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .overlay(
                    Group {
                        if wishText.isEmpty {
                            Text("e.g. 'Send me a daily summary' or 'Let me share notes with family'")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(12)
                        }
                    },
                    alignment: .topLeading
                )
        }
        .padding()
        .background(AppTheme.surface)
        .cornerRadius(16)
    }

    // MARK: - Feature Feedback

    private var featureSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Which features were most useful?")
                .font(.subheadline.bold())
                .foregroundColor(AppTheme.textPrimary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(featureOptions, id: \.self) { feature in
                    Button {
                        if selectedFeatures.contains(feature) {
                            selectedFeatures.remove(feature)
                        } else {
                            selectedFeatures.insert(feature)
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: selectedFeatures.contains(feature) ? "checkmark.circle.fill" : "circle")
                                .font(.caption)
                            Text(feature)
                                .font(.caption)
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(selectedFeatures.contains(feature) ? AppTheme.emeraldGreen.opacity(0.15) : Color(.systemGray6))
                        .foregroundColor(selectedFeatures.contains(feature) ? AppTheme.emeraldGreen : AppTheme.textPrimary)
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(AppTheme.surface)
        .cornerRadius(16)
    }

    // MARK: - Submit

    private var submitSection: some View {
        Button {
            BetaAnalytics.shared.logFeedback(
                feeling: selectedFeeling?.rawValue ?? "none",
                confusion: confusionText,
                wish: wishText,
                features: Array(selectedFeatures)
            )
            showConfirmation = true
        } label: {
            Text("Submit Feedback")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppTheme.emeraldGreen)
                .foregroundColor(.white)
                .cornerRadius(14)
        }
        .disabled(selectedFeeling == nil && confusionText.isEmpty && wishText.isEmpty)
    }

    // MARK: - External Feedback

    private var externalFeedbackSection: some View {
        VStack(spacing: 12) {
            Button {
                openURL(WCSMarketingConfig.feedbackFormURL)
            } label: {
                HStack {
                    Image(systemName: "globe")
                    Text("Submit detailed feedback online")
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .font(.caption)
                }
                .font(.subheadline)
                .foregroundColor(AppTheme.emeraldGreen)
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }

            Button {
                if let url = URL(string: "mailto:\(WCSMarketingConfig.supportEmail)?subject=WCS%20Care%20Beta%20Feedback") {
                    openURL(url)
                }
            } label: {
                HStack {
                    Image(systemName: "envelope.fill")
                    Text("Email us directly")
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .font(.caption)
                }
                .font(.subheadline)
                .foregroundColor(AppTheme.emeraldGreen)
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
        }
    }
}

// MARK: - Analytics Service (from PDF Section 6)

@MainActor
final class BetaAnalytics: ObservableObject {
    static let shared = BetaAnalytics()

    @Published var events: [(type: String, payload: [String: String], timestamp: Date)] = []
    @Published var feedbackCount: Int = 0
    @Published var planInterestCounts: [String: Int] = [:]

    private init() {}

    func logEvent(_ type: String, payload: [String: String] = [:]) {
        events.append((type: type, payload: payload, timestamp: Date()))
    }

    func logFeedback(feeling: String, confusion: String, wish: String, features: [String]) {
        feedbackCount += 1
        logEvent("beta_feedback", payload: [
            "feeling": feeling,
            "confusion": confusion.isEmpty ? "none" : confusion,
            "wish": wish.isEmpty ? "none" : wish,
            "useful_features": features.joined(separator: ","),
        ])
    }

    func logActivation(_ event: String) {
        logEvent("activation", payload: ["action": event])
    }

    func logRetention() {
        logEvent("session_start", payload: ["week": "\(Calendar.current.component(.weekOfYear, from: Date()))"])
    }

    func logPlanInterest(_ plan: String) {
        planInterestCounts[plan, default: 0] += 1
        logEvent("plan_interest", payload: ["plan": plan])
    }

    func logOnboardingStep(_ step: String, completed: Bool) {
        logEvent("onboarding", payload: ["step": step, "completed": "\(completed)"])
    }

    func logFeatureUse(_ feature: String, duration: TimeInterval? = nil) {
        var payload = ["feature": feature]
        if let d = duration { payload["duration_seconds"] = String(format: "%.0f", d) }
        logEvent("feature_use", payload: payload)
    }
}
