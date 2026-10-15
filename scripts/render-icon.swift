import AppKit
import Foundation

// Render the same original vector used by sema-icon.svg and SemaSymbol.
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
        colors: [color(38, 80, 115), color(45, 149, 150)] as CFArray, locations: [0, 1])!
    context.drawLinearGradient(gradient, start: CGPoint(x: 4, y: 60), end: CGPoint(x: 60, y: 4), options: [])
    context.restoreGState()
    context.addPath(CGPath(roundedRect: CGRect(x: 4.5, y: 4.5, width: 55, height: 55),
                           cornerWidth: 12.5, cornerHeight: 12.5, transform: nil))
    context.setStrokeColor(color(255, 255, 255, alpha: 0.14))
    context.setLineWidth(1)
    context.strokePath()

    context.move(to: CGPoint(x: 37, y: 14))
    context.addLine(to: CGPoint(x: 27, y: 14))
    context.addCurve(to: CGPoint(x: 16, y: 23.5), control1: CGPoint(x: 20.4, y: 14), control2: CGPoint(x: 16, y: 18.1))
    context.addCurve(to: CGPoint(x: 27, y: 33), control1: CGPoint(x: 16, y: 29), control2: CGPoint(x: 20.4, y: 33))
    context.addLine(to: CGPoint(x: 37, y: 33))
    context.addCurve(to: CGPoint(x: 48, y: 42.5), control1: CGPoint(x: 43.6, y: 33), control2: CGPoint(x: 48, y: 37.1))
    context.addCurve(to: CGPoint(x: 37, y: 52), control1: CGPoint(x: 48, y: 48), control2: CGPoint(x: 43.6, y: 52))
    context.addLine(to: CGPoint(x: 21, y: 52))
    context.setLineWidth(8)
    context.setLineCap(.round)
    context.setLineJoin(.round)
    context.setStrokeColor(color(246, 250, 249))
    context.strokePath()
    context.setFillColor(color(154, 208, 194))
    context.fillEllipse(in: CGRect(x: 45, y: 10, width: 8, height: 8))

    let bitmap = NSBitmapImageRep(cgImage: context.makeImage()!)
    try bitmap.representation(using: .png, properties: [:])!.write(to: directory.appendingPathComponent(name))
}

for size in [16, 32, 128, 256, 512] {
    try render(pixels: size, name: "icon_\(size)x\(size).png")
    try render(pixels: size * 2, name: "icon_\(size)x\(size)@2x.png")
}
