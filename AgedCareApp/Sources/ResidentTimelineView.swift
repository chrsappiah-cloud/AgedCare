import SwiftUI
import AgedCareShared

struct ResidentTimelineView: View {
  let resident: ResidentModel
  @EnvironmentObject var container: DependencyContainer
  @State private var entries: [TimelineEntryDTO] = []
  @State private var loadError: String?

  var body: some View {
    List(entries, id: \.ts) { entry in
      switch entry.kind {
      case "fall":
        FallTimelineRow(entry: entry)
      case "vital":
        VitalTimelineRow(entry: entry)
      default:
        Text(entry.summary)
      }
    }
    .navigationTitle("Timeline")
    .task { await loadTimeline() }
    .overlay {
      if entries.isEmpty {
        if let error = loadError {
          Text(error).foregroundColor(.red).padding()
        } else {
          Text("No events yet").foregroundColor(.secondary)
        }
      }
    }
  }

  private func loadTimeline() async {
    do {
      entries = try await container.residentsRepository.getTimeline(residentId: resident.id)
    } catch {
      loadError = error.localizedDescription
    }
  }
}

struct FallTimelineRow: View {
  let entry: TimelineEntryDTO

  var body: some View {
    HStack {
      Image(systemName: "exclamationmark.triangle.fill")
        .foregroundColor(.red)
      VStack(alignment: .leading) {
        Text(entry.summary)
          .font(.body)
        Text(entry.ts)
          .font(.caption)
          .foregroundColor(.secondary)
      }
    }
  }
}

struct VitalTimelineRow: View {
  let entry: TimelineEntryDTO

  var body: some View {
    HStack {
      Image(systemName: "heart.fill")
        .foregroundColor(.pink)
      VStack(alignment: .leading) {
        Text(entry.summary)
          .font(.body)
        Text(entry.ts)
          .font(.caption)
          .foregroundColor(.secondary)
      }
    }
  }
}
