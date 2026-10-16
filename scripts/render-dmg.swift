import AppKit
import Foundation

// Build tool only. No Finder automation and no executable code inside the DMG.
// PNG representations share a 640 × 400 pt canvas; tiffutil combines their scales.
let arguments = CommandLine.arguments
func fail(_ message: String) -> Never {
    fputs("\(message)\n", stderr)
    exit(1)
}

guard arguments.count == 3 else { fail("Usage : swift scripts/render-dmg.swift fond.svg dossier-sortie") }
let source = URL(fileURLWithPath: arguments[1])
let output = URL(fileURLWithPath: arguments[2], isDirectory: true)
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
guard let image = NSImage(contentsOf: source) else { fail("Fond SVG illisible.") }
let size = NSSize(width: 640, height: 400)
for scale in [1, 2] {
    guard let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 640 * scale,
        pixelsHigh: 400 * scale, bitsPerSample: 8, samplesPerPixel: 4,
        hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
        bytesPerRow: 0, bitsPerPixel: 0), let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
        fail("Impossible de préparer le fond Retina.")
    }
    bitmap.size = size
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    context.cgContext.scaleBy(x: CGFloat(scale), y: CGFloat(scale))
    image.draw(in: NSRect(origin: .zero, size: size), from: .zero,
               operation: .copy, fraction: 1)
    NSGraphicsContext.restoreGraphicsState()
    guard let png = bitmap.representation(using: .png, properties: [:]) else { fail("Encodage PNG impossible.") }
    try png.write(to: output.appendingPathComponent("background@\(scale)x.png"), options: .atomic)
}
