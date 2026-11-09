// Produit les tailles d’icône nécessaires au bundle à partir du tracé natif du symbole.
import AppKit
import Foundation

// Render the same mark as the app icon SVG.
let directory = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, alpha: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: red / 255, green: green / 255, blue: blue / 255, alpha: alpha)
}

func render(pixels: Int, name: String) throws {
    let context = CGContext(data: nil, width: pixels, height: pixels, bitsPerComponent: 8,
        bytesPerRow: pixels * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    // Same geometry as Resources/Brand/sema-app-icon.svg, drawn in its 512 unit square.
    context.translateBy(x: 0, y: CGFloat(pixels))
    context.scaleBy(x: CGFloat(pixels) / 512, y: -CGFloat(pixels) / 512)
    let ink = color(20, 20, 20)
    context.addPath(CGPath(roundedRect: CGRect(x: 3, y: 3, width: 506, height: 506), cornerWidth: 115, cornerHeight: 115, transform: nil))
    context.setFillColor(ink)
    context.fillPath()

    context.move(to: CGPoint(x: 120, y: 368))
    context.addCurve(to: CGPoint(x: 312, y: 214), control1: CGPoint(x: 210, y: 368), control2: CGPoint(x: 232, y: 214))
    context.addLine(to: CGPoint(x: 392, y: 214))
    context.setLineWidth(36)
    context.setLineCap(.round)
    context.setStrokeColor(color(250, 250, 250))
    context.strokePath()

    // The teal point, separated from the line by a ring of the background colour.
    let point = CGRect(x: 312 - 34, y: 214 - 34, width: 68, height: 68)
    context.addEllipse(in: point)
    context.setFillColor(color(31, 111, 115))
    context.setStrokeColor(ink)
    context.setLineWidth(14)
    context.drawPath(using: .fillStroke)

    let bitmap = NSBitmapImageRep(cgImage: context.makeImage()!)
    try bitmap.representation(using: .png, properties: [:])!.write(to: directory.appendingPathComponent(name))
}

for size in [16, 32, 128, 256, 512] {
    try render(pixels: size, name: "icon_\(size)x\(size).png")
    try render(pixels: size * 2, name: "icon_\(size)x\(size)@2x.png")
}
