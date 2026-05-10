import SwiftUI
import AVKit
import AgedCareShared

struct MediaAttachmentView: View {
  let attachments: [MediaAttachment]

  private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)

  var body: some View {
    if attachments.isEmpty {
      EmptyView()
    } else {
      LazyVGrid(columns: columns, spacing: 8) {
        ForEach(attachments) { item in
          MediaThumbnail(attachment: item)
        }
      }
      .padding(.vertical, 4)
    }
  }
}

private struct MediaThumbnail: View {
  let attachment: MediaAttachment
  @State private var showVideoPlayer = false

  var body: some View {
    Group {
      switch attachment.type {
      case .photo:
        photoView
      case .audio:
        audioView
      case .video:
        videoView
      }
    }
    .clipShape(RoundedRectangle(cornerRadius: 8))
    .frame(height: 80)
    .onTapGesture { handleTap() }
    .fullScreenCover(isPresented: $showVideoPlayer) {
      if let url = attachment.localURL ?? attachment.remoteURL {
        VideoPlayerView(url: url)
      }
    }
  }

  private var photoView: some View {
    let url = attachment.localURL ?? attachment.remoteURL
    if let url = url, let image = UIImage(contentsOfFile: url.path) {
      return AnyView(
        Image(uiImage: image)
          .resizable()
          .scaledToFill()
      )
    }
    return AnyView(
      ZStack {
        RoundedRectangle(cornerRadius: 8).fill(Color(.secondarySystemBackground))
        Image(systemName: "photo").foregroundColor(.secondary)
      }
    )
  }

  private var audioView: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 8).fill(Color(.secondarySystemBackground))
      Image(systemName: "waveform").font(.title2).foregroundColor(.accentColor)
    }
  }

  private var videoView: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 8).fill(Color(.secondarySystemBackground))
      Image(systemName: "play.circle.fill").font(.title).foregroundColor(.white)
    }
  }

  private func handleTap() {
    guard let url = attachment.localURL ?? attachment.remoteURL else { return }
    switch attachment.type {
    case .audio:
      let player = try? AVAudioPlayer(contentsOf: url)
      player?.play()
    case .video:
      showVideoPlayer = true
    case .photo:
      break
    }
  }
}
