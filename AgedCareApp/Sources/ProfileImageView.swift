import SwiftUI

enum ProfileImageSize {
  case small
  case medium
  case large
  case custom(CGFloat)

  var dimension: CGFloat {
    switch self {
    case .small: return 40
    case .medium: return 64
    case .large: return 120
    case .custom(let d): return d
    }
  }
}

struct ProfileImageView: View {
  let name: String
  let imageURL: URL?
  let size: ProfileImageSize

  @State private var loadedImage: UIImage?

  private var initials: String {
    name.split(separator: " ").compactMap { $0.first }.map { String($0) }.joined().prefix(2).uppercased()
  }

  var body: some View {
    Group {
      if let img = loadedImage {
        Image(uiImage: img)
          .resizable()
          .scaledToFill()
      } else {
        ZStack {
          Circle()
            .fill(avatarColor)
          Text(initials)
            .font(.system(size: size.dimension * 0.4, weight: .semibold))
            .foregroundColor(.white)
        }
      }
    }
    .frame(width: size.dimension, height: size.dimension)
    .clipShape(Circle())
    .task { await loadImage() }
  }

  private var avatarColor: Color {
    let hash = name.hash
    let colors: [Color] = [.blue, .teal, .green, .orange, .purple, .pink, .indigo]
    return colors[abs(hash) % colors.count]
  }

  private func loadImage() async {
    guard let url = imageURL else { return }
    loadedImage = await ImageCache.shared.load(from: url)
  }
}
