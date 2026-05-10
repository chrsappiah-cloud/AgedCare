import UIKit

final class ImageCache {
  static let shared = ImageCache()

  private let cache = NSCache<NSString, UIImage>()

  private init() {
    cache.countLimit = 100
    cache.totalCostLimit = 50 * 1024 * 1024
  }

  func image(for key: String) -> UIImage? {
    cache.object(forKey: key as NSString)
  }

  func setImage(_ image: UIImage, for key: String) {
    cache.setObject(image, forKey: key as NSString)
  }

  func load(from url: URL) async -> UIImage? {
    let key = url.absoluteString
    if let cached = image(for: key) { return cached }
    do {
      let (data, _) = try await URLSession.shared.data(from: url)
      guard let image = UIImage(data: data) else { return nil }
      setImage(image, for: key)
      return image
    } catch {
      return nil
    }
  }
}
