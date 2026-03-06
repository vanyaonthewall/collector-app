import UIKit
import Vision
import CoreImage
import CoreImage.CIFilterBuiltins

enum BackgroundRemovalError: Error {
    case invalidImage
    case noMaskGenerated
    case maskApplicationFailed
}

struct BackgroundRemovalService {

    /// Удаляет фон и обрезает изображение с отступом 8% от границ объекта
    static func removeBackground(from image: UIImage) async throws -> UIImage {
        // Нормализуем ориентацию перед обработкой — CGImage теряет EXIF-ориентацию
        let normalized = normalizeOrientation(image)
        guard let cgImage = normalized.cgImage else { throw BackgroundRemovalError.invalidImage }

        // 1. Vision — генерируем маску переднего плана
        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])

        guard let result = request.results?.first else {
            throw BackgroundRemovalError.noMaskGenerated
        }

        let maskPixelBuffer = try result.generateScaledMaskForImage(forInstances: result.allInstances, from: handler)

        // 2. Применяем маску через CoreImage
        let ciOriginal = CIImage(cgImage: cgImage)
        let ciMask = CIImage(cvPixelBuffer: maskPixelBuffer)

        // Размываем маску для плавных краёв — радиус пропорционален размеру изображения
        let blurFilter = CIFilter.gaussianBlur()
        blurFilter.inputImage = ciMask
        blurFilter.radius = Float(cgImage.width) * 0.003  // ~12px для 4K-фото
        let smoothMask = blurFilter.outputImage ?? ciMask

        let blendFilter = CIFilter.blendWithMask()
        blendFilter.inputImage = ciOriginal
        blendFilter.maskImage = smoothMask
        blendFilter.backgroundImage = CIImage.empty()

        guard let outputCI = blendFilter.outputImage else {
            throw BackgroundRemovalError.maskApplicationFailed
        }

        let context = CIContext()
        guard let maskedCG = context.createCGImage(outputCI, from: outputCI.extent) else {
            throw BackgroundRemovalError.maskApplicationFailed
        }

        // 3. Кроп — находим bounding box непрозрачных пикселей + padding 8%
        let cropped = cropToContent(cgImage: maskedCG, padding: 0.08)
        return UIImage(cgImage: cropped)
    }

    // MARK: - Приватные

    /// Перерисовывает UIImage в ориентации .up, сохраняя масштаб
    private static func normalizeOrientation(_ image: UIImage) -> UIImage {
        guard image.imageOrientation != .up else { return image }
        let format = UIGraphicsImageRendererFormat()
        format.scale = image.scale
        return UIGraphicsImageRenderer(size: image.size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
    }

    private static func cropToContent(cgImage: CGImage, padding: CGFloat) -> CGImage {
        let width = cgImage.width
        let height = cgImage.height
        guard let data = cgImage.dataProvider?.data,
              let bytes = CFDataGetBytePtr(data) else { return cgImage }

        let bytesPerPixel = cgImage.bitsPerPixel / 8
        let bytesPerRow = cgImage.bytesPerRow

        var minX = width, maxX = 0, minY = height, maxY = 0

        for y in 0..<height {
            for x in 0..<width {
                let offset = y * bytesPerRow + x * bytesPerPixel
                // Альфа-канал — 4-й байт (RGBA)
                let alpha = bytes[offset + 3]
                if alpha > 10 {
                    if x < minX { minX = x }
                    if x > maxX { maxX = x }
                    if y < minY { minY = y }
                    if y > maxY { maxY = y }
                }
            }
        }

        guard maxX > minX, maxY > minY else { return cgImage }

        let contentW = maxX - minX
        let contentH = maxY - minY
        let padX = Int(CGFloat(contentW) * padding)
        let padY = Int(CGFloat(contentH) * padding)

        let cropX = max(0, minX - padX)
        let cropY = max(0, minY - padY)
        let cropW = min(width - cropX, contentW + padX * 2)
        let cropH = min(height - cropY, contentH + padY * 2)

        let cropRect = CGRect(x: cropX, y: cropY, width: cropW, height: cropH)
        return cgImage.cropping(to: cropRect) ?? cgImage
    }
}
