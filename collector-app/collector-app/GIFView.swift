import SwiftUI
import ImageIO

struct GIFView: UIViewRepresentable {
    let name: String

    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        imageView.image = Self.loadGIF(named: name)
        return imageView
    }

    func updateUIView(_ uiView: UIImageView, context: Context) {}

    static func loadGIF(named name: String) -> UIImage? {
        guard
            let url = Bundle.main.url(forResource: name, withExtension: "gif"),
            let data = try? Data(contentsOf: url),
            let source = CGImageSourceCreateWithData(data as CFData, nil as CFDictionary?)
        else { return nil }

        let count = CGImageSourceGetCount(source)
        var images: [UIImage] = []
        var totalDuration: Double = 0

        let frameOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true
        ]
        for i in 0..<count {
            guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, i, frameOptions as CFDictionary) else { continue }
            totalDuration += frameDuration(at: i, source: source)
            images.append(UIImage(cgImage: cgImage))
        }

        guard !images.isEmpty else { return nil }
        return UIImage.animatedImage(with: images, duration: totalDuration)
    }

    private static func frameDuration(at index: Int, source: CGImageSource) -> Double {
        let defaultDelay = 0.1
        guard
            let props = CGImageSourceCopyPropertiesAtIndex(source, index, nil as CFDictionary?) as? [CFString: Any],
            let gifProps = props[kCGImagePropertyGIFDictionary] as? [CFString: Any]
        else { return defaultDelay }
        let delay = gifProps[kCGImagePropertyGIFUnclampedDelayTime] as? Double
                 ?? gifProps[kCGImagePropertyGIFDelayTime] as? Double
                 ?? defaultDelay
        return delay < 0.011 ? defaultDelay : delay
    }
}
