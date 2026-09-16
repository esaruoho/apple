#!/usr/bin/env swift
// REPORT-CARD >> features/icdcopy.feature
import Foundation
import Darwin

let fm = FileManager.default

func die(_ message: String, code: Int32 = 1) -> Never {
    fputs("icloud-materialize: \(message)\n", stderr)
    exit(code)
}

func human(_ bytes: Int64) -> String {
    let units = ["B", "KB", "MB", "GB", "TB"]
    var value = Double(bytes)
    var idx = 0
    while value >= 1024 && idx < units.count - 1 {
        value /= 1024
        idx += 1
    }
    return idx == 0 ? "\(Int(value)) \(units[idx])" : String(format: "%.2f %@", value, units[idx])
}

func duration(_ seconds: Double) -> String {
    let total = max(0, Int(seconds.rounded()))
    if total < 60 {
        return "\(total)s"
    }
    let minutes = total / 60
    let seconds = total % 60
    if minutes < 60 {
        return seconds == 0 ? "\(minutes)m" : "\(minutes)m \(seconds)s"
    }
    let hours = minutes / 60
    let remMinutes = minutes % 60
    return remMinutes == 0 ? "\(hours)h" : "\(hours)h \(remMinutes)m"
}

func pad(_ value: Int, width: Int) -> String {
    String(format: "%0\(width)d", value)
}

func resourceStatus(_ url: URL) -> String {
    let keys: Set<URLResourceKey> = [
        .isUbiquitousItemKey,
        .ubiquitousItemDownloadingStatusKey,
    ]
    guard let values = try? url.resourceValues(forKeys: keys) else {
        return "unknown"
    }
    guard values.isUbiquitousItem == true else {
        return "local"
    }
    return values.ubiquitousItemDownloadingStatus?.rawValue ?? "ubiquitous-unknown"
}

func isReady(_ status: String) -> Bool {
    status == "local" || status == URLUbiquitousItemDownloadingStatus.current.rawValue || status == URLUbiquitousItemDownloadingStatus.downloaded.rawValue
}

func residentBytesReady(_ url: URL) -> Bool {
    var st = stat()
    let ok = url.path.withCString { pathPtr in
        fstatat(AT_FDCWD, pathPtr, &st, 0) == 0
    }
    guard ok else {
        return false
    }
    if st.st_size == 0 {
        return true
    }
    return Int64(st.st_blocks) * 512 >= Int64(st.st_size)
}

func fileReady(_ url: URL, status: String? = nil) -> Bool {
    if let status = status, isReady(status) {
        return true
    }
    if status == nil && isReady(resourceStatus(url)) {
        return true
    }
    return residentBytesReady(url)
}

func regularFiles(under root: URL) -> [URL] {
    var isDir: ObjCBool = false
    guard fm.fileExists(atPath: root.path, isDirectory: &isDir) else {
        die("source does not exist: \(root.path)")
    }
    if !isDir.boolValue {
        return [root]
    }
    let keys: [URLResourceKey] = [.isRegularFileKey, .fileSizeKey]
    guard let e = fm.enumerator(at: root, includingPropertiesForKeys: keys, options: [.skipsPackageDescendants]) else {
        die("cannot enumerate: \(root.path)")
    }
    fputs("icloud-materialize: scanning \(root.path) …\n", stderr)
    var files: [URL] = []
    var seen = 0
    for case let url as URL in e {
        seen += 1
        if seen % 500 == 0 {
            fputs("icloud-materialize: scanned \(seen) entries so far, \(files.count) files …\n", stderr)
        }
        let values = try? url.resourceValues(forKeys: Set(keys))
        if values?.isRegularFile == true {
            files.append(url)
        }
    }
    fputs("icloud-materialize: scan done — \(files.count) file(s)\n", stderr)
    return files
}

// Read the raw iCloud "is downloading" flag without triggering a download.
func isDownloading(_ url: URL) -> Bool {
    let keys: Set<URLResourceKey> = [.ubiquitousItemIsDownloadingKey]
    guard let values = try? url.resourceValues(forKeys: keys) else { return false }
    return values.ubiquitousItemIsDownloading == true
}

// Read-only audit: classify every file, print a report, and exit non-zero if any
// file is not fully local + resident on disk. Never starts a download.
func runCheck(_ files: [URL], verbose: Bool, json: Bool) -> Never {
    var ok = 0            // local/current/downloaded AND bytes resident
    var placeholder = 0   // ubiquitous, not downloaded (dataless)
    var downloading = 0   // ubiquitous, download in progress
    var suspect = 0       // status says downloaded but bytes not resident on disk
    var notReady: [(String, String, Int64)] = []  // (path, label, size)
    let total = files.count
    for (idx, url) in files.enumerated() {
        if (idx + 1) % 2000 == 0 {
            fputs("icdcheck: audited \(idx + 1)/\(total) …\n", stderr)
        }
        let attrs = try? fm.attributesOfItem(atPath: url.path)
        let size = (attrs?[.size] as? NSNumber)?.int64Value ?? 0
        let status = resourceStatus(url)
        let resident = residentBytesReady(url)
        var label: String
        if isReady(status) && resident {
            ok += 1
            if verbose { print("OK          \(human(size))\t\(url.path)") }
            continue
        } else if isReady(status) && !resident {
            suspect += 1; label = "SUSPECT"      // claims downloaded, bytes missing
        } else if isDownloading(url) {
            downloading += 1; label = "DOWNLOADING"
        } else {
            placeholder += 1; label = "NOT-DOWNLOADED"
        }
        notReady.append((url.path, label, size))
        if verbose { print("\(label.padding(toLength: 12, withPad: " ", startingAt: 0))\(human(size))\t\(url.path)") }
    }

    if json {
        func esc(_ s: String) -> String { s.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"") }
        let items = notReady.map { "{\"path\":\"\(esc($0.0))\",\"status\":\"\($0.1)\",\"bytes\":\($0.2)}" }
        print("{\"total\":\(total),\"ok\":\(ok),\"not_downloaded\":\(placeholder),\"downloading\":\(downloading),\"suspect\":\(suspect),\"issues\":[\(items.joined(separator: ","))]}")
    } else {
        if !verbose && !notReady.isEmpty {
            print("icdcheck: files not fully downloaded:")
            for (p, label, size) in notReady.prefix(200) {
                print("  \(label.padding(toLength: 14, withPad: " ", startingAt: 0))\(human(size))\t\(p)")
            }
            if notReady.count > 200 { print("  … and \(notReady.count - 200) more (use --verbose for all)") }
        }
        print("icdcheck: \(total) file(s) — \(ok) OK, \(placeholder) not-downloaded, \(downloading) downloading, \(suspect) suspect")
        if notReady.isEmpty {
            print("icdcheck: PERFECT — every file is downloaded and resident on disk")
        } else {
            print("icdcheck: \(notReady.count) file(s) NOT fully local — run `icdmat <path>` to download them")
        }
    }
    exit(notReady.isEmpty ? 0 : 1)
}

var rawArgs = Array(CommandLine.arguments.dropFirst())
var maxWaitSeconds = 0.0
var noProgressSeconds = 0.0
var verbose = false
var checkMode = false
var jsonMode = false
if let idx = rawArgs.firstIndex(of: "--check") {
    checkMode = true
    rawArgs.remove(at: idx)
}
if let idx = rawArgs.firstIndex(of: "--json") {
    jsonMode = true
    rawArgs.remove(at: idx)
}
if let idx = rawArgs.firstIndex(of: "--verbose") {
    verbose = true
    rawArgs.remove(at: idx)
}
if let idx = rawArgs.firstIndex(of: "--no-progress-timeout") {
    guard idx + 1 < rawArgs.count, let parsed = Double(rawArgs[idx + 1]) else {
        die("--no-progress-timeout needs seconds", code: 64)
    }
    noProgressSeconds = parsed
    rawArgs.removeSubrange(idx...(idx + 1))
}
if let idx = rawArgs.firstIndex(of: "--max-wait") {
    guard idx + 1 < rawArgs.count, let parsed = Double(rawArgs[idx + 1]) else {
        die("--max-wait needs seconds", code: 64)
    }
    maxWaitSeconds = parsed
    rawArgs.removeSubrange(idx...(idx + 1))
}

let args = rawArgs
if args.isEmpty || args.contains("--help") || args.contains("-h") {
    print("""
    Usage:
      icloud-materialize [--max-wait SECONDS] [--no-progress-timeout SECONDS] [--verbose] PATH [PATH...]
      icloud-materialize --check [--verbose] [--json] PATH [PATH...]

    Default: requests macOS/iCloud Drive to download each file under PATH and waits
    until the item reports local/current/downloaded before returning.

    --check: read-only audit. Classifies every file (OK / not-downloaded /
    downloading / suspect) WITHOUT triggering any download, prints a report, and
    exits non-zero if any file is not fully downloaded and resident on disk.

    By default, the wait has no overall timeout and lack of visible progress is
    reported but does not abort. Pass --max-wait SECONDS or
    --no-progress-timeout SECONDS only for diagnostics.
    """)
    exit(args.isEmpty ? 64 : 0)
}

var allFiles: [URL] = []
for raw in args {
    let url = URL(fileURLWithPath: NSString(string: raw).expandingTildeInPath)
    allFiles.append(contentsOf: regularFiles(under: url))
}

if checkMode {
    runCheck(allFiles, verbose: verbose, json: jsonMode)
}

var pending: [URL] = []
var readyCount = 0
let total = allFiles.count
fputs("icloud-materialize: checking \(total) file(s) for what needs downloading …\n", stderr)
for (idx, url) in allFiles.enumerated() {
    if (idx + 1) % 1000 == 0 {
        fputs("icloud-materialize: checked \(idx + 1)/\(total) — \(readyCount) already local, \(pending.count) requested so far …\n", stderr)
    }
    let attrs = try? fm.attributesOfItem(atPath: url.path)
    let size = (attrs?[.size] as? NSNumber)?.int64Value ?? 0
    let status = resourceStatus(url)
    if verbose {
        print("[\(idx + 1)/\(total)] \(human(size)) \(status) \(url.lastPathComponent)")
    }

    if fileReady(url, status: status) {
        readyCount += 1
        continue
    }

    do {
        try fm.startDownloadingUbiquitousItem(at: url)
        pending.append(url)
    } catch {
        die("could not start iCloud download for \(url.path): \(error)")
    }
}

print("icloud-materialize: scanned \(allFiles.count) file(s), \(readyCount) ready, \(pending.count) requested from iCloud")

if pending.isEmpty {
    print("icloud-materialize: ready")
    exit(0)
}

print("icloud-materialize: downloading \(pending.count) iCloud file(s)")

let started = Date()
var lastReady = -1
var lastPrinted = Date.distantPast
var lastProgress = Date()
var nextNoProgressReport = 60.0
let countWidth = max(2, String(pending.count).count)
while true {
    var ready = 0
    var firstWaiting: URL?

    for url in pending {
        let status = resourceStatus(url)
        if fileReady(url, status: status) {
            ready += 1
        } else if firstWaiting == nil {
            firstWaiting = url
        }
    }

    if ready == pending.count {
        print("icloud-materialize: downloads ready \(pad(ready, width: countWidth))/\(pad(pending.count, width: countWidth))")
        break
    }

    let elapsed = Date().timeIntervalSince(started)
    let remaining = max(0, maxWaitSeconds - elapsed)

    if ready != lastReady {
        print("icloud-materialize: downloads ready \(pad(ready, width: countWidth))/\(pad(pending.count, width: countWidth))")
        fflush(stdout)
        lastReady = ready
        lastPrinted = Date()
        lastProgress = Date()
        nextNoProgressReport = elapsed + 60
    } else if elapsed >= nextNoProgressReport {
        if let url = firstWaiting {
            if maxWaitSeconds > 0 {
                print("icloud-materialize: no new downloads for \(duration(elapsed)); still \(pad(ready, width: countWidth))/\(pad(pending.count, width: countWidth)) ready; timeout in \(duration(remaining)); waiting on \(url.lastPathComponent)")
            } else {
                print("icloud-materialize: no new downloads for \(duration(elapsed)); still \(pad(ready, width: countWidth))/\(pad(pending.count, width: countWidth)) ready; continuing; waiting on \(url.lastPathComponent)")
            }
        } else {
            if maxWaitSeconds > 0 {
                print("icloud-materialize: no new downloads for \(duration(elapsed)); still \(pad(ready, width: countWidth))/\(pad(pending.count, width: countWidth)) ready; timeout in \(duration(remaining))")
            } else {
                print("icloud-materialize: no new downloads for \(duration(elapsed)); still \(pad(ready, width: countWidth))/\(pad(pending.count, width: countWidth)) ready; continuing")
            }
        }
        fflush(stdout)
        lastPrinted = Date()
        nextNoProgressReport = elapsed + 60
    }

    if maxWaitSeconds > 0 && elapsed >= maxWaitSeconds {
        if let url = firstWaiting {
            die("timed out after \(Int(maxWaitSeconds))s waiting for iCloud:\n  downloads ready \(pad(ready, width: countWidth))/\(pad(pending.count, width: countWidth))\n  \(url.path)\n  status: not downloaded\n  iCloud did not finish making this source local. Try Finder Download Now for this item/folder, then run icdcopy again.")
        }
        die("timed out after \(Int(maxWaitSeconds))s waiting for iCloud:\n  downloads ready \(pad(ready, width: countWidth))/\(pad(pending.count, width: countWidth))")
    }

    if noProgressSeconds > 0 && Date().timeIntervalSince(lastProgress) >= noProgressSeconds {
        if let url = firstWaiting {
            die("iCloud made no download progress for \(duration(noProgressSeconds)):\n  downloads ready \(pad(ready, width: countWidth))/\(pad(pending.count, width: countWidth))\n  \(url.path)\n  iCloud/FileProvider is stalled, not copying.", code: 75)
        }
        die("iCloud made no download progress for \(duration(noProgressSeconds)):\n  downloads ready \(pad(ready, width: countWidth))/\(pad(pending.count, width: countWidth))\n  iCloud/FileProvider is stalled, not copying.", code: 75)
    }

    if verbose {
        for (idx, url) in pending.enumerated() {
            print("  [\(idx + 1)/\(pending.count)] \(resourceStatus(url)) \(url.lastPathComponent)")
        }
        fflush(stdout)
    }

    Thread.sleep(forTimeInterval: 2.0)
}

print("icloud-materialize: ready")
