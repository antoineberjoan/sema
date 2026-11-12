// Produit les tailles d’icône du bundle depuis la géométrie de SignalPath et les couleurs de DesignPrimitive.
// Compilé avec ces deux fichiers par build-app.sh : le script ne contient ni point, ni couleur, ni dimension.
import AppKit
import Foundation

let directory = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

func color(_ hex: UInt32) -> CGColor {
    CGColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255, blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
}

func render(pixels: Int, name: String) throws {
    let context = CGContext(data: nil, width: pixels, height: pixels, bitsPerComponent: 8,
        bytesPerRow: pixels * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    // The icon unit square: the same geometry as the exported SVG, whose single source is SignalPath.
    context.translateBy(x: 0, y: CGFloat(pixels))
    context.scaleBy(x: CGFloat(pixels) / SignalPath.appIconSize, y: -CGFloat(pixels) / SignalPath.appIconSize)
    let ink = color(DesignPrimitive.ink800)
    let offset = SignalPath.appIconOffset
    let moved = { (point: CGPoint) in CGPoint(x: point.x + offset.x, y: point.y + offset.y) }
    let inset = SignalPath.appIconInset
    let tile = SignalPath.appIconSize - 2 * inset
    context.addPath(CGPath(roundedRect: CGRect(x: inset, y: inset, width: tile, height: tile),
                           cornerWidth: SignalPath.appIconCorner, cornerHeight: SignalPath.appIconCorner, transform: nil))
    context.setFillColor(ink)
    context.fillPath()

    context.move(to: moved(SignalPath.start))
    context.addCurve(to: moved(SignalPath.dotCenter), control1: moved(SignalPath.control1), control2: moved(SignalPath.control2))
    context.addLine(to: moved(SignalPath.end))
    context.setLineWidth(SignalPath.stroke)
    context.setLineCap(.round)
    context.setStrokeColor(color(DesignPrimitive.paper0))
    context.strokePath()

    // The teal point, separated from the line by a ring of the background colour.
    let radius = (SignalPath.dotRadius + SignalPath.gapRadius) / 2
    let center = moved(SignalPath.dotCenter)
    context.addEllipse(in: CGRect(x: center.x - radius, y: center.y - radius, width: 2 * radius, height: 2 * radius))
    context.setFillColor(color(DesignPrimitive.accent500(.brand)))
    context.setStrokeColor(ink)
    context.setLineWidth(SignalPath.gapRadius - SignalPath.dotRadius)
    context.drawPath(using: .fillStroke)

    let bitmap = NSBitmapImageRep(cgImage: context.makeImage()!)
    try bitmap.representation(using: .png, properties: [:])!.write(to: directory.appendingPathComponent(name))
}

for size in [16, 32, 128, 256, 512] {
    try render(pixels: size, name: "icon_\(size)x\(size).png")
    try render(pixels: size * 2, name: "icon_\(size)x\(size)@2x.png")
}
