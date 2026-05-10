import Foundation

public enum MediaAttachmentType: String, Codable, Sendable {
  case photo
  case audio
  case video
}

public struct MediaAttachment: Identifiable, Codable, Sendable {
  public let id: UUID
  public let type: MediaAttachmentType
  public let localURL: URL?
  public let remoteURL: URL?
  public let createdAt: Date

  public init(id: UUID = UUID(), type: MediaAttachmentType, localURL: URL? = nil, remoteURL: URL? = nil, createdAt: Date = Date()) {
    self.id = id
    self.type = type
    self.localURL = localURL
    self.remoteURL = remoteURL
    self.createdAt = createdAt
  }
}

public struct MediaUploadResponse: Decodable, Sendable {
  public let url: String
  public let filename: String
}

public struct UploadAttachmentRequest: Encodable {
  public let p_alert_id: Int64
  public let p_attachment_type: String
  public let p_data_base64: String
  public let p_filename: String

  public init(p_alert_id: Int64, p_attachment_type: String, p_data_base64: String, p_filename: String) {
    self.p_alert_id = p_alert_id
    self.p_attachment_type = p_attachment_type
    self.p_data_base64 = p_data_base64
    self.p_filename = p_filename
  }
}

public struct GetAttachmentsRequest: Encodable {
  public let p_alert_id: Int64
  public init(p_alert_id: Int64) { self.p_alert_id = p_alert_id }
}

// MARK: - AI Media Monitoring Models

public struct MediaAnalysisResult: Identifiable, Codable, Sendable {
  public let id: String
  public let facility_id: String
  public let resident_id: String?
  public let resident_name: String?
  public let media_url: String
  public let media_type: String
  public let analysis_status: String
  public let summary: String?
  public let confidence: Double
  public let insights: [String]
  public let detected_keywords: [String]
  public let sentiment: String?
  public let safety_flags: [SafetyFlag]
  public let transcribed_text: String?
  public let created_at: String
  public let completed_at: String?

  public struct SafetyFlag: Codable, Sendable {
    public let type: String
    public let detail: String
  }
}

public struct AudioTranscriptionResult: Codable, Sendable {
  public let transcript: String
  public let duration_seconds: Double
  public let words_per_second: Double
  public let summary: String
  public let confidence: Double
  public let insights: [String]
  public let sentiment: String
  public let safety_flags: [MediaAnalysisResult.SafetyFlag]
  public let detected_keywords: [String]
  public let event_type: String?
  public let event_keyword: String?
}

public struct AudioMonitorSession: Identifiable, Codable, Sendable {
  public let id: String
  public let facility_id: String
  public let resident_id: String?
  public let resident_name: String?
  public let status: String
  public let started_at: String
  public let stopped_at: String?
  public let last_event_at: String?
  public let event_count: Int
  public let critical_events: Int
}

public struct AudioMonitorEvent: Identifiable, Codable, Sendable {
  public let id: String
  public let session_id: String
  public let facility_id: String
  public let resident_id: String?
  public let resident_name: String?
  public let event_type: String
  public let keyword: String?
  public let confidence: Double
  public let transcript_snippet: String?
  public let audio_level: Double?
  public let detected_at: String
  public let acknowledged: Bool

  public var eventTypeDisplay: String {
    switch event_type {
    case "keyword_detected": return "Keyword detected"
    case "distress_sound": return "Distress sound"
    case "fall_sound": return "Possible fall"
    case "silence_anomaly": return "Silence anomaly"
    case "loud_noise": return "Loud noise"
    case "call_for_help": return "Call for help"
    case "medication_reminder": return "Medication reminder"
    default: return event_type.replacingOccurrences(of: "_", with: " ").capitalized
    }
  }

  public var eventIcon: String {
    switch event_type {
    case "keyword_detected": return "waveform.path.mic"
    case "distress_sound": return "exclamationmark.triangle"
    case "fall_sound": return "figure.fall"
    case "silence_anomaly": return "speaker.slash"
    case "loud_noise": return "speaker.wave.3"
    case "call_for_help": return "hand.raised"
    case "medication_reminder": return "pills"
    default: return "questionmark"
    }
  }
}

public struct AIInsightsRequest: Encodable {
  public let facility_id: String
  public let limit: Int?
  public let status: String?
  public init(facility_id: String, limit: Int? = nil, status: String? = nil) {
    self.facility_id = facility_id
    self.limit = limit
    self.status = status
  }
}

public struct AIMonitorStartRequest: Encodable {
  public let facility_id: String
  public let resident_id: String?
  public let started_by: String?
  public init(facility_id: String, resident_id: String? = nil, started_by: String? = nil) {
    self.facility_id = facility_id
    self.resident_id = resident_id
    self.started_by = started_by
  }
}

public struct AIMonitorStopRequest: Encodable {
  public let session_id: String
  public init(session_id: String) { self.session_id = session_id }
}

public struct AIEventReport: Encodable {
  public let resident_id: String?
  public let event_type: String
  public let keyword: String?
  public let confidence: Double
  public let transcript_snippet: String?
  public let audio_level: Double?
  public init(resident_id: String? = nil, event_type: String, keyword: String? = nil,
              confidence: Double = 0.0, transcript_snippet: String? = nil, audio_level: Double? = nil) {
    self.resident_id = resident_id
    self.event_type = event_type
    self.keyword = keyword
    self.confidence = confidence
    self.transcript_snippet = transcript_snippet
    self.audio_level = audio_level
  }
}

public struct AISessionsRequest: Encodable {
  public let facility_id: String
  public let limit: Int?
  public init(facility_id: String, limit: Int? = nil) {
    self.facility_id = facility_id
    self.limit = limit
  }
}

public struct AIEventsRequest: Encodable {
  public let facility_id: String
  public let hours: Int?
  public init(facility_id: String, hours: Int? = nil) {
    self.facility_id = facility_id
    self.hours = hours
  }
}

public struct AIAnalyzeMediaRequest: Encodable {
  public let data_base64: String
  public let filename: String
  public let media_type: String
  public let facility_id: String
  public let resident_id: String?
  public let media_url: String?
  public let transcribed_text: String?
  public init(data_base64: String, filename: String, media_type: String,
              facility_id: String, resident_id: String? = nil,
              media_url: String? = nil, transcribed_text: String? = nil) {
    self.data_base64 = data_base64
    self.filename = filename
    self.media_type = media_type
    self.facility_id = facility_id
    self.resident_id = resident_id
    self.media_url = media_url
    self.transcribed_text = transcribed_text
  }
}
