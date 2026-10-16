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
        colors: [color(32, 39, 37), color(16, 22, 20)] as CFArray, locations: [0, 1])!
    context.drawLinearGradient(gradient, start: CGPoint(x: 4, y: 4), end: CGPoint(x: 60, y: 60), options: [])
    context.restoreGState()

    // Same D3 path as the SVG, normalized to 64 and inset by 8 points.
    context.translateBy(x: 8 - 10.84 * 0.75, y: 8 - 6.76 * 0.75)
    context.scaleBy(x: 0.34 * 0.75, y: 0.34 * 0.75)
    context.move(to: CGPoint(x: 43, y: 149.348))
    context.addCurve(to: CGPoint(x: 89.6292, y: 114.842), control1: CGPoint(x: 84.0337, y: 149.348), control2: CGPoint(x: 95.2247, y: 128.831))
    context.addCurve(to: CGPoint(x: 74.7079, y: 128.831), control1: CGPoint(x: 84.0337, y: 100.854), control2: CGPoint(x: 64.4494, y: 112.045))
    context.addCurve(to: CGPoint(x: 155.843, y: 92.4604), control1: CGPoint(x: 95.2247, y: 162.404), control2: CGPoint(x: 137.191, y: 119.505))
    context.addCurve(to: CGPoint(x: 209, y: 81.2694), control1: CGPoint(x: 174.494, y: 65.4155), control2: CGPoint(x: 187.551, y: 81.2694))
    context.setLineWidth(8.5)
    context.setLineCap(.round)
    context.setLineJoin(.round)
    context.setStrokeColor(color(154, 208, 194))
    context.strokePath()

    let bitmap = NSBitmapImageRep(cgImage: context.makeImage()!)
    try bitmap.representation(using: .png, properties: [:])!.write(to: directory.appendingPathComponent(name))
}

for size in [16, 32, 128, 256, 512] {
    try render(pixels: size, name: "icon_\(size)x\(size).png")
    try render(pixels: size * 2, name: "icon_\(size)x\(size)@2x.png")
}
