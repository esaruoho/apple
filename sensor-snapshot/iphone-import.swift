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
// Needs: iPhone tethered + unlocked + "Trust This Computer". The session-open is
// retried for ~80s so you can unlock the phone AFTER starting. In --watch the
// next photo is found by POLLING (close→reopen re-enumerates) every 2s, because
// ImageCaptureCore's didAdd push event is unreliable for iPhone captures.

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
    var unlockTries = 0
    let maxUnlockTries = 40           // ~80s of retrying (2s tick) while you unlock
    var sessionOpen = false
    var wantRetry = false
    var loggedLock = false
    var catalogReady = false          // true once the existing-photo baseline is set
    var downloading = false           // a download is in flight — don't start another
    var refreshing = false            // a poll-triggered close→reopen is in flight
    var pollTicks = 0                 // 2s poll ticks since we started watching

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
        guard let error = error else {            // success → catalog will follow
            sessionOpen = true; wantRetry = false
            return
        }
        let code = (error as NSError).code
        // -9943 == ICReturnDeviceIsPasscodeLocked. The phone is locked (or this
        // Mac isn't yet trusted, which iOS surfaces as "locked"). Flag a retry
        // (driven by the main-thread timer) instead of bailing, so you can start
        // the command and unlock the phone afterwards.
        if code == -9943 {
            if !loggedLock {
                loggedLock = true
                err("[iphone-import] iPhone is locked — unlock it now (and tap Trust if asked). Retrying for ~80s…")
            }
            // Fall back to the retry phase (also covers the phone re-locking mid-watch).
            sessionOpen = false; refreshing = false; wantRetry = true
            return
        }
        err("open session failed: \(error)")
        finish(2)
    }
    func device(_ device: ICDevice, didCloseSessionWithError error: Error?) {
        // A poll asked for a refresh: reopen so the catalog re-enumerates and we
        // can see any photo taken since the last scan.
        if refreshing, !done { (device as? ICCameraDevice)?.requestOpenSession() }
    }
    func didRemove(_ device: ICDevice) {}
    func cameraDevice(_ camera: ICCameraDevice, didRenameItems items: [ICCameraItem]) {}
    func cameraDevice(_ camera: ICCameraDevice, didReceivePTPEvent eventData: Data) {}
    func cameraDeviceDidRemoveAccessRestriction(_ device: ICDevice) {}
    func cameraDeviceDidEnableAccessRestriction(_ device: ICDevice) {}
    func deviceDidBecomeReady(withCompleteContentCatalog device: ICCameraDevice) {
        let files = mediaFiles(device)
        if watch {
            if !catalogReady {
                // First enumeration: remember everything already on the phone.
                baseline = Set(files.map { $0.name ?? "" })
                catalogReady = true
                err("[iphone-import] catalog ready, \(files.count) item(s) — watching (polling every 2s). Take a shot now…")
            } else {
                // A poll-triggered reopen finished: did a new photo appear?
                refreshing = false
                let fresh = files.filter { !baseline.contains($0.name ?? "") }
                if let f = fresh.max(by: { ($0.creationDate ?? .distantPast) < ($1.creationDate ?? .distantPast) }) {
                    err("[iphone-import] new photo detected: \(f.name ?? "?")")
                    downloading = true
                    download(device, f)
                }
            }
            return
        }
        if latest {
            err("[iphone-import] catalog ready, \(files.count) media item(s)")
            guard let newest = files.max(by: { ($0.creationDate ?? .distantPast) < ($1.creationDate ?? .distantPast) }) else {
                err("no media on device"); finish(3); return
            }
            download(device, newest)
        }
    }

    // Fast path: if the push event ever DOES fire for a fresh capture, take it.
    func cameraDevice(_ camera: ICCameraDevice, didAdd items: [ICCameraItem]) {
        guard watch, !done, catalogReady, !downloading else { return }
        let fresh = items.compactMap { $0 as? ICCameraFile }
            .filter { !baseline.contains($0.name ?? "") }
        guard let f = fresh.max(by: { ($0.creationDate ?? .distantPast) < ($1.creationDate ?? .distantPast) }) else { return }
        err("[iphone-import] new photo detected: \(f.name ?? "?")")
        downloading = true
        download(camera, f)
    }
    func cameraDevice(_ camera: ICCameraDevice, didRemove items: [ICCameraItem]) {}
    func cameraDeviceDidChangeCapability(_ camera: ICCameraDevice) {}
    func cameraDevice(_ camera: ICCameraDevice, didReceiveThumbnail t: CGImage?, for item: ICCameraItem, error: Error?) {}
    func cameraDevice(_ camera: ICCameraDevice, didReceiveMetadata m: [AnyHashable: Any]?, for item: ICCameraItem, error: Error?) {}

    func mediaFiles(_ device: ICCameraDevice) -> [ICCameraFile] {
        (device.mediaFiles ?? []).compactMap { $0 as? ICCameraFile }
    }

    // Called every 2s by the main-thread timer. Two jobs: (1) retry the session
    // open while the phone is still locked; (2) once watching, poll for a new
    // photo by forcing a catalog refresh (close→reopen re-enumerates).
    func tick() {
        guard !done, let cam = camera else { return }

        // Phase 1 — still trying to open the session (phone locked / untrusted).
        if !sessionOpen {
            guard wantRetry else { return }
            unlockTries += 1
            if unlockTries >= maxUnlockTries {
                err("open session still failing after \(unlockTries) tries — likely a Trust problem, not a lock.")
                finish(2); return
            }
            if unlockTries % 2 == 0 {
                err("[iphone-import] still waiting for unlock… (\(unlockTries)/\(maxUnlockTries))")
            }
            cam.requestOpenSession()
            return
        }

        // Phase 2 — watching: every tick, force a fresh catalog scan.
        guard watch, catalogReady, !downloading, !refreshing else { return }
        pollTicks += 1
        if pollTicks % 5 == 0 { err("[iphone-import] still watching… (\(pollTicks) scans)") }
        refreshing = true
        cam.requestCloseSession()   // didCloseSessionWithError → reopen → re-enumerate
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
else {
    // Main-thread repeating timer drives unlock-retry AND the watch poll. Created
    // + added on the same thread that runs CFRunLoopRun(), so it fires reliably
    // (a timer added from ImageCaptureCore's callback thread never wakes this loop).
    let retry = Timer(timeInterval: 2.0, repeats: true) { _ in imp.tick() }
    RunLoop.main.add(retry, forMode: .common)
    CFRunLoopRun()
}
exit(imp.exitCode)
