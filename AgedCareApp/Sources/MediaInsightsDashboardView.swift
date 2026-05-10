import SwiftUI

struct MediaInsightsDashboardView: View {
  let staff: StaffUserModel
  @StateObject private var ai = AIMonitoringService.shared
  @State private var selectedTab: InsightsTab = .media
  @State private var showAudioMonitor = false

  enum InsightsTab: String, CaseIterable {
    case media = "AI Insights"
    case events = "Alert Events"
    case sessions = "Sessions"

    var icon: String {
      switch self {
      case .media: return "waveform.and.magnifyingglass"
      case .events: return "bell.badge.fill"
      case .sessions: return "radio"
      }
    }
  }

  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        pickerStrip
        tabContent
      }
      .navigationTitle("AI Monitoring")
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button { Task { await refreshAll() } } label: {
            Image(systemName: "arrow.clockwise")
          }
          .accessibilityLabel("Refresh monitoring data")
        }
        ToolbarItem(placement: .navigationBarLeading) {
          Button(action: { showAudioMonitor = true }) {
            Image(systemName: "mic.badge.plus")
          }
          .accessibilityLabel("Start audio monitoring session")
        }
      }
      .task { await refreshAll() }
      .onAppear {
        ai.startPolling(facilityId: staff.facilityId.uuidString)
      }
      .onDisappear {
        ai.stopPolling()
      }
      .sheet(isPresented: $showAudioMonitor) {
        AudioMonitorView(staff: staff, aiService: AIMonitoringService.shared)
      }
    }
  }

  private var pickerStrip: some View {
    Picker("View", selection: $selectedTab) {
      ForEach(InsightsTab.allCases, id: \.self) { tab in
        Label(tab.rawValue, systemImage: tab.icon).tag(tab)
      }
    }
    .pickerStyle(.segmented)
    .padding()
    .accessibilityLabel("Monitoring insights category")
  }

  @ViewBuilder
  private var tabContent: some View {
    switch selectedTab {
    case .media:
      mediaInsightsList
    case .events:
      audioEventsList
    case .sessions:
      monitoringSessionsList
    }
  }

  private var mediaInsightsList: some View {
    List {
      if ai.recentInsights.isEmpty && !ai.isLoading {
        ContentUnavailableView(
          "No Insights Yet",
          systemImage: "waveform.and.magnifyingglass",
          description: Text("Media you upload will be analyzed here by AI")
        )
      }
      ForEach(ai.recentInsights) { insight in
        MediaInsightRow(insight: insight)
      }
    }
    .refreshable { await ai.fetchInsights(facilityId: staff.facilityId.uuidString) }
    .overlay {
      if ai.isLoading { ProgressView("Loading insights\u{2026}") }
    }
  }

  private var audioEventsList: some View {
    List {
      if ai.recentEvents.isEmpty && !ai.isLoading {
        ContentUnavailableView(
          "No Recent Events",
          systemImage: "bell.badge.fill",
          description: Text("Audio monitoring events will appear here in real time")
        )
      }
      ForEach(ai.recentEvents) { event in
        AudioEventRow(event: event)
      }
    }
    .refreshable { await ai.fetchRecentEvents(facilityId: staff.facilityId.uuidString) }
    .overlay {
      if ai.isLoading { ProgressView("Loading events\u{2026}") }
    }
  }

  private var monitoringSessionsList: some View {
    List {
      if ai.activeSessions.isEmpty && !ai.isLoading {
        ContentUnavailableView(
          "No Sessions",
          systemImage: "radio",
          description: Text("Start an audio monitoring session to track resident activity")
        )
      }
      ForEach(ai.activeSessions) { session in
        MonitoringSessionRow(session: session, ai: ai)
      }
    }
    .refreshable { await ai.fetchSessions(facilityId: staff.facilityId.uuidString) }
    .overlay {
      if ai.isLoading { ProgressView("Loading sessions\u{2026}") }
    }
  }

  private func refreshAll() async {
    async let insights: () = ai.fetchInsights(facilityId: staff.facilityId.uuidString)
    async let events: () = ai.fetchRecentEvents(facilityId: staff.facilityId.uuidString)
    async let sessions: () = ai.fetchSessions(facilityId: staff.facilityId.uuidString)
    _ = await (insights, events, sessions)
  }
}

// MARK: - Media Insight Row

struct MediaInsightRow: View {
  let insight: MediaAnalysisResult

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      HStack {
        Label(insight.media_type.capitalized, systemImage: mediaIcon)
          .font(.subheadline.bold())
        Spacer()
        sentimentBadge
      }
      if let summary = insight.summary {
        Text(summary)
          .font(.body)
      }
      if !insight.insights.isEmpty {
        ForEach(insight.insights, id: \.self) { item in
          Label(item, systemImage: "info.circle")
            .font(.caption)
            .foregroundColor(.secondary)
        }
      }
      if !insight.safety_flags.isEmpty {
        ForEach(insight.safety_flags.indices, id: \.self) { i in
          Label(insight.safety_flags[i].detail, systemImage: "exclamationmark.triangle.fill")
            .font(.caption.weight(.medium))
            .foregroundColor(.orange)
        }
      }
      if !insight.detected_keywords.isEmpty {
        HStack(spacing: 4) {
          ForEach(insight.detected_keywords.prefix(5), id: \.self) { kw in
            Text(kw)
              .font(.caption2.bold())
              .padding(.horizontal, 6)
              .padding(.vertical, 2)
              .background(Color.accentColor.opacity(0.15))
              .cornerRadius(4)
          }
        }
      }
      HStack {
        Text(insight.created_at)
          .font(.caption2)
          .foregroundColor(.secondary)
        Spacer()
        if insight.confidence > 0 {
          Text("\(Int(insight.confidence * 100))% confidence")
            .font(.caption2)
            .foregroundColor(.secondary)
        }
      }
    }
    .padding(.vertical, 4)
    .accessibilityElement(children: .combine)
    .accessibilityLabel("\(insight.media_type) insight: \(insight.summary ?? "No summary")")
  }

  private var mediaIcon: String {
    switch insight.media_type {
    case "photo": return "camera.fill"
    case "audio": return "mic.fill"
    case "video": return "video.fill"
    default: return "doc.fill"
    }
  }

  private var sentimentBadge: some View {
    HStack(spacing: 4) {
      Circle().fill(sentimentColor).frame(width: 8, height: 8)
      Text(insight.sentiment?.capitalized ?? "Unknown")
        .font(.caption2)
        .foregroundColor(.secondary)
    }
    .accessibilityLabel("Sentiment: \(insight.sentiment ?? "unknown")")
  }

  private var sentimentColor: Color {
    switch insight.sentiment {
    case "positive": return .green
    case "concern", "attention": return .orange
    default: return .gray
    }
  }
}

// MARK: - Audio Event Row

struct AudioEventRow: View {
  let event: AudioMonitorEvent

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      Image(systemName: event.eventIcon)
        .font(.title3)
        .foregroundColor(eventColor)
        .frame(width: 32)
        .accessibilityHidden(true)
      VStack(alignment: .leading, spacing: 4) {
        HStack {
          Text(event.eventTypeDisplay)
            .font(.subheadline.bold())
          Spacer()
          if event.acknowledged {
            Text("Seen")
              .font(.caption2)
              .foregroundColor(.secondary)
              .padding(.horizontal, 6)
              .padding(.vertical, 2)
              .background(Color(.systemGray5))
              .cornerRadius(4)
          } else {
            Text("New")
              .font(.caption2.bold())
              .foregroundColor(.white)
              .padding(.horizontal, 6)
              .padding(.vertical, 2)
              .background(Color.red)
              .cornerRadius(4)
          }
        }
        if let resident = event.resident_name {
          Text(resident)
            .font(.caption)
            .foregroundColor(.secondary)
        }
        if let snippet = event.transcript_snippet {
          Text("\"\(snippet)\"")
            .font(.caption)
            .foregroundColor(.secondary)
            .italic()
        }
        if let keyword = event.keyword {
          Text("Keyword: \(keyword)")
            .font(.caption2)
            .foregroundColor(.orange)
        }
        HStack {
          Text(event.detected_at)
            .font(.caption2)
            .foregroundColor(.secondary)
          if let level = event.audio_level {
            Text("Level: \(Int(level * 100))%")
              .font(.caption2)
              .foregroundColor(.secondary)
          }
          if event.confidence > 0 {
            Text("\(Int(event.confidence * 100))% conf")
              .font(.caption2)
              .foregroundColor(.secondary)
          }
        }
      }
    }
    .padding(.vertical, 4)
    .accessibilityElement(children: .combine)
    .accessibilityLabel("\(event.eventTypeDisplay) event")
    .accessibilityHint(event.acknowledged ? "Already reviewed" : "New event requiring attention")
  }

  private var eventColor: Color {
    switch event.event_type {
    case "fall_sound", "call_for_help": return .red
    case "distress_sound": return .orange
    case "loud_noise": return .yellow
    case "keyword_detected", "medication_reminder": return .blue
    default: return .gray
    }
  }
}

// MARK: - Monitoring Session Row

struct MonitoringSessionRow: View {
  let session: AudioMonitorSession
  let ai: AIMonitoringService

  var body: some View {
    HStack(spacing: 12) {
      VStack(alignment: .leading, spacing: 4) {
        HStack {
          statusDot
          Text(session.status.capitalized)
            .font(.subheadline.bold())
          Spacer()
          if session.critical_events > 0 {
            Text("\(session.critical_events) critical")
              .font(.caption2.bold())
              .foregroundColor(.red)
              .padding(.horizontal, 6)
              .padding(.vertical, 2)
              .background(Color.red.opacity(0.1))
              .cornerRadius(4)
          }
        }
        if let name = session.resident_name {
          Text(name)
            .font(.caption)
            .foregroundColor(.secondary)
        }
        HStack(spacing: 12) {
          Label("\(session.event_count) events", systemImage: "waveform.path")
            .font(.caption2)
            .foregroundColor(.secondary)
          Text(session.started_at)
            .font(.caption2)
            .foregroundColor(.secondary)
        }
      }
    }
    .padding(.vertical, 4)
    .accessibilityElement(children: .combine)
    .accessibilityLabel("Monitoring session: \(session.status), \(session.event_count) events, \(session.critical_events) critical")
  }

  private var statusDot: some View {
    Circle()
      .fill(session.status == "active" ? Color.green : Color.gray)
      .frame(width: 10, height: 10)
      .accessibilityHidden(true)
  }
}
