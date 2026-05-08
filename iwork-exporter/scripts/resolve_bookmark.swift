// resolve_bookmark.swift — read a binary bookmark blob from stdin, print path/name as JSON.
//
// Usage:
//   cat bookmark.bin | swift resolve_bookmark.swift
//
// Apple-native: uses Foundation NSURL bookmark resolver.

import Foundation

let data = FileHandle.standardInput.readDataToEndOfFile()
do {
    var stale: ObjCBool = false
    let url = try (NSURL(resolvingBookmarkData: data,
                         options: [],
                         relativeTo: nil,
                         bookmarkDataIsStale: &stale)) as URL
    let out: [String: Any] = [
        "path": url.path,
        "url": url.absoluteString,
        "name": url.lastPathComponent,
        "stale": stale.boolValue,
    ]
    let jdata = try JSONSerialization.data(withJSONObject: out)
    FileHandle.standardOutput.write(jdata)
    FileHandle.standardOutput.write("\n".data(using: .utf8)!)
} catch {
    let err = "{\"error\":\"\(error.localizedDescription)\"}\n"
    FileHandle.standardError.write(err.data(using: .utf8)!)
    exit(1)
}
