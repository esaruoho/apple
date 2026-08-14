// iPhoneMirror — live, auto-oriented, auto-cropped mirrors of USB iPhone/iPad screens.
//
// Run it bare:  iphonemirror
//
// MULTI-DEVICE: every connected iOS device gets its OWN window, with its own orientation, crop
// and remembered calibration. Plug another phone in while it is running and a window appears for
// it. Two or three phones side by side is the point — one Mac screen, several devices, one take.
//
// Each window works out its own settings by CONTINUOUSLY LOOKING at the feed with Vision OCR
// (throttled, and only when the picture actually changes), so switching the phone to Camera.app
// re-crops by itself:
//   • which rotation makes text upright  → so a landscape-held phone whose iOS UI is stuck in
//     portrait comes out landscape, with no flags
//   • where iOS Camera.app's chrome is   → the mode wheel (PHOTO / VIDEO / SLO-MO / PORTRAIT /
//     SQUARE …) is found by name, and the 4:3 viewfinder is kept
//
// Why this app exists: QuickTime Player can mirror a Lightning-connected iOS device, but its
// Edit ▸ Rotate Left/Right/Flip items are DISABLED during a live capture session and its
// scripting dictionary has no rotate terminology — so a live feed cannot be un-rotated. This
// rotates the preview layer instead: the window is already correct, and a one-shot screen
// recording (RecBurn etc.) captures it right way up. No record-then-edit step.
//
// Apple-native: AppKit + AVFoundation + CoreMediaIO + Vision. xcrun swiftc. No Homebrew.
//
// FEATURE-CARD >> features/iphonemirror-rotated-live-mirror.feature

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

// MARK: - Device discovery

func captureDevices() -> [AVCaptureDevice] {
    var seen = Set<String>(); var out: [AVCaptureDevice] = []
    for mt in [AVMediaType.video, .muxed] {
        for d in AVCaptureDevice.devices(for: mt) where !seen.contains(d.uniqueID) {
            seen.insert(d.uniqueID); out.append(d)
        }
    }
    return out
}

/// A Continuity Camera is a genuine camera feed (A12+ device), not a screen mirror. It needs no
/// rotation and no chrome crop, so it is classified separately and never auto-opened — otherwise
/// an iPhone 16 Pro would produce TWO windows, since it publishes both kinds.
func isContinuityCamera(_ d: AVCaptureDevice) -> Bool {
    if #available(macOS 14.0, *), d.deviceType == .continuityCamera { return true }
    return d.localizedName.hasSuffix(" Camera") && looksLikeIOSName(d.localizedName)
}

func looksLikeIOSName(_ n: String) -> Bool {
    let l = n.lowercased()
    return l.contains("iphone") || l.contains("ipad") || l.contains("ipod")
}

/// The iOS SCREEN mirrors — what this app is for.
///
/// SORTED BY NAME, always. AVCaptureDevice enumeration order is not stable, so an unsorted list
/// makes menu items swap slots — a device you just ticked jumps from the 2nd row to the 1st, and
/// you end up clicking the wrong phone. Deterministic order is a correctness requirement for a
/// menu, not a nicety.
func iosScreenDevices() -> [AVCaptureDevice] {
    captureDevices()
        .filter { looksLikeIOSName($0.localizedName) && !isContinuityCamera($0) }
        .sorted { $0.localizedName.localizedStandardCompare($1.localizedName) == .orderedAscending }
}

func iosContinuityDevices() -> [AVCaptureDevice] {
    captureDevices()
        .filter { isContinuityCamera($0) }
        .sorted { $0.localizedName.localizedStandardCompare($1.localizedName) == .orderedAscending }
}

// MARK: - Grab one frame

/// Hands frames to a callback, throttled.
///
/// Detection must be CONTINUOUS, not one-shot. A one-shot first-frame pass looked fine in testing
/// and was wrong in use: tick a device while the phone shows the home screen and it detects "no
/// Camera chrome, no crop" — then you open Camera.app and nothing re-evaluates, so the crop just
/// never happens. The phone's screen is a live thing; the analysis has to keep up with it.
///
/// It must also never block the main thread: waiting on a semaphore in
/// applicationDidFinishLaunching starves the CoreMediaIO plugin and no frame ever arrives
/// (measured: 0 frames in 5s).
final class FrameWatcher: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    var onFrame: ((CGImage) -> Void)?
    /// Minimum gap between delivered frames. Vision runs four OCR passes per analysis, so this is
    /// the CPU governor — do not lower it casually.
    var minInterval: TimeInterval = 1.2
    private var lastDelivered = Date.distantPast
    private let ciContext = CIContext()
    let queue: DispatchQueue

    init(label: String) {
        self.queue = DispatchQueue(label: "org.esaruoho.iphonemirror.frames.\(label)")
        super.init()
    }

    /// Force the next frame through, ignoring the throttle (⌘D re-detect).
    func arm() { lastDelivered = .distantPast }

    func captureOutput(_ out: AVCaptureOutput, didOutput sample: CMSampleBuffer,
                       from conn: AVCaptureConnection) {
        let now = Date()
        guard now.timeIntervalSince(lastDelivered) >= minInterval else { return }
        // The pixel buffer is only valid inside this callback, so convert here and now.
        guard let pb = CMSampleBufferGetImageBuffer(sample) else { return }
        let ci = CIImage(cvPixelBuffer: pb)
        guard let cg = ciContext.createCGImage(ci, from: ci.extent) else { return }
        lastDelivered = now
        DispatchQueue.main.async { [weak self] in self?.onFrame?(cg) }
    }
}

/// A tiny grayscale thumbnail used to tell "the screen changed" from "same picture, new frame",
/// so Vision only runs when there is something new to read.
func frameSignature(_ img: CGImage, side: Int = 16) -> [UInt8] {
    var buf = [UInt8](repeating: 0, count: side * side)
    guard let cs = CGColorSpace(name: CGColorSpace.linearGray),
          let ctx = CGContext(data: &buf, width: side, height: side, bitsPerComponent: 8,
                              bytesPerRow: side, space: cs,
                              bitmapInfo: CGImageAlphaInfo.none.rawValue) else { return buf }
    ctx.draw(img, in: CGRect(x: 0, y: 0, width: side, height: side))
    return buf
}

/// Mean absolute difference between two signatures, 0…255.
func signatureDelta(_ a: [UInt8], _ b: [UInt8]) -> Double {
    guard a.count == b.count, !a.isEmpty else { return 255 }
    var total = 0
    for i in 0..<a.count { total += abs(Int(a[i]) - Int(b[i])) }
    return Double(total) / Double(a.count)
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

// MARK: - Crop: pure geometry
//
// NEVER crop by luminance. Four brightness-based approaches were measured and every one failed,
// because the SUBJECT can itself be black (a DOS CRT) and no brightness test can separate "black
// control band" from "black subject":
//   1. MEAN luminance          — white glyphs lift a black band's mean above any threshold
//   2. RELATIVE/max threshold  — one overexposed window dominated max → 0.156-wide sliver
//   3. MEDIAN luminance        — ate the middle of the feed (w=0.523), clipping the prompt
//   4. Sliding a 4:3 window to maximise contained image — picked the chrome band, because its
//      white shutter circle and colour thumbnail outweigh a dark subject
// Geometry is content-independent: the viewfinder spans the full short edge, PHOTO mode is 4:3,
// and the mode wheel is located BY NAME via OCR.
func detectCrop(sourceFrame: CGImage, chromeBoxesSource: [CGRect]) -> CGRect {
    let full = CGRect(x: 0, y: 0, width: 1, height: 1)
    guard !chromeBoxesSource.isEmpty else { return full }

    let w = CGFloat(sourceFrame.width), h = CGFloat(sourceFrame.height)
    guard w > 0, h > 0 else { return full }
    let shortEdge = min(w, h), longEdge = max(w, h)
    let viewfinderFrac = min(1.0, (4.0 / 3.0) * (shortEdge / longEdge))

    // MEASURED gap between the top of the mode-wheel TEXT and the edge of the 4:3 preview.
    // Bracketed empirically: 0.012 left a black bar on the far side only; 0.062 pulled the icon
    // strip in on the near side. ⌘[ / ⌘] nudge it live if a device disagrees.
    let gapToPreview: CGFloat = 0.040

    let meanY = chromeBoxesSource.map { $0.midY }.reduce(0, +) / CGFloat(chromeBoxesSource.count)
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

// MARK: - Defaults shared by every new window

struct MirrorOptions {
    var autoRotate = true
    var autoCrop = true
    var rotation: CGFloat = 90
    var crop = CGRect(x: 0, y: 0, width: 1, height: 1)
    var mirrored = false
    var borderless = false
    var width: CGFloat = 900
}

// MARK: - Mirror — ONE window per device
//
// Everything device-specific lives here rather than on the app delegate, which is what makes two
// or three phones possible: separate session, separate detection, separate rotation/crop, and
// separate persisted calibration keyed by the device's uniqueID.
final class Mirror: NSObject, NSWindowDelegate {
    let device: AVCaptureDevice
    let session = AVCaptureSession()
    let detectorOutput = AVCaptureVideoDataOutput()
    let watcher: FrameWatcher
    var window: NSWindow!
    var preview: PreviewView!

    var rotation: CGFloat
    var crop: CGRect
    var mirrored: Bool
    var autoRotate: Bool
    var autoCrop: Bool
    var srcAspect: CGFloat = 1125.0 / 2436.0
    weak var owner: AppDelegate?
    /// Hand adjustments win over continuous detection until ⌘D re-detect.
    var manualOverride = false
    var analysing = false
    var lastSignature: [UInt8] = []

    init?(device: AVCaptureDevice, options: MirrorOptions, owner: AppDelegate) {
        self.device = device
        self.owner = owner
        self.watcher = FrameWatcher(label: device.uniqueID)
        self.mirrored = options.mirrored
        self.autoRotate = options.autoRotate
        self.autoCrop = options.autoCrop
        // A saved calibration for THIS device wins over auto-detection, so a phone you have
        // already dialled in comes back correct instead of being re-guessed every launch.
        // A saved calibration SEEDS the window so it opens at roughly the right shape — it does NOT
        // suppress detection. Suppressing it was wrong: a phone whose saved value was captured while
        // it showed the home screen came back portrait and stayed portrait even with Camera.app
        // open, which reads as "the app doesn't work". Vision always gets to correct the seed.
        let saved = Mirror.loadCalibration(uniqueID: device.uniqueID)
        self.rotation = saved?.rotation ?? options.rotation
        self.crop = saved?.crop ?? options.crop
        // A Continuity Camera is already a clean, upright, landscape camera feed — there is no
        // Camera.app chrome to crop and nothing to rotate. Running Vision on it is pure harm:
        // it OCRs whatever the lens happens to see and flip-flops the orientation.
        if isContinuityCamera(device) {
            self.autoRotate = false; self.autoCrop = false
            self.rotation = 0
            self.crop = CGRect(x: 0, y: 0, width: 1, height: 1)
        }
        super.init()

        guard let input = try? AVCaptureDeviceInput(device: device), session.canAddInput(input) else {
            // Single-client device: another app (QuickTime, or another iPhoneMirror) holds it.
            // Skip THIS device rather than failing the whole app — the other phones still work.
            owner.log("\(device.localizedName): could not open (single-client — QuickTime or another app holds it)")
            return nil
        }
        session.addInput(input)

        if let f = device.formats.last {
            let d = CMVideoFormatDescriptionGetDimensions(f.formatDescription)
            if d.width > 0 && d.height > 0 { srcAspect = CGFloat(d.width) / CGFloat(d.height) }
        }

        buildWindow(options: options)
        if autoRotate || autoCrop { attachDetector() }
        session.startRunning()
        if saved != nil {
            owner.log("\(device.localizedName): seeded from saved calibration (Vision will still re-check) "
                    + String(format: "rot=%d crop=%.3f,%.3f,%.3f,%.3f", Int(rotation),
                             crop.origin.x, crop.origin.y, crop.width, crop.height))
        }
    }

    // MARK: window

    func buildWindow(options: MirrorOptions) {
        let outAspect = currentAspect()
        let w = options.width
        let h = (w / outAspect).rounded()
        preview = PreviewView(session: session, rotation: rotation, mirrored: mirrored, crop: crop)
        let style: NSWindow.StyleMask = options.borderless
            ? [.borderless, .resizable] : [.titled, .closable, .miniaturizable, .resizable]
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: w, height: h),
                          styleMask: style, backing: .buffered, defer: false)
        window.title = titleText()
        window.contentView = preview
        window.contentAspectRatio = NSSize(width: outAspect, height: 1)
        window.isMovableByWindowBackground = true
        window.collectionBehavior.insert(.fullScreenPrimary)
        // A programmatically-created NSWindow defaults to isReleasedWhenClosed = true, which under
        // ARC double-releases: AppKit releases it on close AND ARC releases our strong reference.
        // Measured crash: EXC_BAD_ACCESS in objc_release during objc_autoreleasePoolPop, straight
        // after unticking a device. Must be false whenever you hold the window in a property.
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.makeKeyAndOrderFront(nil)
    }

    func titleText() -> String {
        let kind = isContinuityCamera(device) ? "camera" : "screen"
        return "\(device.localizedName) — \(kind) @ \(Int(rotation))°"
    }

    func currentAspect() -> CGFloat {
        let quarterTurn = Int(rotation) % 180 != 0
        let rotA = quarterTurn ? (1.0 / srcAspect) : srcAspect
        return rotA * (crop.width / max(crop.height, 0.01))
    }

    func refit() {
        let aspect = currentAspect()
        window.contentAspectRatio = NSSize(width: aspect, height: 1)
        var f = window.frame
        let chrome = window.frame.height - window.contentLayoutRect.height
        f.size.height = (f.size.width / aspect).rounded() + chrome
        window.setFrame(f, display: true, animate: false)
        window.title = titleText()
    }

    func windowWillClose(_ n: Notification) {
        // Tear the capture graph down explicitly; leaving the DAL device open would keep this
        // single-client phone unavailable to anything else.
        detectorOutput.setSampleBufferDelegate(nil, queue: nil)
        watcher.onFrame = nil
        session.stopRunning()
        window.delegate = nil
        owner?.mirrorClosed(self)
    }

    // MARK: detection

    func attachDetector() {
        guard session.canAddOutput(detectorOutput) else { return }
        detectorOutput.alwaysDiscardsLateVideoFrames = true
        session.addOutput(detectorOutput)
        watcher.onFrame = { [weak self] frame in self?.inspect(frame) }
        watcher.arm()
        detectorOutput.setSampleBufferDelegate(watcher, queue: watcher.queue)
    }

    /// Vision runs off-main (four OCR passes), then the result is applied on main.
    ///
    /// Gated three ways so continuous analysis stays cheap and never fights the user:
    ///   • manualOverride — once you rotate/nudge/uncrop by hand, your choice stands (⌘D resumes)
    ///   • signature — skip frames that look like the last analysed one (nothing new to read)
    ///   • busy — never overlap two Vision passes
    func inspect(_ frame: CGImage) {
        guard !manualOverride else { return }
        guard !analysing else { return }
        let sig = frameSignature(frame)
        if signatureDelta(sig, lastSignature) < 6.0 { return }
        lastSignature = sig
        analysing = true

        let wantRotate = autoRotate, wantCrop = autoCrop
        let name = device.localizedName
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
                self.analysing = false
                let changed = (wantRotate && self.rotation != rot)
                           || (wantCrop && self.crop != newCrop)
                guard changed else { return }
                if wantRotate {
                    self.rotation = rot
                    self.owner?.log("\(name): orientation \(Int(rot))° — \(det.basis)"
                        + (det.words.isEmpty ? "" : " [\(det.words.prefix(6).joined(separator: ", "))]"))
                }
                if wantCrop {
                    self.crop = newCrop
                    self.owner?.log(name + String(format: ": crop x=%.3f y=%.3f w=%.3f h=%.3f",
                                                  newCrop.origin.x, newCrop.origin.y,
                                                  newCrop.width, newCrop.height))
                }
                self.preview.rotation = self.rotation
                self.preview.crop = self.crop
                self.refit()
                self.saveCalibration()
            }
        }
    }

    func redetect() {
        autoRotate = true; autoCrop = true
        manualOverride = false
        lastSignature = []                 // force the next frame to be analysed
        owner?.log("\(device.localizedName): automatic detection resumed")
        watcher.arm()
    }

    // MARK: live adjustments

    func rotateBy(_ d: CGFloat) {
        manualOverride = true
        rotation = CGFloat(((Int(rotation + d) % 360) + 360) % 360)
        preview.rotation = rotation
        refit(); saveCalibration()
    }
    func toggleMirror() { manualOverride = true; mirrored.toggle(); preview.mirrored = mirrored; saveCalibration() }
    func resetCrop() {
        manualOverride = true
        crop = CGRect(x: 0, y: 0, width: 1, height: 1)
        autoCrop = false
        preview.crop = crop; refit(); saveCalibration()
    }
    func slideCrop(_ d: CGFloat) {
        manualOverride = true
        if crop.width < 0.999 {
            crop.origin.x = max(0, min(1 - crop.width, crop.origin.x + d))
        } else if crop.height < 0.999 {
            crop.origin.y = max(0, min(1 - crop.height, crop.origin.y + d))
        }
        preview.crop = crop
        saveCalibration()
        owner?.log(device.localizedName + String(format: ": crop nudged → x=%.3f y=%.3f w=%.3f h=%.3f",
                                                 crop.origin.x, crop.origin.y, crop.width, crop.height))
    }

    // MARK: per-device persistence

    struct Calibration { var rotation: CGFloat; var crop: CGRect }

    static func key(_ uid: String) -> String { "calib.\(uid)" }

    func saveCalibration() {
        let v: [Double] = [Double(rotation), crop.origin.x, crop.origin.y, crop.width, crop.height,
                           mirrored ? 1 : 0]
        UserDefaults.standard.set(v, forKey: Mirror.key(device.uniqueID))
    }

    static func loadCalibration(uniqueID: String) -> Calibration? {
        guard let v = UserDefaults.standard.array(forKey: key(uniqueID)) as? [Double], v.count >= 5
        else { return nil }
        return Calibration(rotation: CGFloat(v[0]),
                           crop: CGRect(x: v[1], y: v[2], width: v[3], height: v[4]))
    }

    static func forgetCalibration(uniqueID: String) {
        UserDefaults.standard.removeObject(forKey: key(uniqueID))
    }
}

// MARK: - App

final class AppDelegate: NSObject, NSApplicationDelegate {
    var mirrors: [Mirror] = []
    var options = MirrorOptions()
    var deviceMatch: String? = nil
    var waitSeconds: TimeInterval = 20
    var autoOpenNew = false
    var openAllAtLaunch = false
    var includeContinuity = false
    var pollTimer: Timer?
    var knownIDs = Set<String>()
    var windowOffset: CGFloat = 0

    func applicationDidFinishLaunching(_ note: Notification) {
        allowScreenCaptureDevices()
        parseArgs()
        loadRoster()
        buildMenu()

        openInitialDevices()

        // POLLING rather than AVCaptureDevice connect/disconnect notifications: DAL screen-capture
        // devices are published by an out-of-process assistant and do not reliably post those, and
        // enumeration is cheap. 3s is fast enough that plugging a phone in feels immediate.
        pollTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            self?.rescanDevices()
        }

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

        NotificationCenter.default.addObserver(forName: .showAppHelp, object: nil, queue: .main) {
            [weak self] _ in self?.showHelp(nil)
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: opening devices

    func candidateDevices() -> [AVCaptureDevice] {
        var list = iosScreenDevices()
        if includeContinuity { list += iosContinuityDevices() }
        if let m = deviceMatch?.lowercased(), !m.isEmpty {
            list = list.filter { $0.localizedName.lowercased().contains(m) }
        }
        return list
    }

    /// Menu-driven by default: nothing opens by itself. The Devices menu lists every phone and a
    /// click ticks it on. --all (or --device X) opens immediately instead, for scripted use.
    func openInitialDevices() {
        let wantImmediate = openAllAtLaunch || (deviceMatch != nil)
        let deadline = Date().addingTimeInterval(wantImmediate ? waitSeconds : 6)
        var found = candidateDevices()
        while found.isEmpty && Date() < deadline {
            RunLoop.current.run(until: Date().addingTimeInterval(0.25))
            found = candidateDevices()
        }
        for d in found { knownIDs.insert(d.uniqueID) }
        rebuildDevicesMenu()

        if wantImmediate {
            guard !found.isEmpty else { failNoDevice(); return }
            for d in found { open(d) }
            rebuildDevicesMenu()
            return
        }
        if found.isEmpty {
            log("no iOS devices yet — plug one in; the Devices menu updates every 3s")
        } else {
            log("ready: " + found.map { $0.localizedName }.joined(separator: ", ")
                + "  —  tick one in the Devices menu to show it")
        }
    }

    @discardableResult
    func open(_ d: AVCaptureDevice) -> Bool {
        if let existing = mirrors.first(where: { $0.device.uniqueID == d.uniqueID }) {
            existing.window.makeKeyAndOrderFront(nil)
            return true
        }
        guard let m = Mirror(device: d, options: options, owner: self) else { return false }
        // Cascade, so two or three phones do not stack exactly on top of each other.
        m.window.center()
        var f = m.window.frame
        f.origin.x += windowOffset; f.origin.y -= windowOffset
        m.window.setFrame(f, display: true)
        windowOffset += 32
        mirrors.append(m)
        knownIDs.insert(d.uniqueID)
        log("\(d.localizedName): window open (\(mirrors.count) mirror(s) now)")
        return true
    }

    func mirrorClosed(_ m: Mirror) {
        // Dropping the array's reference here would deallocate the Mirror while we are still
        // inside its own windowWillClose. Defer to the next turn of the run loop so the callback
        // finishes on a live object.
        let name = m.device.localizedName
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.mirrors.removeAll { $0 === m }
            self.rebuildDevicesMenu()
            self.log("\(name): window closed (\(self.mirrors.count) left)")
        }
    }

    /// Notice phones plugged in or pulled out while running.
    func rescanDevices() {
        // RE-ASSERT the CMIO flag every scan. iOSScreenCaptureAssistant EXITS when no screen-capture
        // device is in use — e.g. while you are watching a Continuity Camera — and once it is gone,
        // plain enumeration will not bring it back, so every iPhone silently reads "(not connected)"
        // and cannot be ticked on. Setting the property is what respawns the assistant.
        allowScreenCaptureDevices()
        let now = candidateDevices()
        let nowIDs = Set(now.map { $0.uniqueID })

        for d in now where !knownIDs.contains(d.uniqueID) {
            knownIDs.insert(d.uniqueID)
            log("\(d.localizedName): appeared")
            if autoOpenNew { open(d) }
        }
        // Close windows whose device went away, so a yanked cable does not leave a dead frame.
        for m in mirrors where !nowIDs.contains(m.device.uniqueID) {
            log("\(m.device.localizedName): disconnected — closing its window")
            m.window.close()
        }
        noteInRoster(now)
        knownIDs.formIntersection(nowIDs.union(Set(mirrors.map { $0.device.uniqueID })))
        rebuildDevicesMenu()
    }

    // MARK: routing keys to the FRONT window

    var front: Mirror? {
        if let w = NSApp.keyWindow, let m = mirrors.first(where: { $0.window === w }) { return m }
        return mirrors.last
    }

    @objc func rotateLeft(_ s: Any?)  { front?.rotateBy(-90) }
    @objc func rotateRight(_ s: Any?) { front?.rotateBy(+90) }
    @objc func toggleMirrorAction(_ s: Any?) { front?.toggleMirror() }
    @objc func resetCropAction(_ s: Any?) { front?.resetCrop() }
    @objc func nudgeCropBack(_ s: Any?) { front?.slideCrop(-0.01) }
    @objc func nudgeCropFwd(_ s: Any?)  { front?.slideCrop(+0.01) }
    @objc func redetect(_ s: Any?) { front?.redetect() }
    @objc func forgetCalibration(_ s: Any?) {
        guard let m = front else { return }
        Mirror.forgetCalibration(uniqueID: m.device.uniqueID)
        log("\(m.device.localizedName): saved calibration forgotten — re-detecting")
        m.redetect()
    }
    @objc func openAllDevices(_ s: Any?) {
        for d in candidateDevices() { open(d) }
        rebuildDevicesMenu()
    }
    /// Tick = window open, untick = window closed. One menu, one click per phone.
    @objc func toggleDeviceFromMenu(_ sender: NSMenuItem) {
        guard let uid = sender.representedObject as? String else { return }
        if let m = mirrors.first(where: { $0.device.uniqueID == uid }) {
            m.window.close()                       // windowWillClose tidies up and rebuilds
            return
        }
        guard let d = captureDevices().first(where: { $0.uniqueID == uid }) else {
            log("that device is gone — rescanning")
            rescanDevices(); return
        }
        open(d)
        rebuildDevicesMenu()
    }

    @objc func rescanNow(_ s: Any?) {
        log("rescanning for iOS devices…")
        rescanDevices()
        let screens = iosScreenDevices(), cams = iosContinuityDevices()
        log("found \(screens.count) screen mirror(s), \(cams.count) Continuity Camera(s)")
    }

    // MARK: menus

    var devicesMenu = NSMenu(title: "Devices")

    func buildMenu() {
        let main = NSMenu()

        let appItem = NSMenuItem(); let appMenu = NSMenu()
        let aboutItem = NSMenuItem(title: "About iPhoneMirror — and how to support Esa",
                                   action: #selector(showHelp(_:)), keyEquivalent: "")
        aboutItem.target = self
        appMenu.addItem(aboutItem)
        appMenu.addItem(.separator())
        let soloApp = NSMenuItem(title: "Hide All Other Apps", action: #selector(toggleSolo(_:)), keyEquivalent: "")
        soloApp.target = self
        appMenu.addItem(soloApp)
        appMenu.addItem(withTitle: "Hide iPhoneMirror", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Quit iPhoneMirror", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
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
        add("Flip Horizontal", #selector(toggleMirrorAction(_:)), "H")
        v.addItem(.separator())
        add("Re-detect (Vision)", #selector(redetect(_:)), "d")
        add("Show Whole Screen (no crop)", #selector(resetCropAction(_:)), "0")
        add("Nudge Crop ←", #selector(nudgeCropBack(_:)), "[")
        add("Nudge Crop →", #selector(nudgeCropFwd(_:)), "]")
        add("Forget Saved Calibration for This Device", #selector(forgetCalibration(_:)), "")
        v.addItem(.separator())
        let solo = NSMenuItem(title: "Hide All Other Apps  (Space)", action: #selector(toggleSolo(_:)), keyEquivalent: "")
        solo.target = self
        v.addItem(solo)
        v.addItem(withTitle: "Enter Full Screen", action: #selector(NSWindow.toggleFullScreen(_:)), keyEquivalent: "f")
        vItem.submenu = v; main.addItem(vItem)

        // Devices menu — every connected iOS device, so a second or third phone is one click away.
        let dItem = NSMenuItem(title: "Devices", action: nil, keyEquivalent: "")
        dItem.submenu = devicesMenu
        main.addItem(dItem)

        let hItem = NSMenuItem(title: "Help", action: nil, keyEquivalent: "")
        let h = NSMenu(title: "Help")
        let hi = NSMenuItem(title: "iPhoneMirror Help", action: #selector(showHelp(_:)), keyEquivalent: "?")
        hi.target = self
        h.addItem(hi)
        hItem.submenu = h; main.addItem(hItem)

        NSApp.mainMenu = main
        NSApp.helpMenu = h
        rebuildDevicesMenu()
    }

    /// Every device ever seen, so entries do not VANISH from the menu.
    ///
    /// A Continuity Camera in particular comes and goes with the phone's proximity, wake state and
    /// whether another app is using it — so a menu built only from "what enumerates right now"
    /// loses the row while you are reaching for it. Remembered rows stay put, greyed, labelled
    /// "not connected". uniqueID → (display name, is it a Continuity Camera).
    struct RosterEntry { var name: String; var isCam: Bool }
    var roster: [String: RosterEntry] = [:]

    static let rosterKey = "deviceRoster"

    func loadRoster() {
        guard let raw = UserDefaults.standard.dictionary(forKey: AppDelegate.rosterKey) else { return }
        for (uid, v) in raw {
            guard let d = v as? [String: Any], let n = d["name"] as? String else { continue }
            roster[uid] = RosterEntry(name: n, isCam: (d["isCam"] as? Bool) ?? false)
        }
    }

    func saveRoster() {
        var out: [String: Any] = [:]
        for (uid, e) in roster { out[uid] = ["name": e.name, "isCam": e.isCam] }
        UserDefaults.standard.set(out, forKey: AppDelegate.rosterKey)
    }

    func noteInRoster(_ devices: [AVCaptureDevice]) {
        for d in devices {
            roster[d.uniqueID] = RosterEntry(name: d.localizedName, isCam: isContinuityCamera(d))
        }
        saveRoster()
    }

    func rebuildDevicesMenu() {
        devicesMenu.removeAllItems()
        let openIDs = Set(mirrors.map { $0.device.uniqueID })
        let present = Set(captureDevices().map { $0.uniqueID })

        noteInRoster(iosScreenDevices() + iosContinuityDevices())

        // Sorted by name so rows never swap slots between rebuilds.
        let rows = roster.map { (uid: $0.key, entry: $0.value) }
            .sorted { $0.entry.name.localizedStandardCompare($1.entry.name) == .orderedAscending }
        let screens = rows.filter { !$0.entry.isCam }
        let cams = rows.filter { $0.entry.isCam }

        if rows.isEmpty {
            let none = NSMenuItem(title: "No iOS devices seen yet", action: nil, keyEquivalent: "")
            none.isEnabled = false
            devicesMenu.addItem(none)
        }

        if !screens.isEmpty {
            let hdr = NSMenuItem(title: "Screen mirrors", action: nil, keyEquivalent: "")
            hdr.isEnabled = false
            devicesMenu.addItem(hdr)
            for r in screens {
                devicesMenu.addItem(rosterItem(uid: r.uid, entry: r.entry,
                                               isOpen: openIDs.contains(r.uid),
                                               isPresent: present.contains(r.uid)))
            }
        }
        if !cams.isEmpty {
            devicesMenu.addItem(.separator())
            // Continuity Camera is a clean camera feed with no chrome and no rotation problem —
            // strictly better than mirroring Camera.app, on any A12-or-later device.
            let hdr = NSMenuItem(title: "Continuity Cameras (clean feed, no chrome)",
                                 action: nil, keyEquivalent: "")
            hdr.isEnabled = false
            devicesMenu.addItem(hdr)
            for r in cams {
                devicesMenu.addItem(rosterItem(uid: r.uid, entry: r.entry,
                                               isOpen: openIDs.contains(r.uid),
                                               isPresent: present.contains(r.uid)))
            }
        }

        devicesMenu.addItem(.separator())
        let all = NSMenuItem(title: "Show All iOS Devices", action: #selector(openAllDevices(_:)), keyEquivalent: "")
        all.target = self
        devicesMenu.addItem(all)
        let rescan = NSMenuItem(title: "Rescan for Devices", action: #selector(rescanNow(_:)), keyEquivalent: "r")
        rescan.target = self
        devicesMenu.addItem(rescan)
        let forget = NSMenuItem(title: "Forget Disconnected Devices", action: #selector(forgetRoster(_:)), keyEquivalent: "")
        forget.target = self
        devicesMenu.addItem(forget)
    }

    func rosterItem(uid: String, entry: RosterEntry, isOpen: Bool, isPresent: Bool) -> NSMenuItem {
        let label = isOpen ? "Showing " : "Show "
        let suffix = isPresent ? "" : "  (not connected)"
        let mi = NSMenuItem(title: "    " + label + entry.name + suffix,
                            action: #selector(toggleDeviceFromMenu(_:)), keyEquivalent: "")
        mi.target = self
        mi.representedObject = uid
        mi.state = isOpen ? .on : .off
        mi.isEnabled = true
        return mi
    }

    @objc func forgetRoster(_ s: Any?) {
        let keepOpen = Set(mirrors.map { $0.device.uniqueID })
        roster = roster.filter { pair in keepOpen.contains(pair.key) }
        noteInRoster(iosScreenDevices() + iosContinuityDevices())
        rebuildDevicesMenu()
        log("device list reset to what is connected now")
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
            appName: "iPhoneMirror",
            tagline: "Live mirrors of USB iPhone or iPad screens — one window per device, each "
                   + "rotated and cropped as you want it, so a one-shot screen recording needs no editing.",
            usage: [
                ("bolt", "Run it bare: every connected iPhone gets a window, oriented and cropped by Vision OCR"),
                ("iphone", "Devices menu lists every phone; plug one in and its window appears"),
                ("rotate.right", "⇧⌘L / ⇧⌘R rotate · ⇧⌘H flip — applies to the front window"),
                ("crop", "⌘[ / ⌘] nudge the crop · ⌘0 whole screen · ⌘D re-detect"),
                ("externaldrive", "Each device remembers its own calibration"),
                ("rectangle.on.rectangle", "Space hides every other app, so only the mirrors are on screen"),
                ("record.circle", "Pair with recburn --system-audio to film them beside anything else")
            ],
            note: "QuickTime Player cannot rotate a live device mirror — its Rotate and Flip items are "
                + "disabled during capture, and it holds one device exclusively. That is why this exists."
        )
        let host = NSHostingController(rootView: view)
        let w = NSWindow(contentViewController: host)
        w.title = "iPhoneMirror Help"
        w.styleMask = [.titled, .closable]
        w.setContentSize(NSSize(width: 460, height: 660))
        w.center()
        w.isReleasedWhenClosed = false
        helpWindow = w
        w.makeKeyAndOrderFront(nil)
    }

    // MARK: Solo — hide every other app
    //
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
            log("solo on — only the mirrors are on screen; Space again to restore")
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: args, logging, failure

    func parseArgs() {
        let args = Array(CommandLine.arguments.dropFirst())
        var i = 0
        while i < args.count {
            switch args[i] {
            case "--rotate", "-r":
                if i + 1 < args.count {
                    if args[i+1] == "auto" { options.autoRotate = true }
                    else { options.autoRotate = false; options.rotation = CGFloat(Int(args[i+1]) ?? 90) }
                    i += 1
                }
            case "--crop":
                if i + 1 < args.count {
                    if args[i+1] == "auto" { options.autoCrop = true }
                    else if args[i+1] == "none" || args[i+1] == "off" {
                        options.autoCrop = false; options.crop = CGRect(x: 0, y: 0, width: 1, height: 1)
                    } else {
                        let p = args[i+1].split(separator: ",").compactMap { Double($0) }
                        if p.count == 4 {
                            options.autoCrop = false
                            options.crop = CGRect(x: p[0], y: p[1], width: p[2], height: p[3])
                        }
                    }
                    i += 1
                }
            case "--no-crop": options.autoCrop = false; options.crop = CGRect(x: 0, y: 0, width: 1, height: 1)
            case "--no-auto": options.autoCrop = false; options.autoRotate = false
            case "--device", "-d": if i + 1 < args.count { deviceMatch = args[i+1]; i += 1 }
            case "--continuity": includeContinuity = true
            case "--all", "--open-all": openAllAtLaunch = true
            case "--auto-open": autoOpenNew = true
            case "--no-auto-open": autoOpenNew = false
            case "--mirror": options.mirrored = true
            case "--borderless": options.borderless = true
            case "--width", "-w":
                if i + 1 < args.count, let n = Double(args[i+1]) { options.width = CGFloat(n); i += 1 }
            case "--wait":
                if i + 1 < args.count, let n = Double(args[i+1]) { waitSeconds = n; i += 1 }
                else { waitSeconds = 86_400 }
            case "--list":
                Thread.sleep(forTimeInterval: 1.5)
                let screens = iosScreenDevices().map { $0.uniqueID }
                let cams = iosContinuityDevices().map { $0.uniqueID }
                for d in captureDevices() {
                    let tag = screens.contains(d.uniqueID) ? "  [iOS screen mirror]"
                            : cams.contains(d.uniqueID)    ? "  [Continuity Camera]" : ""
                    print("\(d.localizedName)  [\(d.uniqueID)]\(tag)")
                }
                NSApp.terminate(nil)
            case "--help", "-h": printUsage(); NSApp.terminate(nil)
            default: break
            }
            i += 1
        }
        options.rotation = CGFloat(((Int(options.rotation) % 360) + 360) % 360)
    }

    func log(_ s: String) {
        FileHandle.standardError.write(("iPhoneMirror: " + s + "\n").data(using: .utf8)!)
    }

    func failNoDevice() {
        let msg = """
             No iOS device found as a capture source.

             Looked for \(deviceMatch.map { "a device matching \"\($0)\"" } ?? "any iPhone/iPad/iPod") \
             for \(Int(waitSeconds))s after enabling CoreMediaIO screen-capture devices.

             Available now:
             \(captureDevices().map { "  • " + $0.localizedName }.joined(separator: "\n"))

             Checks, in order:
              1. iOS screen-capture devices are SINGLE-CLIENT. Close QuickTime's Movie Recording
                 window — while it owns a phone, nothing else can see it.
              2. Is the phone on the bus?
                   ioreg -rc IOUSBHostDevice -w0 -l | grep -c '"idVendor" = 1452'
              3. If present but absent here, it is a PAIRING problem, not this app:
                   log show --last 5m --predicate 'subsystem == "com.apple.mobiledevice"' \\
                     --style compact | grep -iE 'iOSScreenCapture|pair'
                 Unlock the phone, replug, tap Trust.

             `iphonemirror --wait` keeps looking, so you can launch first and plug in after.
             """
        FileHandle.standardError.write((msg + "\n").data(using: .utf8)!)
        let a = NSAlert(); a.alertStyle = .warning
        a.messageText = "iPhoneMirror: no iOS screen source"
        a.informativeText = msg
        a.runModal()
        NSApp.terminate(nil)
    }

    func printUsage() {
        print("""
            iPhoneMirror — live mirrors of USB iPhone/iPad screens, one window per device.

              iphonemirror                    every connected iPhone gets a window; Vision OCR
                                             picks each one's rotation and crops Camera.app's
                                             controls out. Plug another in and it appears.

              --device, -d <str>       only devices whose name contains this
              --continuity             also open Continuity Cameras (A12+; clean feed, no chrome)
              --no-auto-open           do not open windows for phones plugged in later
              --rotate, -r auto|<deg>  default auto (0/90/180/270 clockwise)
              --crop auto|none|x,y,w,h default auto; x,y,w,h normalized 0…1, origin top-left
              --no-crop                show each phone's whole screen, chrome and all
              --no-auto                no Vision pass at all
              --mirror                 flip horizontally
              --borderless             no title bars — cleanest for screen recording
              --width, -w <px>         initial window width (default 900)
              --wait [secs]            keep looking for a device (bare --wait = forever)
              --list                   list capture devices, tagged by kind, and exit

            Live (applies to the FRONT window):
              ⇧⌘L / ⇧⌘R rotate · ⇧⌘H flip · ⌘D re-detect · ⌘0 uncropped
              ⌘[ / ⌘] nudge the crop · ⌘F full screen · Space hides every other app

            Each device remembers its own rotation and crop, keyed by its uniqueID, so a phone you
            have dialled in comes back correct. View ▸ Forget Saved Calibration to re-detect.

            One-shot recording of two phones plus anything else on one screen:
              iphonemirror --borderless &
              recburn --system-audio --fps 60 -o dosbox-vs-schism.mov
            """)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ a: NSApplication) -> Bool { false }
}

// Top-level code is only legal in main.swift, and this target has two files (the shared
// SupportHelp), so the entry point is an explicit @main with -parse-as-library.
@main
struct iPhoneMirrorMain {
    // Held statically so the delegate outlives main() — NSApplication does not retain it.
    static let delegate = AppDelegate()

    static func main() {
        let app = NSApplication.shared
        app.delegate = delegate
        app.setActivationPolicy(.regular)
        app.run()
    }
}
