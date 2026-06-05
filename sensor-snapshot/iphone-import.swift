// iphone-import — pull a full-resolution photo off a USB-tethered iPhone via
// ImageCaptureCore (PTP). Apple-native; no third-party deps.
//
// Unlike Continuity Camera (Path 1, capped ~2MP), this transfers the ACTUAL
// file the iPhone's Camera.app wrote — 12MP, 48MP ProRAW, HEIC, whatever — so
// the trigger is your finger on the shutter and the Mac copies the result.
//
//   iphone-import --latest <destdir>   download the newest photo on the phone now
//   iphone-import --watch  <destdir>   wait for the NEXT new photo, import it, exit
//   iphone-import --list               list the camera devices ImageCaptureCore sees
//
// Needs: iPhone tethered + unlocked + "Trust This Computer". First run prompts
// for TCC access to the connected device.

import Foundation
import ImageCaptureCore

let args = Array(CommandLine.arguments.dropFirst())
func err(_ s: String) { FileHandle.standardError.write((s + "\n").data(using: .utf8)!) }

let listOnly = args.contains("--list")
let watch = args.contains("--watch")
let latest = args.contains("--latest")
let destDir = args.last.flatMap { $0.hasPrefix("--") ? nil : $0 }

guard listOnly || ((watch || latest) && destDir != nil) else {
    err("usage: iphone-import (--latest|--watch) <destdir> | --list"); exit(1)
}

final class Importer: NSObject, ICDeviceBrowserDelegate, ICCameraDeviceDelegate, ICCameraDeviceDownloadDelegate {
    let browser = ICDeviceBrowser()
    var camera: ICCameraDevice?
    var baseline = Set<String>()      // item names present when --watch started
    var done = false
    var exitCode: Int32 = 0

    func start() {
        browser.delegate = self
        browser.browsedDeviceTypeMask = ICDeviceTypeMask(rawValue:
            ICDeviceTypeMask.camera.rawValue | ICDeviceLocationTypeMask.local.rawValue)!
        browser.start()
    }

    // --- browser ---
    func deviceBrowser(_ b: ICDeviceBrowser, didAdd device: ICDevice, moreComing: Bool) {
        guard let cam = device as? ICCameraDevice else { return }
        err("[iphone-import] found camera: \(cam.name ?? "?")")
        if listOnly {
            print(cam.name ?? "(unnamed camera)")
            if !moreComing { finish(0) }
            return
        }
        camera = cam
        cam.delegate = self
        cam.requestOpenSession()
    }
    func deviceBrowser(_ b: ICDeviceBrowser, didRemove d: ICDevice, moreGoing: Bool) {}

    // --- device session ---
    func device(_ device: ICDevice, didOpenSessionWithError error: Error?) {
        if let error = error { err("open session failed: \(error)"); finish(2) }
    }
    func device(_ device: ICDevice, didCloseSessionWithError error: Error?) {}
    func didRemove(_ device: ICDevice) {}
    func cameraDevice(_ camera: ICCameraDevice, didRenameItems items: [ICCameraItem]) {}
    func cameraDevice(_ camera: ICCameraDevice, didReceivePTPEvent eventData: Data) {}
    func cameraDeviceDidRemoveAccessRestriction(_ device: ICDevice) {}
    func cameraDeviceDidEnableAccessRestriction(_ device: ICDevice) {}
    func deviceDidBecomeReady(withCompleteContentCatalog device: ICCameraDevice) {
        let files = mediaFiles(device)
        err("[iphone-import] catalog ready, \(files.count) media item(s)")
        if watch {
            baseline = Set(files.map { $0.name ?? "" })
            err("[iphone-import] watching for the next new photo — take a shot now…")
            return  // wait for didAdd
        }
        if latest {
            guard let newest = files.max(by: { ($0.creationDate ?? .distantPast) < ($1.creationDate ?? .distantPast) }) else {
                err("no media on device"); finish(3); return
            }
            download(device, newest)
        }
    }

    // fires when the phone writes a new photo while we're watching
    func cameraDevice(_ camera: ICCameraDevice, didAdd items: [ICCameraItem]) {
        guard watch, !done else { return }
        let fresh = items.compactMap { $0 as? ICCameraFile }
            .filter { !baseline.contains($0.name ?? "") }
        guard let f = fresh.max(by: { ($0.creationDate ?? .distantPast) < ($1.creationDate ?? .distantPast) }) else { return }
        err("[iphone-import] new photo detected: \(f.name ?? "?")")
        download(camera, f)
    }
    func cameraDevice(_ camera: ICCameraDevice, didRemove items: [ICCameraItem]) {}
    func cameraDeviceDidChangeCapability(_ camera: ICCameraDevice) {}
    func cameraDevice(_ camera: ICCameraDevice, didReceiveThumbnail t: CGImage?, for item: ICCameraItem, error: Error?) {}
    func cameraDevice(_ camera: ICCameraDevice, didReceiveMetadata m: [AnyHashable: Any]?, for item: ICCameraItem, error: Error?) {}

    func mediaFiles(_ device: ICCameraDevice) -> [ICCameraFile] {
        (device.mediaFiles ?? []).compactMap { $0 as? ICCameraFile }
    }

    func download(_ device: ICCameraDevice, _ file: ICCameraFile) {
        let dest = URL(fileURLWithPath: destDir!, isDirectory: true)
        let opts: [ICDownloadOption: Any] = [
            .downloadsDirectoryURL: dest,
            .overwrite: true,
        ]
        err("[iphone-import] downloading \(file.name ?? "?") → \(dest.path)")
        device.requestDownloadFile(file, options: opts, downloadDelegate: self,
                                   didDownloadSelector: #selector(didDownloadFile(_:error:options:contextInfo:)),
                                   contextInfo: nil)
    }

    // ICCameraDeviceDownloadDelegate
    func didDownloadFile(_ file: ICCameraFile, error: Error?,
                         options: [String: Any] = [:], contextInfo: UnsafeMutableRawPointer?) {
        if let error = error { err("download failed: \(error)"); finish(4); return }
        let name = (options[ICDownloadOption.savedFilename.rawValue] as? String) ?? file.name ?? "photo"
        let path = URL(fileURLWithPath: destDir!).appendingPathComponent(name).path
        print(path)
        finish(0)
    }
    func didReceiveDownloadProgress(for file: ICCameraFile,
                                    downloadedBytes: off_t, maxBytes: off_t) {}

    func finish(_ code: Int32) {
        if done { return }
        done = true; exitCode = code
        camera?.requestCloseSession()
        browser.stop()
        CFRunLoopStop(CFRunLoopGetMain())
    }
}

let imp = Importer()
imp.start()
// give --list a moment; --latest/--watch end via finish()
if listOnly { CFRunLoopRunInMode(.defaultMode, 4.0, false); imp.finish(0) }
else { CFRunLoopRun() }
exit(imp.exitCode)
