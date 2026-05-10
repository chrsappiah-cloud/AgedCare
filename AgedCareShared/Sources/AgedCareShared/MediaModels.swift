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
