// Native macOS webcam photo capture via AVCaptureVideoDataOutput.
// Apple-native only — no third-party deps. Uses /usr/bin/swiftc which ships with macOS.
//
// Why VideoDataOutput instead of PhotoOutput: AVCapturePhotoOutput requires
// KVO subclassing that isn't linked into command-line tools (NSKVONotifying_*
// missing). VideoDataOutput grabs raw sample buffers; we convert one to JPEG
// via CGImageDestination — purely native AppKit/CoreImage path.
//
// Usage:  sal-take-photo /path/to/output.jpg

import Foundation
import AVFoundation
import CoreImage
import ImageIO
import UniformTypeIdentifiers

guard CommandLine.arguments.count >= 2 else {
    FileHandle.standardError.write("usage: sal-take-photo <output.jpg>\n".data(using: .utf8)!)
    exit(1)
}
let outURL = URL(fileURLWithPath: CommandLine.arguments[1])

guard let device = AVCaptureDevice.default(for: .video) else {
    FileHandle.standardError.write("no video device\n".data(using: .utf8)!)
    exit(2)
}

let session = AVCaptureSession()
session.sessionPreset = .photo
do {
    let input = try AVCaptureDeviceInput(device: device)
    if session.canAddInput(input) { session.addInput(input) }
} catch {
    FileHandle.standardError.write("input failed: \(error)\n".data(using: .utf8)!)
    exit(3)
}

final class FrameGrabber: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    let outURL: URL
    let sema: DispatchSemaphore
    var captured = false
    var skipFrames = 15  // discard first N frames so exposure / WB settle
    var exitCode: Int32 = 0
    init(outURL: URL, sema: DispatchSemaphore) { self.outURL = outURL; self.sema = sema }

    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        if captured { return }
        if skipFrames > 0 { skipFrames -= 1; return }
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let ci = CIImage(cvPixelBuffer: pixelBuffer)
        let ctx = CIContext()
        guard let cg = ctx.createCGImage(ci, from: ci.extent) else { return }
        guard let dest = CGImageDestinationCreateWithURL(outURL as CFURL, UTType.jpeg.identifier as CFString, 1, nil) else {
            exitCode = 5
            captured = true
            sema.signal()
            return
        }
        CGImageDestinationAddImage(dest, cg, [kCGImageDestinationLossyCompressionQuality as String: 0.9] as CFDictionary)
        if !CGImageDestinationFinalize(dest) {
            exitCode = 6
        }
        captured = true
        sema.signal()
    }
}

let sema = DispatchSemaphore(value: 0)
let grabber = FrameGrabber(outURL: outURL, sema: sema)
let dataOut = AVCaptureVideoDataOutput()
dataOut.setSampleBufferDelegate(grabber, queue: DispatchQueue(label: "frame.grabber"))
if session.canAddOutput(dataOut) { session.addOutput(dataOut) }

session.startRunning()
let timedOut = sema.wait(timeout: .now() + 5.0) == .timedOut
session.stopRunning()
if timedOut {
    FileHandle.standardError.write("timed out\n".data(using: .utf8)!)
    exit(7)
}
exit(grabber.exitCode)
