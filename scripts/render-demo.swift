// Produit les images d’une démonstration motion de sema, sans capturer l’écran ni utiliser de données privées.
import AppKit
import Foundation

/* STORYBOARD — 18 s à 30 images/s, rendu 1440 × 900.
 * 0,0 s : bureau et signe sema ; arrivée du pointeur.
 * 0,8 s : ouverture du bandeau, quatre favoris (décalage 90 ms).
 * 5,0 s : transition vers la commande, pression de ⌘K.
 * 6,2 s : frappe « euro », apparition des trois résultats.
 * 9,4 s : sélection d’euro / dollar, ouverture de Focus.
 * 10,5 s : tracé de l’historique en 2,2 s ; sidebar révélée puis repliée.
 * 16,0 s : la signature accompagne le graphique au repos.
 */
enum Demo {
    static let width = 1440, height = 900, fps = 30
    static let duration = 18.0
    static let ribbon = 0.8, cardStep = 0.09, search = 5.0, typing = 6.2
    static let result = 6.9, focus = 9.4, trace = 10.5, traceDuration = 2.2, ending = 16.0
    static let points: [(Double, Double)] = [(0,152),(17,149),(30,154),(45,137),(58,141),(72,134),(86,139),(100,121),(113,125),(128,117),(142,122),(158,103),(170,107),(186,99),(200,106),(215,83),(230,91),(247,73),(263,82),(279,67),(293,72),(310,49),(326,58),(343,44),(359,57),(375,35),(391,45),(407,31),(423,42),(439,25),(455,32),(471,18),(488,27),(505,15),(522,24),(539,11),(554,20),(572,8),(586,14),(600,5)]
}
func progress(_ t: Double, _ start: Double, _ duration: Double) -> Double { max(0, min(1, (t-start)/duration)) }
func ease(_ x: Double) -> Double { 1-pow(1-x, 3) }

final class Frame {
    let c: CGContext
    init() {
        c = CGContext(data: nil, width: Demo.width, height: Demo.height, bitsPerComponent: 8,
            bytesPerRow: Demo.width*4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        c.translateBy(x: 0, y: CGFloat(Demo.height)); c.scaleBy(x: 1, y: -1)
        NSGraphicsContext.current = NSGraphicsContext(cgContext: c, flipped: true)
    }
    func grey(_ value: Double, _ alpha: Double = 1) -> CGColor { CGColor(gray: value, alpha: alpha) }
    func text(_ value: String, _ x: Double, _ y: Double, _ size: Double, _ tone: Double = 0.91, _ weight: NSFont.Weight = .regular, width: Double = 1200, align: NSTextAlignment = .left) {
        let paragraph = NSMutableParagraphStyle(); paragraph.alignment = align
        (value as NSString).draw(in: NSRect(x:x,y:y,width:width,height:size*2.5), withAttributes:[
            .font:NSFont.systemFont(ofSize:size,weight:weight), .foregroundColor:NSColor(white:tone,alpha:1), .paragraphStyle:paragraph])
    }
    func panel(_ x: Double, _ y: Double, _ w: Double, _ h: Double, _ radius: Double = 22, _ tone: Double = 0.14, shadow: Bool = true) {
        let path = CGPath(roundedRect:CGRect(x:x,y:y,width:w,height:h),cornerWidth:radius,cornerHeight:radius,transform:nil)
        c.saveGState()
        if shadow { c.setShadow(offset:CGSize(width:0,height:14),blur:36,color:grey(0,0.32)) }
        c.addPath(path);c.setFillColor(grey(tone));c.fillPath();c.restoreGState()
        c.addPath(path);c.setStrokeColor(grey(1,0.09));c.setLineWidth(1);c.strokePath()
    }
    func layer(_ alpha: Double, _ y: Double = 0, _ scale: Double = 1, draw: () -> Void) {
        guard alpha > 0 else { return }
        c.saveGState(); c.setAlpha(alpha); c.translateBy(x:720,y:450+y); c.scaleBy(x:scale,y:scale); c.translateBy(x:-720,y:-450)
        draw();c.restoreGState()
    }
    func mark(_ x: Double, _ y: Double, _ size: Double) {
        c.saveGState();c.translateBy(x:x-10.84*size/64,y:y-6.41998*size/64);c.scaleBy(x:0.34*size/64,y:0.34*size/64)
        c.move(to:CGPoint(x:43,y:166.683)); c.addCurve(to:CGPoint(x:118.362,y:76.0449),control1:CGPoint(x:92.9018,y:166.683),control2:CGPoint(x:111.233,y:118.818))
        c.addCurve(to:CGPoint(x:90.865,y:86.229),control1:CGPoint(x:122.436,y:49.5664),control2:CGPoint(x:94.9387,y:55.6768))
        c.addCurve(to:CGPoint(x:159.098,y:96.413),control1:CGPoint(x:84.7546,y:136.131),control2:CGPoint(x:140.767,y:111.689))
        c.addCurve(to:CGPoint(x:209,y:94.3762),control1:CGPoint(x:180.485,y:79.1001),control2:CGPoint(x:196.779,y:95.3946))
        c.setLineWidth(6);c.setLineCap(.round);c.setStrokeColor(grey(0.91));c.strokePath();c.restoreGState()
    }
    func line(_ rect: CGRect, _ fraction: Double = 1, variant: Int = 0) {
        let points: [(Double,Double)] = variant == 1 ? [(0,20),(100,20),(100,42),(180,42),(180,64),(260,64),(260,86),(340,86),(340,108),(420,108),(420,130),(500,130),(500,150),(600,150)] : variant == 2 ? [(0,65),(320,65),(320,105),(600,105)] : Demo.points
        let end = fraction*Double(points.count-1);let last=Int(end)
        c.saveGState();c.translateBy(x:rect.minX,y:rect.minY);c.scaleBy(x:rect.width/600,y:rect.height/180)
        for (i,p) in points.enumerated() where i <= last {
            let y = variant == 3 ? 170-p.1 : p.1
            if i == 0 { c.move(to:CGPoint(x:p.0,y:y)) } else { c.addLine(to:CGPoint(x:p.0,y:y)) }
        }
        if last < points.count-1 {
            let a=points[last],b=points[last+1],q=end-Double(last)
            let yy=a.1+(b.1-a.1)*q
            c.addLine(to:CGPoint(x:a.0+(b.0-a.0)*q,y:variant == 3 ? 170-yy : yy))
        }
        c.restoreGState();c.setLineWidth(rect.width > 500 ? 2.5 : 1.8);c.setLineCap(.round);c.setLineJoin(.round);c.setStrokeColor(grey(0.83));c.strokePath()
    }
    func cursor(_ x: Double, _ y: Double, _ alpha: Double = 1, pressed: Double = 0) {
        layer(alpha) {
            if pressed > 0 { c.setFillColor(grey(1,0.07*pressed));c.fillEllipse(in:CGRect(x:x-17,y:y-17,width:42,height:42)) }
            let p=CGMutablePath();p.move(to:CGPoint(x:x,y:y));p.addLine(to:CGPoint(x:x+3,y:y+23));p.addLine(to:CGPoint(x:x+10,y:y+16));p.addLine(to:CGPoint(x:x+17,y:y+16));p.closeSubpath()
            c.addPath(p);c.setFillColor(grey(0.92));c.setStrokeColor(grey(0.12));c.setLineWidth(1.4);c.drawPath(using:.fillStroke)
        }
    }
    func ribbon(_ t: Double) {
        let close=1-ease(progress(t,Demo.search,0.55))
        layer(close) {
            panel(44,38,1352,672,25,0.105)
            c.saveGState();c.setFillColor(grey(0.19));c.fill(CGRect(x:45,y:39,width:1350,height:37));c.restoreGState()
            text("   finder   fichier   édition",70,48,12,0.75);mark(1243,44,28);text("09:41",1302,49,12,0.75)
            panel(330,390,780,260,20,0.13);text("●  ●  ●",355,407,10,0.4)
            text("un peu de place pour vos idées.",375,455,27,0.6,.medium)
            for i in 0..<4 {c.setFillColor(grey(0.21));c.fill(CGRect(x:375,y:520+Double(i)*22,width:i == 3 ? 250 : 550,height:4))}
            let names=["euro / dollar","taux de dépôt BCE","livret A","emprunt phare FR · 10 ans"]
            let values=["1,1642","2,00","1,70","3,42"],units=["USD","%","%","%"],changes=["+4,00 %","−1,00 pt","−1,30 pt","−0,14 pt"]
            for i in 0..<4 {
                let q=ease(progress(t,Demo.ribbon+Double(i)*Demo.cardStep,0.65))
                c.saveGState();c.setAlpha(q);c.translateBy(x:0,y:-20*(1-q))
                let x=120+Double(i)*310
                panel(x,100,296,230,24,0.195)
                text(names[i],x+22,122,14,0.84,.medium)
                text(values[i],x+22,155,43,0.93,.medium,width:180);text(units[i],x+(i == 0 ? 169:133),182,13,0.64)
                line(CGRect(x:x+22,y:218,width:252,height:58),ease(progress(t,1.2,1.2)),variant:i)
                text(changes[i],x+22,300,11,0.63);text("sur 1 an",x+202,300,11,0.63)
                c.restoreGState()
            }
            layer(ease(progress(t,Demo.ribbon,0.55))) {
                for (i,s) in ["3 mois","1 an","3 ans","5 ans","tout"].enumerated(){text(s,62,118+Double(i)*40,10,i == 1 ? 0.95:0.62)}
            }
            let travel=ease(progress(t,0.1,0.65));cursor(1100+travel*155,135-travel*75,1-ease(progress(t,1.7,0.5)),pressed:1-abs(2*progress(t,0.7,0.3)-1))
            text("vos repères. en un regard.",0,772,34,0.9,.medium,width:1440,align:.center)
        }
    }
    func search(_ t: Double) {
        let alpha=ease(progress(t,Demo.search,0.55))*(1-ease(progress(t,Demo.focus,0.5)))
        layer(alpha,20*(1-ease(progress(t,Demo.search,0.8))),0.985+0.015*ease(progress(t,Demo.search,0.8))) {
            text("un raccourci. le bon repère.",0,110,38,0.91,.medium,width:1440,align:.center)
            panel(355,240,730,358,24,0.16)
            text("⌕",381,265,27,0.65)
            let count=min(4,Int(progress(t,Demo.typing,0.6)*4));text(String("euro".prefix(count)),424,267,26)
            text("esc",1030,277,11,0.5)
            let names=["euro / dollar","euro / yen","euro / franc suisse"],values=["1,1642 USD","171,46 JPY","0,9341 CHF"]
            for i in 0..<3 {
                let q=ease(progress(t,Demo.result+Double(i)*0.11,0.45));layer(q,8*(1-q)) {
                    let y=333+Double(i)*78
                    if i == 0 {panel(370,y-4,700,70,11,0.22,shadow:false)}
                    text(names[i],392,y+8,18,0.87,.medium);text("devises",392,y+35,12,0.5)
                    text(values[i],875,y+17,15,0.68,width:175,align:.right)
                }
            }
            let press=sin(progress(t,5.3,0.45)*Double.pi)*4
            panel(647,677+press,66,62,13,0.16);panel(728,685+press,66,62,13,0.16)
            text("⌘",659,687+press,33);text("K",750,700+press,25)
            let move=ease(progress(t,8.4,0.6));cursor(1120-move*112,620-move*250,ease(progress(t,8.2,0.4)),pressed:sin(progress(t,9.0,0.35)*Double.pi))
        }
    }
    func focus(_ t: Double) {
        let q=ease(progress(t,Demo.focus,0.65))
        layer(q,22*(1-q),0.98+0.02*q) {
            panel(110,90,1220,650,24,0.12)
            text("●  ●  ●",133,106,11,0.4);text("▣",244,103,20,0.66);text("sema",281,107,15,0.8,.semibold)
            text("euro / dollar",170,174,18,0.65)
            text("1,1642",170,212,87,0.94,.regular);text("USD",469,264,25,0.55)
            text("+4,00 % sur 1 an",174,319,15,0.6)
            for (i,s) in ["3 mois","1 an","3 ans","5 ans","tout"].enumerated(){text(s,970+Double(i)*61,179,12,i == 1 ? 0.95:0.5,width:65)}
            for i in 0..<3 {c.setFillColor(grey(1,0.035));c.fill(CGRect(x:170,y:410+Double(i)*100,width:1100,height:1))}
            line(CGRect(x:174,y:390,width:1080,height:225),ease(progress(t,Demo.trace,Demo.traceDuration)))
            for (i,s) in ["oct. 2025","janv.","avr.","juil.","oct. 2026"].enumerated(){text(s,174+Double(i)*251,650,12,0.46,width:100)}
            let side=ease(progress(t,13.0,0.55))*(1-ease(progress(t,15.0,0.55)))
            layer(side,-5*(1-side)) {
                panel(124,143,244,575,16,0.175)
                panel(139,160,214,42,9,0.21,shadow:false);text("⌕  rechercher",151,172,13,0.6);text("⌘K",320,175,10,0.5)
                text("favoris",153,229,14,0.77);text("alertes",153,266,14,0.77);text("explorer",153,303,14,0.77)
                text("mes repères",153,361,12,0.55)
                panel(138,395,215,70,10,0.255,shadow:false);text("euro / dollar",153,408,14,0.9,.medium);text("1,1642 USD",153,434,12,0.6)
                text("taux de dépôt BCE",153,492,14,0.76);text("2,00 %",153,517,12,0.56)
                text("◉  mon espace",153,667,14,0.7)
            }
            cursor(268,145,ease(progress(t,12.7,0.3))*(1-ease(progress(t,15.4,0.3))))
        }
        layer(ease(progress(t,Demo.ending,0.9))) {mark(476,782,44);text("gardez vos repères.",537,790,31,0.84,.medium)}
    }
    func render(_ t: Double) -> Data {
        c.setFillColor(grey(0.055));c.fill(CGRect(x:0,y:0,width:1440,height:900))
        ribbon(t);search(t);focus(t)
        text("valeurs d’illustration",0,870,10,0.36,width:1400,align:.right)
        let image=NSBitmapImageRep(cgImage:c.makeImage()!)
        return image.representation(using:.png,properties:[:])!
    }
}
if CommandLine.arguments.count == 3, CommandLine.arguments[1] == "--poster" {
    try Frame().render(3.5).write(to:URL(fileURLWithPath:CommandLine.arguments[2]))
} else {
    for frame in 0..<Int(Demo.duration*Double(Demo.fps)) {
        autoreleasepool { FileHandle.standardOutput.write(Frame().render(Double(frame)/Double(Demo.fps))) }
    }
}
