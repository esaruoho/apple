// iphone-screen — grab a still of a USB-tethered iPhone's SCREEN (the QuickTime
// "New Movie Recording → iPhone" mechanism) via CoreMediaIO + AVFoundation.
// Apple-native. Best-effort: the iOS screen device only appears when the phone
// is unlocked + trusted over USB; if absent, this exits non-zero cleanly.
//
//   iphone-screen <out.jpg> [--device <substr>] [--list] [--timeout S]
//
// The screen device is distinct from the Continuity Camera: it carries the
// phone's plain name (no " Camera"/" Desk View" suffix) and shows up only after
// kCMIOHardwarePropertyAllowScreenCaptureDevices is enabled.

import Foundation
import AVFoundation
import CoreMediaIO
import CoreImage
import ImageIO
import UniformTypeIdentifiers

func err(_ s: String) { FileHandle.standardError.write((s + "\n").data(using: .utf8)!) }

// Enable iOS screen-capture DAL devices.
var prop = CMIOObjectPropertyAddress(
    mSelector: CMIOObjectPropertySelector(kCMIOHardwarePropertyAllowScreenCaptureDevices),
    mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
    mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain))
var allow: UInt32 = 1
CMIOObjectSetPropertyData(CMIOObjectID(kCMIOObjectSystemObject), &prop, 0, nil,
                          UInt32(MemoryLayout<UInt32>.size), &allow)
Thread.sleep(forTimeInterval: 0.8)  // let the DAL plugin surface the device

var args = Array(CommandLine.arguments.dropFirst())
func popFlag(_ n: String) -> String? {
    guard let i = args.firstIndex(of: n), i + 1 < args.count else { return nil }
    let v = args[i + 1]; args.removeSubrange(i...(i+1)); return v
}
let listOnly = args.contains("--list"); args.removeAll { $0 == "--list" }
let deviceMatch = popFlag("--device")
let timeout = Double(popFlag("--timeout") ?? "8") ?? 8
let outPath = args.first

// iOS screen devices enumerate as muxed and/or external video.
func screenDevices() -> [AVCaptureDevice] {
    let muxed = AVCaptureDevice.DiscoverySession(
        deviceTypes: [.external], mediaType: .muxed, position: .unspecified).devices
    let video = AVCaptureDevice.DiscoverySession(
        deviceTypes: [.external], mediaType: .video, position: .unspecified).devices
    // Heuristic: the iPhone screen device is NOT a known virtual-cam vendor and
    // is NOT a Continuity " Camera"/" Desk View".
    let blocked = ["OBS", "Insta360", "Loom", " Camera", "Desk View", "FaceTime"]
    let all = muxed + video
    return all.filter { d in !blocked.contains { d.localizedName.contains($0) } }
}

let candidates = screenDevices()
if listOnly {
    print("candidate iPhone-screen devices (\(candidates.count)):")
    for d in candidates { print("  • \(d.localizedName) | type=\(d.deviceType.rawValue) | id=\(d.uniqueID)") }
    exit(0)
}
guard let outPath = outPath else { err("usage: iphone-screen <out.jpg> [--device X] [--list]"); exit(1) }
let outURL = URL(fileURLWithPath: outPath)

func pick() -> AVCaptureDevice? {
    if let m = deviceMatch {
        return candidates.first { $0.localizedName.range(of: m, options: .caseInsensitive) != nil }
    }
    return candidates.first
}
guard let device = pick() else {
    err("[iphone-screen] no iPhone screen device — is the phone unlocked + trusted over USB?"); exit(2)
}
err("[iphone-screen] using: \(device.localizedName) [\(device.deviceType.rawValue)]")

let session = AVCaptureSession()
session.beginConfiguration()
do {
    let input = try AVCaptureDeviceInput(device: device)
    guard session.canAddInput(input) else { err("cannot add input"); exit(3) }
    session.addInput(input)
} catch { err("input failed: \(error)"); exit(3) }

final class Grabber: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    let outURL: URL; let sema: DispatchSemaphore
    var captured = false; var skip = 8; var code: Int32 = 0
    init(_ u: URL, _ s: DispatchSemaphore) { outURL = u; sema = s }
    func captureOutput(_ o: AVCaptureOutput, didOutput sb: CMSampleBuffer, from c: AVCaptureConnection) {
        if captured { return }
        if skip > 0 { skip -= 1; return }
        guard let pb = CMSampleBufferGetImageBuffer(sb) else { return }
        let ci = CIImage(cvPixelBuffer: pb)
        guard let cg = CIContext().createCGImage(ci, from: ci.extent),
              let dest = CGImageDestinationCreateWithURL(outURL as CFURL, UTType.jpeg.identifier as CFString, 1, nil) else {
            code = 5; captured = true; sema.signal(); return
        }
        CGImageDestinationAddImage(dest, cg, [kCGImageDestinationLossyCompressionQuality as String: 0.95] as CFDictionary)
        if !CGImageDestinationFinalize(dest) { code = 6 }
        captured = true; sema.signal()
    }
}

let sema = DispatchSemaphore(value: 0)
let grabber = Grabber(outURL, sema)
let dataOut = AVCaptureVideoDataOutput()
dataOut.setSampleBufferDelegate(grabber, queue: DispatchQueue(label: "screen.grab"))
guard session.canAddOutput(dataOut) else { err("cannot add video output"); exit(4) }
session.addOutput(dataOut)
session.commitConfiguration()

session.startRunning()
let timedOut = sema.wait(timeout: .now() + timeout) == .timedOut
session.stopRunning()
if timedOut { err("timed out after \(timeout)s"); exit(7) }
if grabber.code == 0 { print(outURL.path) }
exit(grabber.code)
