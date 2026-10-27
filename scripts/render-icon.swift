// Produit les tailles d’icône nécessaires au bundle à partir du tracé natif du symbole.
import AppKit
import Foundation

// Render the same original vector used by Symbol.
let directory = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, alpha: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: red / 255, green: green / 255, blue: blue / 255, alpha: alpha)
}

func render(pixels: Int, name: String) throws {
    let context = CGContext(data: nil, width: pixels, height: pixels, bitsPerComponent: 8,
        bytesPerRow: pixels * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    context.translateBy(x: 0, y: CGFloat(pixels))
    context.scaleBy(x: CGFloat(pixels) / 64, y: -CGFloat(pixels) / 64)
    let background = CGPath(roundedRect: CGRect(x: 4, y: 4, width: 56, height: 56),
                            cornerWidth: 13, cornerHeight: 13, transform: nil)
    context.saveGState()
    context.addPath(background)
    context.clip()
    let gradient = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB),
        colors: [color(39, 39, 39), color(22, 22, 22)] as CFArray, locations: [0, 1])!
    context.drawLinearGradient(gradient, start: CGPoint(x: 4, y: 4), end: CGPoint(x: 60, y: 60), options: [])
    context.restoreGState()

    // Same Palier — Référence path as the SVG, uniformly scaled and centred.
    context.translateBy(x: 8 - 10.84 * 0.75, y: 8 - 6.41998 * 0.75)
    context.scaleBy(x: 0.34 * 0.75, y: 0.34 * 0.75)
    context.move(to: CGPoint(x: 43, y: 166.683))
    context.addCurve(to: CGPoint(x: 118.362, y: 76.0449), control1: CGPoint(x: 92.9018, y: 166.683), control2: CGPoint(x: 111.233, y: 118.818))
    context.addCurve(to: CGPoint(x: 90.865, y: 86.229), control1: CGPoint(x: 122.436, y: 49.5664), control2: CGPoint(x: 94.9387, y: 55.6768))
    context.addCurve(to: CGPoint(x: 159.098, y: 96.413), control1: CGPoint(x: 84.7546, y: 136.131), control2: CGPoint(x: 140.767, y: 111.689))
    context.addCurve(to: CGPoint(x: 209, y: 94.3762), control1: CGPoint(x: 180.485, y: 79.1001), control2: CGPoint(x: 196.779, y: 95.3946))
    context.setLineWidth(8.5)
    context.setLineCap(.round)
    context.setLineJoin(.round)
    context.setStrokeColor(color(250, 250, 250))
    context.strokePath()

    let bitmap = NSBitmapImageRep(cgImage: context.makeImage()!)
    try bitmap.representation(using: .png, properties: [:])!.write(to: directory.appendingPathComponent(name))
}

for size in [16, 32, 128, 256, 512] {
    try render(pixels: size, name: "icon_\(size)x\(size).png")
    try render(pixels: size * 2, name: "icon_\(size)x\(size)@2x.png")
}
