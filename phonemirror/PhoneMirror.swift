// PhoneMirror — live, auto-oriented, auto-cropped mirror of a USB iPhone/iPad screen.
//
// Run it bare:  phonemirror
//
// It works out the rest by LOOKING at the first frame with Vision OCR:
//   • which rotation makes text upright  → so a landscape-held phone whose iOS UI is stuck in
//     portrait comes out landscape, with no flags
//   • where iOS Camera.app's chrome is   → the mode wheel (PHOTO / VIDEO / SLO-MO / PORTRAIT /
//     SQUARE …) is found by name, and cropped OUT, so you get viewfinder only
//   • where the letterbox black bars are → trimmed by luminance
//
// Why this app exists: QuickTime Player can mirror a Lightning-connected iOS device, but its
// Edit ▸ Rotate Left/Right/Flip items are DISABLED during a live capture session and its
// scripting dictionary has no rotate terminology — so a live feed cannot be un-rotated. This
// rotates the preview layer instead: the window is already correct, and a one-shot screen
// recording (RecBurn etc.) captures it right way up. No record-then-edit step.
//
// Apple-native: AppKit + AVFoundation + CoreMediaIO + Vision. xcrun swiftc. No Homebrew.
//
// FEATURE-CARD >> features/phonemirror-rotated-live-mirror.feature

import Cocoa
import SwiftUI
import AVFoundation
import CoreMediaIO
import Vision
import CoreImage

// MARK: - CoreMediaIO: unhide iOS screen-capture DAL devices
//
// An iOS device on USB is published as a CoreMediaIO DAL "screen capture" device, and those are
// INVISIBLE to AVCaptureDevice enumeration until this system property is set. QuickTime sets it;
// any other process must set it itself or it sees only the built-in camera. This one call is the
// difference between "no iPhone found" and a working mirror.
func allowScreenCaptureDevices() {
    var prop = CMIOObjectPropertyAddress(
        mSelector: CMIOObjectPropertySelector(kCMIOHardwarePropertyAllowScreenCaptureDevices),
        mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
        mElement: CMIOObjectPropertyElement(0))
    var allow: UInt32 = 1
    CMIOObjectSetPropertyData(CMIOObjectID(kCMIOObjectSystemObject), &prop, 0, nil,
                              UInt32(MemoryLayout<UInt32>.size), &allow)
}

func captureDevices() -> [AVCaptureDevice] {
    var seen = Set<String>(); var out: [AVCaptureDevice] = []
    for mt in [AVMediaType.video, .muxed] {
        for d in AVCaptureDevice.devices(for: mt) where !seen.contains(d.uniqueID) {
            seen.insert(d.uniqueID); out.append(d)
        }
    }
    return out
}

func findDevice(match: String?, timeout: TimeInterval) -> AVCaptureDevice? {
    let deadline = Date().addingTimeInterval(timeout)
    repeat {
        let devs = captureDevices()
        if let m = match?.lowercased(), !m.isEmpty {
            if let d = devs.first(where: { $0.localizedName.lowercased().contains(m) }) { return d }
        } else if let d = devs.first(where: {
            let n = $0.localizedName.lowercased()
            return n.contains("iphone") || n.contains("ipad") || n.contains("ipod")
        }) { return d }
        RunLoop.current.run(until: Date().addingTimeInterval(0.25))
    } while Date() < deadline
    return nil
}

// MARK: - Grab one frame

/// Hands the FIRST frame to a callback and then goes quiet.
///
/// This must never block the main thread: waiting on a semaphore in
/// applicationDidFinishLaunching starves the CoreMediaIO plugin and no frame ever arrives
/// (measured: 0 frames in 5s). So detection is asynchronous — the window opens immediately with
/// safe defaults and snaps to the detected orientation/crop a moment later.
final class FirstFrameWatcher: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    var onFrame: ((CGImage) -> Void)?
    private var taken = false
    private let ciContext = CIContext()
    let queue = DispatchQueue(label: "org.esaruoho.phonemirror.frames")

    func arm() { taken = false }

    func captureOutput(_ out: AVCaptureOutput, didOutput sample: CMSampleBuffer,
                       from conn: AVCaptureConnection) {
        // The pixel buffer is only valid inside this callback, so convert here and now.
        guard !taken, let pb = CMSampleBufferGetImageBuffer(sample) else { return }
        let ci = CIImage(cvPixelBuffer: pb)
        guard let cg = ciContext.createCGImage(ci, from: ci.extent) else { return }
        taken = true
        DispatchQueue.main.async { [weak self] in self?.onFrame?(cg) }
    }
}

// MARK: - Vision: what am I looking at?

/// iOS Camera.app mode-wheel labels. Finding these tells us both which way is up and where the
/// chrome lives, because they only ever sit in the control band beside the viewfinder.
let cameraChromeWords: Set<String> = [
    "PHOTO", "VIDEO", "SLO-MO", "SLOMO", "PORTRAIT", "SQUARE", "PANO", "PANORAMA",
    "TIME-LAPSE", "TIMELAPSE", "CINEMATIC", "SPATIAL"
]

struct Detection {
    var rotation: Int                 // degrees to feed the preview layer
    var score: Int                    // evidence count behind that choice
    var chromeBoxes: [CGRect]         // normalized SOURCE coords, y-up (Vision convention)
    var words: [String]
    var basis: String                 // how the rotation was decided, for the log
}

// MARK: - Normalized 90° coordinate mapping
//
// Rotating the source CCW by 90° in y-up coords maps (x,y) → (1-y, x). Verified at the corners:
// bottom-left (0,0) → bottom-right (1,0); bottom-right (1,0) → top-right (1,1).
func mapPointFwd90(_ p: CGPoint) -> CGPoint { CGPoint(x: 1 - p.y, y: p.x) }
func mapPointBack90(_ p: CGPoint) -> CGPoint { CGPoint(x: p.y, y: 1 - p.x) }

/// Map a normalized rect through `times` quarter-turns, forward (source→rotated) or back.
func mapRect(_ r: CGRect, quarterTurns times: Int, forward: Bool) -> CGRect {
    var rect = r
    for _ in 0..<(((times % 4) + 4) % 4) {
        let cs = [CGPoint(x: rect.minX, y: rect.minY), CGPoint(x: rect.maxX, y: rect.minY),
                  CGPoint(x: rect.minX, y: rect.maxY), CGPoint(x: rect.maxX, y: rect.maxY)]
            .map { forward ? mapPointFwd90($0) : mapPointBack90($0) }
        let xs = cs.map { $0.x }, ys = cs.map { $0.y }
        rect = CGRect(x: xs.min()!, y: ys.min()!,
                      width: xs.max()! - xs.min()!, height: ys.max()! - ys.min()!)
    }
    return rect
}

/// Rotate using the SAME visual convention as CALayer: CIImage extent is y-up like a layer, so a
/// positive angle here matches a positive angle in CATransform3DMakeRotation.
func rotated(_ img: CGImage, _ deg: Int) -> CGImage? {
    if ((deg % 360) + 360) % 360 == 0 { return img }
    let ci = CIImage(cgImage: img)
        .transformed(by: CGAffineTransform(rotationAngle: CGFloat(Double(deg) * .pi / 180.0)))
    return CIContext().createCGImage(ci, from: ci.extent)
}

struct Word { let text: String; let box: CGRect; let confidence: Float }

func readText(_ img: CGImage) -> [Word] {
    let req = VNRecognizeTextRequest()
    req.recognitionLevel = .fast
    req.usesLanguageCorrection = false
    let handler = VNImageRequestHandler(cgImage: img, options: [:])
    do { try handler.perform([req]) } catch { return [] }
    guard let obs = req.results else { return [] }
    return obs.compactMap { o in
        guard let c = o.topCandidates(1).first else { return nil }
        return Word(text: c.string.uppercased().trimmingCharacters(in: .whitespaces),
                    box: o.boundingBox, confidence: c.confidence)
    }
}

func isChrome(_ s: String) -> Bool {
    cameraChromeWords.contains(s.replacingOccurrences(of: " ", with: ""))
}

/// Words that look like real content rather than UI furniture — the SCENE being filmed.
func isSceneWord(_ s: String) -> Bool {
    if isChrome(s) { return false }
    let stripped = s.filter { $0.isLetter || $0.isNumber }
    if stripped.count < 3 { return false }
    // "1X", "HDR", "LIVE" etc. are Camera overlays, not scene content.
    return !["1X", "05X", "2X", "3X", "HDR", "LIVE", "OFF", "AUTO", "RAW"].contains(stripped)
}

/// Decide which rotation to display.
///
/// KEY INSIGHT: upright *chrome* tells you the iOS UI orientation, which is NOT what we want.
/// With Rotation Lock on and the phone held landscape, iOS draws its UI upright while the
/// viewfinder shows the scene turned 90°. So we score on SCENE text — the thing being filmed —
/// and only fall back to (chrome-upright + 90°) when the scene has no readable text.
func detectOrientation(_ frame: CGImage) -> Detection {
    var perRotation: [(deg: Int, words: [Word])] = []
    for deg in [0, 90, 180, 270] {
        guard let r = rotated(frame, deg) else { continue }
        perRotation.append((deg, readText(r)))
    }
    guard !perRotation.isEmpty else {
        return Detection(rotation: 90, score: 0, chromeBoxes: [], words: [], basis: "no OCR possible")
    }

    // Chrome reads most reliably where it is upright. Map those boxes back to SOURCE coords so
    // all later geometry is independent of whichever rotation we end up displaying.
    let chromeBest = perRotation.max { a, b in
        a.words.filter { isChrome($0.text) }.count < b.words.filter { isChrome($0.text) }.count
    }!
    let chromeHits = chromeBest.words.filter { isChrome($0.text) }
    let chromeSource = chromeHits.map { mapRect($0.box, quarterTurns: chromeBest.deg / 90, forward: false) }

    // The BAND the chrome occupies, in SOURCE coords, padded generously. Any text landing in this
    // strip is chrome — including the GARBAGE that OCR invents when it reads the mode wheel upside
    // down (SQUARE→"IYVNUS", PORTRAIT→"IIVIIITIOD", PHOTO→"OIOHD", VIDEO→"OAAIA", SLO-MO→"OW-OIS").
    // Excluding the band, rather than requiring membership in a detected viewfinder, keeps this
    // independent of the crop heuristic — which is what let 180° win twice.
    var chromeBandLo = -1.0, chromeBandHi = -1.0
    if !chromeSource.isEmpty {
        let lo = chromeSource.map { $0.minY }.min()!, hi = chromeSource.map { $0.maxY }.max()!
        let pad = max(0.05, (hi - lo) * 1.5)
        chromeBandLo = Double(lo) - Double(pad)
        chromeBandHi = Double(hi) + Double(pad)
    }

    func sceneWords(_ deg: Int, _ words: [Word]) -> [String] {
        words.filter { w in
            guard w.confidence >= 0.4, isSceneWord(w.text) else { return false }
            guard chromeBandLo >= 0 else { return true }
            let inSource = mapRect(w.box, quarterTurns: deg / 90, forward: false)
            let cy = Double(inSource.midY)
            return cy < chromeBandLo || cy > chromeBandHi
        }.map { $0.text }
    }

    let scored = perRotation.map { (deg: $0.deg, scene: sceneWords($0.deg, $0.words)) }
    let sceneBest = scored.max { $0.scene.count < $1.scene.count }!

    if sceneBest.scene.count >= 2 {
        return Detection(rotation: sceneBest.deg, score: sceneBest.scene.count,
                         chromeBoxes: chromeSource, words: sceneBest.scene,
                         basis: "scene text upright inside the viewfinder")
    }
    if !chromeHits.isEmpty {
        // Scene unreadable: assume the case this tool exists for — portrait UI held landscape.
        return Detection(rotation: (chromeBest.deg + 90) % 360, score: chromeHits.count,
                         chromeBoxes: chromeSource, words: chromeHits.map { $0.text },
                         basis: "chrome upright at \(chromeBest.deg)°, +90 for a portrait UI held landscape")
    }
    return Detection(rotation: 90, score: 0, chromeBoxes: [], words: [], basis: "no text found — assuming 90°")
}

/// Per-column / per-row MEDIAN luminance of a downscaled copy, for finding control bands.
///
/// Median, not mean, and this matters twice over:
///   • iOS Camera.app's control bands are black but carry white glyphs (flash, timer, Live Photo).
///     Their MEAN is lifted above any black threshold, so a mean-based trim leaves them in shot.
///     Their MEDIAN is ~0, because they are mostly black.
///   • A relative/max-based threshold fails the other way: one overexposed window in the scene
///     raises max so far that most of the real viewfinder falls below the bar (measured: it
///     cropped to a 0.156-wide sliver).
/// Median + a low ABSOLUTE threshold is immune to both.
func luminanceProfile(_ img: CGImage, side: Int = 96) -> (cols: [Double], rows: [Double])? {
    var buf = [UInt8](repeating: 0, count: side * side)
    guard let cs = CGColorSpace(name: CGColorSpace.linearGray),
          let ctx = CGContext(data: &buf, width: side, height: side, bitsPerComponent: 8,
                              bytesPerRow: side, space: cs,
                              bitmapInfo: CGImageAlphaInfo.none.rawValue) else { return nil }
    ctx.draw(img, in: CGRect(x: 0, y: 0, width: side, height: side))
    func median(_ v: inout [Double]) -> Double { v.sort(); return v[v.count / 2] }
    var cols = [Double](repeating: 0, count: side), rows = [Double](repeating: 0, count: side)
    for x in 0..<side {
        var col = (0..<side).map { Double(buf[$0 * side + x]) }
        cols[x] = median(&col)
    }
    for y in 0..<side {
        var row = (0..<side).map { Double(buf[y * side + $0]) }
        rows[y] = median(&row)
    }
    // CGContext row 0 is the BOTTOM, which is already the y-up convention used throughout
    // the analysis. No flip here — conversion to top-down happens once, at the very end.
    return (cols, rows)
}

/// Longest contiguous BRIGHT run in a luminance profile, as normalized (start, end).
///
/// A plain near-black trim is not enough: iOS Camera.app's control bands are black but carry
/// white glyphs (flash, timer, Live Photo, filters), and those glyphs lift the band's mean above
/// any absolute black threshold — so the band survives the trim and stays in the shot. A
/// RELATIVE threshold plus longest-run selection discards it, because the viewfinder is a
/// photographic image and is dramatically brighter across its whole width than an icon strip.
/// Trim near-black runs from both ends of a MEDIAN profile. Absolute threshold, so scene
/// brightness and overexposure are irrelevant.
func trimDark(_ p: [Double], threshold: Double = 14.0) -> (Double, Double) {
    let n = p.count
    guard n > 0 else { return (0, 1) }
    var lo = 0, hi = n - 1
    while lo < hi && p[lo] < threshold { lo += 1 }
    while hi > lo && p[hi] < threshold { hi -= 1 }
    if hi <= lo { return (0, 1) }
    return (Double(lo) / Double(n), Double(hi + 1) / Double(n))
}

func brightRun(_ p: [Double], relative: Double = 0.35) -> (Double, Double) {
    let n = p.count
    guard n > 0, let mx = p.max(), mx > 0 else { return (0, 1) }
    let thr = max(8.0, mx * relative)
    var bestStart = 0, bestLen = 0, runStart = -1
    for i in 0..<n {
        if p[i] >= thr {
            if runStart < 0 { runStart = i }
        } else if runStart >= 0 {
            if i - runStart > bestLen { bestLen = i - runStart; bestStart = runStart }
            runStart = -1
        }
    }
    if runStart >= 0, n - runStart > bestLen { bestLen = n - runStart; bestStart = runStart }
    if bestLen == 0 { return (0, 1) }
    return (Double(bestStart) / Double(n), Double(bestStart + bestLen) / Double(n))
}

/// Work out the crop that keeps the viewfinder and drops chrome + letterbox.
/// Everything here is in SOURCE-frame normalized coords, y-up (Vision convention).
/// Callers map it into display orientation afterwards.
func detectCrop(sourceFrame: CGImage, chromeBoxesSource: [CGRect]) -> CGRect {
    let full = CGRect(x: 0, y: 0, width: 1, height: 1)

    // NEVER crop by luminance. It looks reasonable and is wrong: the scene being filmed can
    // itself be black (measured: a DOS CRT), and no brightness test can separate "black control
    // band" from "black subject". Doing so ate the middle of the feed and produced a 0.517-wide
    // window when the viewfinder needed the full width. Geometry is content-independent; use it.
    //
    // Facts we can rely on for iOS Camera.app on a phone screen:
    //   • the viewfinder spans the FULL short edge (full width in portrait)
    //   • PHOTO mode is 4:3, so its height is (4/3) x the width
    //   • the mode wheel sits in the control band directly beyond one end of the viewfinder
    guard !chromeBoxesSource.isEmpty else { return full }

    let w = CGFloat(sourceFrame.width), h = CGFloat(sourceFrame.height)
    guard w > 0, h > 0 else { return full }
    let shortEdge = min(w, h), longEdge = max(w, h)
    let viewfinderFrac = min(1.0, (4.0 / 3.0) * (shortEdge / longEdge))

    // SLIDE a band of exactly the viewfinder's height over the frame and keep the position that
    // contains the most actual image. This beats anchoring off the chrome, which failed twice:
    //   • flush against the mode-wheel TEXT starts too low — the text sits below the viewfinder
    //     edge by more than any fixed margin, so a black strip rode along (bar on one side only)
    //   • centring the leftover slack pulls in the OPPOSITE chrome band, because that slack is
    //     the icon row (flash / timer / Live Photo), not padding
    // The two black chrome bands lose this contest on their own merits — they are near-black,
    // while the viewfinder holds a real image. Nothing has to know where they are.
    // Anchor the 4:3 band just beyond the chrome, then shave any PURE-BLACK rows still riding
    // along at either edge. Two things make this reliable where earlier attempts failed:
    //   • the anchor is the chrome band, which OCR locates by name — not image statistics, which
    //     cannot tell a black control band from a black subject (a DOS CRT)
    //   • the shave is capped and only removes rows whose MEDIAN is essentially zero, so a merely
    //     dark subject survives while a true letterbox strip does not. That is what makes the
    //     leftover bars uniform instead of all-on-one-side.
    let meanY = chromeBoxesSource.map { $0.midY }.reduce(0, +) / CGFloat(chromeBoxesSource.count)

    // MEASURED gap between the top of the mode-wheel TEXT and the edge of the 4:3 preview on iOS
    // Camera.app. It is a fixed layout, so a constant is honest here — unlike a luminance probe,
    // which cannot survive a black subject. Anchoring flush (0.012) left a ~5% black strip riding
    // along, which showed as a bar on one side only. If this is ever off, ⌘[ / ⌘] nudge it live.
    // Calibrated between two measured extremes: 0.012 left a black bar on the far side, 0.062
    // pulled the icon strip in on the near side. The midpoint lands the 4:3 band on the preview.
    let gapToPreview: CGFloat = 0.040

    var y0: CGFloat, y1: CGFloat
    if meanY < 0.5 {                                       // chrome at the bottom
        y0 = min((chromeBoxesSource.map { $0.maxY }.max() ?? 0) + gapToPreview, 1.0)
        y1 = min(1.0, y0 + viewfinderFrac)
    } else {                                               // chrome at the top
        y1 = max((chromeBoxesSource.map { $0.minY }.min() ?? 1) - gapToPreview, 0.0)
        y0 = max(0.0, y1 - viewfinderFrac)
    }

    if y1 - y0 < 0.35 { return full }          // implausible → whole screen beats a sliver
    return CGRect(x: 0, y: y0, width: 1, height: y1 - y0)
}

// MARK: - Rotating / cropping preview view

final class PreviewView: NSView {
    let previewLayer: AVCaptureVideoPreviewLayer
    var rotation: CGFloat { didSet { needsLayout = true } }
    var mirrored: Bool    { didSet { needsLayout = true } }
    /// Sub-rect of the ROTATED image blown up to fill the window. Normalized, origin top-left.
    var crop: CGRect      { didSet { needsLayout = true } }

    init(session: AVCaptureSession, rotation: CGFloat, mirrored: Bool, crop: CGRect) {
        self.previewLayer = AVCaptureVideoPreviewLayer(session: session)
        self.rotation = rotation; self.mirrored = mirrored; self.crop = crop
        super.init(frame: .zero)
        wantsLayer = true
        let root = CALayer()
        root.backgroundColor = NSColor.black.cgColor
        root.masksToBounds = true        // clip the blown-up crop
        layer = root
        previewLayer.videoGravity = .resizeAspect
        root.addSublayer(previewLayer)
    }
    required init?(coder: NSCoder) { fatalError("not used") }

    override func layout() {
        super.layout()
        let b = bounds
        let cw = max(crop.width, 0.01), ch = max(crop.height, 0.01)
        // Scale the whole rotated frame up so that just the crop sub-rect fills the view.
        let fullW = b.width / cw, fullH = b.height / ch
        // An odd quarter-turn needs width/height swapped BEFORE the transform.
        let quarterTurn = Int(rotation.rounded()) % 180 != 0
        previewLayer.bounds = CGRect(x: 0, y: 0,
                                     width:  max(quarterTurn ? fullH : fullW, 1),
                                     height: max(quarterTurn ? fullW : fullH, 1))
        // Shift so the crop centre lands on the view centre (crop y is top-down, layer y is up).
        let ccx = crop.origin.x + cw / 2.0, ccy = crop.origin.y + ch / 2.0
        previewLayer.position = CGPoint(x: b.midX + (0.5 - ccx) * fullW,
                                        y: b.midY - (0.5 - ccy) * fullH)
        var t = CATransform3DMakeRotation(rotation * .pi / 180.0, 0, 0, 1)
        if mirrored { t = CATransform3DConcat(CATransform3DMakeScale(-1, 1, 1), t) }
        previewLayer.transform = t
    }
}

// MARK: - App

final class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    let session = AVCaptureSession()
    var preview: PreviewView!
    let detectorOutput = AVCaptureVideoDataOutput()
    let watcher = FirstFrameWatcher()

    // Defaults are the whole point: bare `phonemirror` should just be right.
    var autoRotate = true
    var autoCrop = true
    var rotation: CGFloat = 0
    var crop = CGRect(x: 0, y: 0, width: 1, height: 1)
    var mirrored = false
    var deviceMatch: String? = nil
    var borderless = false
    var startWidth: CGFloat = 0
    var waitSeconds: TimeInterval = 20     // generous: the USB link to a phone flaps
    var srcAspect: CGFloat = 1125.0 / 2436.0

    func applicationDidFinishLaunching(_ note: Notification) {
        allowScreenCaptureDevices()
        parseArgs()

        guard let dev = findDevice(match: deviceMatch, timeout: waitSeconds) else { failNoDevice(); return }
        guard let input = try? AVCaptureDeviceInput(device: dev), session.canAddInput(input) else {
            fail("Could not open \(dev.localizedName) for capture.\n\n"
               + "iOS screen-capture devices are SINGLE-CLIENT — if QuickTime has a Movie "
               + "Recording window open on the phone, close it and try again.")
            return
        }
        session.addInput(input)

        if let f = dev.formats.last {
            let d = CMVideoFormatDescriptionGetDimensions(f.formatDescription)
            if d.width > 0 && d.height > 0 { srcAspect = CGFloat(d.width) / CGFloat(d.height) }
        }

        // Safe default while Vision has not spoken yet: a portrait UI held landscape is exactly
        // the case this tool exists for, so 90° is the right guess to show immediately.
        if autoRotate && rotation == 0 { rotation = 90 }

        buildWindow(title: "PhoneMirror — \(dev.localizedName)")
        buildMenu()

        if autoRotate || autoCrop { attachDetector() }
        session.startRunning()

        // Plain Space (no modifier) toggles solo. A menu keyEquivalent of " " would render as
        // ⌘Space, which is Spotlight — so this is a local key monitor instead.
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] e in
            let mods = e.modifierFlags.intersection(.deviceIndependentFlagsMask)
                .subtracting([.capsLock, .function, .numericPad])
            if e.keyCode == 49 && mods.isEmpty {
                self?.toggleSolo(nil)
                return nil
            }
            return e
        }

        // The shared Help panel is also reachable via the shared notification, so the menu item
        // and any other trigger open the same thing.
        NotificationCenter.default.addObserver(forName: .showAppHelp, object: nil, queue: .main) {
            [weak self] _ in self?.showHelp(nil)
        }

        NSApp.activate(ignoringOtherApps: true)
    }

    /// Add a video data output whose first frame drives the Vision pass.
    func attachDetector() {
        guard session.canAddOutput(detectorOutput) else { return }
        detectorOutput.alwaysDiscardsLateVideoFrames = true
        session.addOutput(detectorOutput)
        watcher.onFrame = { [weak self] frame in self?.inspect(frame) }
        watcher.arm()
        detectorOutput.setSampleBufferDelegate(watcher, queue: watcher.queue)
    }

    /// Vision runs off-main (it takes ~4 OCR passes), then the result is applied on main.
    func inspect(_ frame: CGImage) {
        let wantRotate = autoRotate, wantCrop = autoCrop
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let det = detectOrientation(frame)
            let rot = wantRotate ? CGFloat(det.rotation) : (self?.rotation ?? 90)
            var newCrop = CGRect(x: 0, y: 0, width: 1, height: 1)
            if wantCrop {
                // Crop is computed in SOURCE space, then mapped into the display rotation and
                // finally flipped to top-down origin, which is what PreviewView expects.
                let srcCrop = detectCrop(sourceFrame: frame, chromeBoxesSource: det.chromeBoxes)
                let rotCrop = mapRect(srcCrop, quarterTurns: Int(rot) / 90, forward: true)
                newCrop = CGRect(x: rotCrop.minX, y: 1.0 - rotCrop.maxY,
                                 width: rotCrop.width, height: rotCrop.height)
            }
            DispatchQueue.main.async {
                guard let self = self else { return }
                if wantRotate {
                    self.rotation = rot
                    self.log("orientation: \(Int(rot))° — \(det.basis)"
                        + (det.words.isEmpty ? "" : " [\(det.words.prefix(6).joined(separator: ", "))]"))
                }
                if wantCrop {
                    self.crop = newCrop
                    self.log(String(format: "crop: x=%.3f y=%.3f w=%.3f h=%.3f (chrome + letterbox removed)",
                                    newCrop.origin.x, newCrop.origin.y, newCrop.width, newCrop.height))
                }
                self.preview.rotation = self.rotation
                self.preview.crop = self.crop
                self.refit()
            }
        }
    }

    func buildWindow(title: String) {
        let quarterTurn = Int(rotation) % 180 != 0
        let rotA = quarterTurn ? (1.0 / srcAspect) : srcAspect
        let outAspect = rotA * (crop.width / max(crop.height, 0.01))
        let w = startWidth > 0 ? startWidth : 900
        let h = (w / outAspect).rounded()

        preview = PreviewView(session: session, rotation: rotation, mirrored: mirrored, crop: crop)
        let style: NSWindow.StyleMask = borderless
            ? [.borderless, .resizable] : [.titled, .closable, .miniaturizable, .resizable]
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: w, height: h),
                          styleMask: style, backing: .buffered, defer: false)
        window.title = title
        window.contentView = preview
        window.contentAspectRatio = NSSize(width: outAspect, height: 1)
        window.center()
        window.isMovableByWindowBackground = true
        window.collectionBehavior.insert(.fullScreenPrimary)
        window.makeKeyAndOrderFront(nil)
    }

    func refit() {
        let quarterTurn = Int(rotation) % 180 != 0
        let rotA = quarterTurn ? (1.0 / srcAspect) : srcAspect
        let aspect = rotA * (crop.width / max(crop.height, 0.01))
        window.contentAspectRatio = NSSize(width: aspect, height: 1)
        var f = window.frame
        let chrome = window.frame.height - window.contentLayoutRect.height
        f.size.height = (f.size.width / aspect).rounded() + chrome
        window.setFrame(f, display: true, animate: false)
    }

    @objc func rotateLeft(_ s: Any?)  { rotation = norm(rotation - 90); preview.rotation = rotation; refit() }
    @objc func rotateRight(_ s: Any?) { rotation = norm(rotation + 90); preview.rotation = rotation; refit() }
    @objc func toggleMirror(_ s: Any?) { mirrored.toggle(); preview.mirrored = mirrored }
    @objc func resetCrop(_ s: Any?) { crop = CGRect(x: 0, y: 0, width: 1, height: 1); preview.crop = crop; refit() }

    // Live nudge along the crop's long axis, so a slightly-off anchor is a keypress to fix
    // rather than a rebuild. Width/height are preserved — this only slides the window.
    @objc func nudgeCropBack(_ s: Any?) { slideCrop(-0.01) }
    @objc func nudgeCropFwd(_ s: Any?)  { slideCrop(+0.01) }
    func slideCrop(_ d: CGFloat) {
        if crop.width < 0.999 {
            crop.origin.x = max(0, min(1 - crop.width, crop.origin.x + d))
        } else if crop.height < 0.999 {
            crop.origin.y = max(0, min(1 - crop.height, crop.origin.y + d))
        }
        preview.crop = crop
        log(String(format: "crop nudged → x=%.3f y=%.3f w=%.3f h=%.3f",
                   crop.origin.x, crop.origin.y, crop.width, crop.height))
    }
    @objc func redetect(_ s: Any?) {
        autoRotate = true; autoCrop = true
        log("re-detecting from the next frame…")
        watcher.arm()          // the next frame re-triggers the Vision pass
    }
    func norm(_ d: CGFloat) -> CGFloat { CGFloat(((Int(d) % 360) + 360) % 360) }

    func buildMenu() {
        let main = NSMenu()
        let appItem = NSMenuItem(); let appMenu = NSMenu()
        let aboutItem = NSMenuItem(title: "About PhoneMirror — and how to support Esa",
                                   action: #selector(showHelp(_:)), keyEquivalent: "")
        aboutItem.target = self
        appMenu.addItem(aboutItem)
        appMenu.addItem(.separator())
        let soloApp = NSMenuItem(title: "Hide All Other Apps", action: #selector(toggleSolo(_:)), keyEquivalent: "")
        soloApp.target = self
        appMenu.addItem(soloApp)
        appMenu.addItem(withTitle: "Hide PhoneMirror", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Quit PhoneMirror", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appItem.submenu = appMenu; main.addItem(appItem)

        let vItem = NSMenuItem(title: "View", action: nil, keyEquivalent: "")
        let v = NSMenu(title: "View")
        // Explicit targets: relying on the responder chain silently dropped these (⌘D did nothing).
        func add(_ title: String, _ sel: Selector, _ key: String) {
            let mi = NSMenuItem(title: title, action: sel, keyEquivalent: key)
            mi.target = self
            v.addItem(mi)
        }
        add("Rotate Left",  #selector(rotateLeft(_:)),  "L")
        add("Rotate Right", #selector(rotateRight(_:)), "R")
        add("Flip Horizontal", #selector(toggleMirror(_:)), "H")
        v.addItem(.separator())
        add("Re-detect (Vision)", #selector(redetect(_:)), "d")
        add("Show Whole Screen (no crop)", #selector(resetCrop(_:)), "0")
        add("Nudge Crop ←", #selector(nudgeCropBack(_:)), "[")
        add("Nudge Crop →", #selector(nudgeCropFwd(_:)), "]")
        v.addItem(.separator())
        let solo = NSMenuItem(title: "Hide All Other Apps  (Space)", action: #selector(toggleSolo(_:)), keyEquivalent: "")
        solo.target = self
        v.addItem(solo)
        v.addItem(withTitle: "Enter Full Screen", action: #selector(NSWindow.toggleFullScreen(_:)), keyEquivalent: "f")
        vItem.submenu = v; main.addItem(vItem)

        // Help menu — the shared panel, same in every app here.
        let hItem = NSMenuItem(title: "Help", action: nil, keyEquivalent: "")
        let h = NSMenu(title: "Help")
        let hi = NSMenuItem(title: "PhoneMirror Help", action: #selector(showHelp(_:)), keyEquivalent: "?")
        hi.target = self
        h.addItem(hi)
        hItem.submenu = h; main.addItem(hItem)

        NSApp.mainMenu = main
        NSApp.helpMenu = h
    }

    // MARK: Shared Help + donate panel
    //
    // PROJECT GROUND RULE: every Apple-native app here ships the SAME Help, which is the same set
    // of ways to donate to Esa — one component, `shared/SupportHelp.swift`, never a per-app list.
    // This app is AppKit rather than SwiftUI, so the shared SwiftUI view is hosted in a panel via
    // NSHostingController; the donation links still come from the one shared source.
    var helpWindow: NSWindow?

    @objc func showHelp(_ s: Any?) {
        if let w = helpWindow { w.makeKeyAndOrderFront(nil); return }
        let view = AppHelpView(
            appName: "PhoneMirror",
            tagline: "Live mirror of a USB iPhone or iPad screen — rotated and cropped as you want it, "
                   + "so a one-shot screen recording needs no editing afterwards.",
            usage: [
                ("bolt", "Run it bare: Vision OCR reads the first frame, picks the rotation, and crops iOS Camera.app's controls out"),
                ("rotate.right", "⇧⌘L / ⇧⌘R rotate · ⇧⌘H flip horizontally"),
                ("crop", "⌘[ / ⌘] nudge the crop · ⌘0 show the whole phone screen · ⌘D re-detect"),
                ("rectangle.on.rectangle", "Space hides every other app, so only the mirror is on screen"),
                ("record.circle", "Pair with recburn --system-audio to film it beside anything else")
            ],
            note: "QuickTime Player cannot rotate a live device mirror — its Rotate and Flip items are "
                + "disabled during capture. That is why this exists."
        )
        let host = NSHostingController(rootView: view)
        let w = NSWindow(contentViewController: host)
        w.title = "PhoneMirror Help"
        w.styleMask = [.titled, .closable]
        w.setContentSize(NSSize(width: 460, height: 620))
        w.center()
        w.isReleasedWhenClosed = false
        helpWindow = w
        w.makeKeyAndOrderFront(nil)
    }

    // MARK: Solo — hide every other app
    //
    // Uses NSRunningApplication.hide() rather than synthesising ⌘⌥H through System Events:
    // synthetic keystrokes land on whatever is frontmost, which is a good way to type into
    // somebody's editor. This asks each app directly.
    // NSApplication.hideOtherApplications is the same path ⌘⌥H takes, and it works where
    // per-app NSRunningApplication.hide() silently returned false for every app (measured:
    // "hid 0 app(s)"). unhideAllApplications is its counterpart.
    var isSolo = false

    @objc func toggleSolo(_ s: Any?) {
        if isSolo {
            NSApp.unhideAllApplications(nil)
            isSolo = false
            log("solo off — other apps restored")
        } else {
            NSApp.hideOtherApplications(nil)
            isSolo = true
            log("solo on — only the mirror is on screen; Space again to restore")
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    func parseArgs() {
        let args = Array(CommandLine.arguments.dropFirst())
        var i = 0
        while i < args.count {
            switch args[i] {
            case "--rotate", "-r":
                if i + 1 < args.count {
                    if args[i+1] == "auto" { autoRotate = true }
                    else { autoRotate = false; rotation = CGFloat(Int(args[i+1]) ?? 90) }
                    i += 1
                }
            case "--crop":
                if i + 1 < args.count {
                    if args[i+1] == "auto" { autoCrop = true }
                    else if args[i+1] == "none" || args[i+1] == "off" {
                        autoCrop = false; crop = CGRect(x: 0, y: 0, width: 1, height: 1)
                    } else {
                        let p = args[i+1].split(separator: ",").compactMap { Double($0) }
                        if p.count == 4 { autoCrop = false; crop = CGRect(x: p[0], y: p[1], width: p[2], height: p[3]) }
                    }
                    i += 1
                }
            case "--no-crop":   autoCrop = false; crop = CGRect(x: 0, y: 0, width: 1, height: 1)
            case "--no-auto":   autoCrop = false; autoRotate = false
            case "--device", "-d": if i + 1 < args.count { deviceMatch = args[i+1]; i += 1 }
            case "--mirror":     mirrored = true
            case "--borderless": borderless = true
            case "--width", "-w": if i + 1 < args.count { startWidth = CGFloat(Double(args[i+1]) ?? 0); i += 1 }
            case "--wait":
                if i + 1 < args.count, let n = Double(args[i+1]) { waitSeconds = n; i += 1 }
                else { waitSeconds = 86_400 }
            case "--list":
                Thread.sleep(forTimeInterval: 1.5)
                for d in captureDevices() { print("\(d.localizedName)  [\(d.uniqueID)]") }
                NSApp.terminate(nil)
            case "--help", "-h": printUsage(); NSApp.terminate(nil)
            default: break
            }
            i += 1
        }
        rotation = norm(rotation)
    }

    func log(_ s: String) {
        FileHandle.standardError.write(("PhoneMirror: " + s + "\n").data(using: .utf8)!)
    }

    func failNoDevice() {
        fail("""
             No iOS device found as a capture source.

             Looked for \(deviceMatch.map { "a device matching \"\($0)\"" } ?? "an iPhone/iPad/iPod") \
             for \(Int(waitSeconds))s after enabling CoreMediaIO screen-capture devices.

             Available now:
             \(captureDevices().map { "  • " + $0.localizedName }.joined(separator: "\n"))

             Checks, in order:
              1. iOS screen-capture devices are SINGLE-CLIENT. Close QuickTime's Movie Recording
                 window — while it owns the phone, nothing else can see it.
              2. Is the phone even on the bus?
                   ioreg -rc IOUSBHostDevice -w0 -l | grep -c '"idVendor" = 1452'
              3. If it is present but absent here, it is a PAIRING problem, not this app:
                   log show --last 5m --predicate 'subsystem == "com.apple.mobiledevice"' \\
                     --style compact | grep -iE 'iOSScreenCapture|pair'
                 Unlock the phone, replug, tap Trust.

             `phonemirror --wait` keeps looking, so you can launch first and plug in after.
             """)
    }

    func fail(_ msg: String) {
        FileHandle.standardError.write((msg + "\n").data(using: .utf8)!)
        let a = NSAlert(); a.alertStyle = .warning
        a.messageText = "PhoneMirror: no iOS screen source"
        a.informativeText = msg
        a.runModal()
        NSApp.terminate(nil)
    }

    func printUsage() {
        print("""
            PhoneMirror — live mirror of a USB iPhone/iPad screen, auto-oriented, auto-cropped.

              phonemirror                    just works: Vision OCR picks the rotation and
                                             crops iOS Camera.app's controls out of the shot

              --rotate, -r auto|<deg>  default auto (0/90/180/270 clockwise)
              --crop auto|none|x,y,w,h default auto; x,y,w,h normalized 0…1, origin top-left
              --no-crop                show the phone's whole screen, chrome and all
              --no-auto                no Vision pass at all
              --device, -d <str>       capture-device name substring
              --mirror                 flip horizontally
              --borderless             no title bar — cleanest for screen recording
              --width, -w <px>         initial window width (default 900)
              --wait [secs]            keep looking for the device (bare --wait = forever)
              --list                   list capture devices (iOS unhidden) and exit

            Live: ⇧⌘L / ⇧⌘R rotate · ⇧⌘H flip · ⌘D re-detect · ⌘0 uncropped
                  ⌘[ / ⌘] nudge the crop · ⌘F full screen

            One-shot recording of everything on one screen:
              phonemirror --borderless &
              recburn --system-audio --fps 60 -o dosbox-vs-schism.mov
            """)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ a: NSApplication) -> Bool { true }
}

// Top-level code is only legal in main.swift, and this target has two files (the shared
// SupportHelp), so the entry point is an explicit @main with -parse-as-library.
@main
struct PhoneMirrorMain {
    // Held statically so the delegate outlives main() — NSApplication does not retain it.
    static let delegate = AppDelegate()

    static func main() {
        let app = NSApplication.shared
        app.delegate = delegate
        app.setActivationPolicy(.regular)
        app.run()
    }
}
