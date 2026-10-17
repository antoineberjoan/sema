// Prépare une photo locale compacte en supprimant les métadonnées du fichier d’origine.
import Foundation
import ImageIO
import UniformTypeIdentifiers

enum ProfilePhoto {
    enum ImportError: Error, LocalizedError {
        case tooLarge, unsupported
        var errorDescription: String? {
            switch self {
            case .tooLarge: "Choisissez une image de moins de 25 Mo."
            case .unsupported: "Cette image n’a pas pu être lue. Essayez une photo JPEG, PNG ou HEIC."
            }
        }
    }

    static func prepare(_ url: URL) throws -> Data {
        let access = url.startAccessingSecurityScopedResource()
        defer { if access { url.stopAccessingSecurityScopedResource() } }
        let info = try url.resourceValues(forKeys: [.fileSizeKey])
        guard (info.fileSize ?? 0) <= 25_000_000 else { throw ImportError.tooLarge }
        guard let source = CGImageSourceCreateWithURL(url as CFURL, [kCGImageSourceShouldCache: false] as CFDictionary),
              let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: 768
              ] as CFDictionary),
              let space = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(data: nil, width: 384, height: 384, bitsPerComponent: 8,
                bytesPerRow: 0, space: space, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)
        else { throw ImportError.unsupported }
        let size = CGFloat(384)
        let scale = max(size / CGFloat(thumbnail.width), size / CGFloat(thumbnail.height))
        let width = CGFloat(thumbnail.width) * scale, height = CGFloat(thumbnail.height) * scale
        context.setFillColor(CGColor(gray: 1, alpha: 1)); context.fill(CGRect(x: 0, y: 0, width: size, height: size))
        context.interpolationQuality = .high
        context.draw(thumbnail, in: CGRect(x: (size - width) / 2, y: (size - height) / 2, width: width, height: height))
        let result = NSMutableData()
        guard let image = context.makeImage(),
              let destination = CGImageDestinationCreateWithData(result, UTType.jpeg.identifier as CFString, 1, nil)
        else { throw ImportError.unsupported }
        // A new image carries no EXIF/location metadata from the selected file.
        CGImageDestinationAddImage(destination, image, [kCGImageDestinationLossyCompressionQuality: 0.85] as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { throw ImportError.unsupported }
        return result as Data
    }
}
