// iphone-photo — programmatic high-res still from a USB-tethered iPhone via
// Continuity Camera, written to a file on the Mac. Apple-native only.
//
// Two reasons this MUST run from inside a .app bundle (not a bare swiftc CLI):
//   1. NSCameraUseContinuityCameraDeviceType — read from Bundle.main's Info.plist.
//      Without it AVFoundation will not even enumerate Continuity Camera devices
//      (you get: "WARNING: Add NSCameraUseContinuityCameraDeviceType ...").
//   2. AVCapturePhotoOutput uses KVO internally; the NSKVONotifying_* runtime
//      subclasses resolve correctly inside a bundle, where a bare CLI failed and
//      forced sal-take-photo down the lower-res AVCaptureVideoDataOutput path.
//
// Usage (via the bin/iphone-photo wrapper, which execs the in-bundle binary):
//   iphone-photo <output.(jpg|heic)> [--device <name-substring>] [--list] [--timeout S]
//
// Device pick order: explicit --device substring → first .continuityCamera →
// AVCaptureDevice.default(for: .video) as last resort.

import Foundation
import AVFoundation
import CoreImage
import ImageIO
import UniformTypeIdentifiers

// ---- arg parse -------------------------------------------------------------
var args = Array(CommandLine.arguments.dropFirst())
func popFlag(_ name: String) -> String? {
    guard let i = args.firstIndex(of: name), i + 1 < args.count else { return nil }
    let v = args[i + 1]; args.removeSubrange(i...(i+1)); return v
}
let listOnly = args.contains("--list"); args.removeAll { $0 == "--list" }
let deviceMatch = popFlag("--device")
let timeout = Double(popFlag("--timeout") ?? "12") ?? 12
let outPath = args.first  // optional when --list

func err(_ s: String) { FileHandle.standardError.write((s + "\n").data(using: .utf8)!) }

// ---- device discovery ------------------------------------------------------
let wantedTypes: [AVCaptureDevice.DeviceType] = [
    .continuityCamera, .external, .builtInWideAngleCamera, .deskViewCamera
]
let discovery = AVCaptureDevice.DiscoverySession(
    deviceTypes: wantedTypes, mediaType: .video, position: .unspecified)
let devices = discovery.devices

if listOnly {
    print("video devices (\(devices.count)):")
    for d in devices {
        let dims = d.formats
            .compactMap { $0.supportedMaxPhotoDimensions.last }
            .map { Int($0.width) * Int($0.height) }
            .max() ?? 0
        let mp = Double(dims) / 1_000_000.0
        print(String(format: "  • %@ | type=%@ | maxStill≈%.1fMP | id=%@",
                     d.localizedName, d.deviceType.rawValue, mp, d.uniqueID))
    }
    exit(0)
}

guard let outPath = outPath else { err("usage: iphone-photo <out.jpg> [--device X] [--list]"); exit(1) }
let outURL = URL(fileURLWithPath: outPath)

func pickDevice() -> AVCaptureDevice? {
    if let m = deviceMatch {
        return devices.first { $0.localizedName.range(of: m, options: .caseInsensitive) != nil }
    }
    if let cc = devices.first(where: { $0.deviceType == .continuityCamera }) { return cc }
    return AVCaptureDevice.default(for: .video)
}
guard let device = pickDevice() else { err("no matching video device"); exit(2) }
err("[iphone-photo] using device: \(device.localizedName) [\(device.deviceType.rawValue)]")

// ---- capture session -------------------------------------------------------
// Select the device format with the largest still dimensions, and make it the
// active format. sessionPreset must be .inputPriority so the session does NOT
// override our hand-picked format.
// Why AVCaptureVideoDataOutput, NOT AVCapturePhotoOutput: the latter relies on
// KVO-subclassing AVCapturePhotoOutput at runtime (NSKVONotifying_*). A swiftc
// binary cannot synthesize that subclass — even inside a .app bundle — so the
// capture delegate never fires (silent 12s timeout). VideoDataOutput grabs raw
// sample buffers and needs no KVO. And it costs us nothing here: Continuity
// Camera caps its stills at ~2.8MP regardless, which the highest video format
// (1920×1440) already reaches. (Confirmed live: PhotoOutput timed out; this path
// writes the file.)
func vdim(_ f: AVCaptureDevice.Format) -> Int {
    let d = CMVideoFormatDescriptionGetDimensions(f.formatDescription)
    return Int(d.width) * Int(d.height)
}
let bestFormat = device.formats.max(by: { vdim($0) < vdim($1) })

let session = AVCaptureSession()
session.beginConfiguration()
// NB: do not set sessionPreset — assigning device.activeFormat below auto-flips
// the preset to input-priority (which is unavailable to set directly on macOS).
do {
    let input = try AVCaptureDeviceInput(device: device)
    guard session.canAddInput(input) else { err("cannot add input"); exit(3) }
    session.addInput(input)
} catch { err("input failed: \(error)"); exit(3) }

do {
    try device.lockForConfiguration()
    if let bf = bestFormat { device.activeFormat = bf }
    device.unlockForConfiguration()
} catch { err("lockForConfiguration failed: \(error)") }

final class Grabber: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    let outURL: URL; let sema: DispatchSemaphore
    var captured = false; var skip = 15; var code: Int32 = 0
    init(_ u: URL, _ s: DispatchSemaphore) { outURL = u; sema = s }
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        if captured { return }
        if skip > 0 { skip -= 1; return }  // discard early frames so AE/AWB settle
        guard let pb = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let ci = CIImage(cvPixelBuffer: pb)
        guard let cg = CIContext().createCGImage(ci, from: ci.extent) else { return }
        guard let dest = CGImageDestinationCreateWithURL(
            outURL as CFURL, UTType.jpeg.identifier as CFString, 1, nil) else {
            code = 5; captured = true; sema.signal(); return
        }
        CGImageDestinationAddImage(dest, cg,
            [kCGImageDestinationLossyCompressionQuality as String: 0.92] as CFDictionary)
        if !CGImageDestinationFinalize(dest) { code = 6 }
        captured = true; sema.signal()
    }
}

let sema = DispatchSemaphore(value: 0)
let grabber = Grabber(outURL, sema)
let dataOut = AVCaptureVideoDataOutput()
dataOut.setSampleBufferDelegate(grabber, queue: DispatchQueue(label: "frame.grabber"))
guard session.canAddOutput(dataOut) else { err("cannot add video output"); exit(4) }
session.addOutput(dataOut)
session.commitConfiguration()

let liveDims = CMVideoFormatDescriptionGetDimensions(device.activeFormat.formatDescription)
err(String(format: "[iphone-photo] capturing at %d x %d", liveDims.width, liveDims.height))

session.startRunning()
let timedOut = sema.wait(timeout: .now() + timeout) == .timedOut
session.stopRunning()
if timedOut { err("timed out after \(timeout)s"); exit(8) }
if grabber.code == 0 { print(outURL.path) }
exit(grabber.code)
