// take_photo.swift — capture a photo from a named (or default) AVFoundation
// camera and write it as JPEG to a path. Apple-native via /usr/bin/swift.
//
// Usage:  swift take_photo.swift /path/to/out.jpg [device-name-substring]

import AVFoundation
import Foundation
import AppKit

let args = CommandLine.arguments
if args.count < 2 {
    FileHandle.standardError.write("usage: take_photo.swift <out.jpg> [name]\n".data(using: .utf8)!)
    exit(2)
}
let outPath = args[1]
let nameFilter = args.count >= 3 ? args[2].lowercased() : ""

let session = AVCaptureDevice.DiscoverySession(deviceTypes: [
    .builtInWideAngleCamera,
    .external,
    .deskViewCamera,
    .continuityCamera,
], mediaType: .video, position: .unspecified)

let device: AVCaptureDevice? = nameFilter.isEmpty
    ? session.devices.first
    : session.devices.first { $0.localizedName.lowercased().contains(nameFilter) }

guard let d = device else {
    FileHandle.standardError.write("no matching camera\n".data(using: .utf8)!)
    exit(1)
}

let avSession = AVCaptureSession()
avSession.sessionPreset = .photo

do {
    let input = try AVCaptureDeviceInput(device: d)
    if avSession.canAddInput(input) { avSession.addInput(input) }
} catch {
    FileHandle.standardError.write("input error: \(error)\n".data(using: .utf8)!)
    exit(1)
}

let output = AVCaptureVideoDataOutput()
let queue = DispatchQueue(label: "capture")

class Cap: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    let outURL: URL
    let done: () -> Void
    var captured = false
    init(_ url: URL, _ done: @escaping () -> Void) { self.outURL = url; self.done = done }
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if captured { return }
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let ci = CIImage(cvPixelBuffer: pixelBuffer)
        let ctx = CIContext()
        guard let cg = ctx.createCGImage(ci, from: ci.extent) else { return }
        let bitmap = NSBitmapImageRep(cgImage: cg)
        guard let data = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.92]) else { return }
        do {
            try data.write(to: outURL)
            captured = true
            done()
        } catch {
            FileHandle.standardError.write("write error: \(error)\n".data(using: .utf8)!)
            exit(1)
        }
    }
}

let outURL = URL(fileURLWithPath: outPath)
let sem = DispatchSemaphore(value: 0)
let cap = Cap(outURL) { sem.signal() }
output.setSampleBufferDelegate(cap, queue: queue)
if avSession.canAddOutput(output) { avSession.addOutput(output) }

avSession.startRunning()
// give the camera ~0.6 s to warm up before grabbing a frame
let timeout = DispatchTime.now() + .seconds(8)
if sem.wait(timeout: timeout) == .timedOut {
    FileHandle.standardError.write("capture timed out\n".data(using: .utf8)!)
    exit(1)
}
avSession.stopRunning()
print("wrote \(outPath) from \(d.localizedName)")
