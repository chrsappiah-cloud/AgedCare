import SwiftUI
import AVKit

struct VideoPlayerView: View {
  let url: URL
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    ZStack(alignment: .topTrailing) {
      VideoPlayer(player: AVPlayer(url: url))
        .ignoresSafeArea()

      Button(action: { dismiss() }) {
        Image(systemName: "xmark.circle.fill")
          .font(.title)
          .foregroundColor(.white)
          .shadow(radius: 4)
          .padding()
      }
    }
  }
}
