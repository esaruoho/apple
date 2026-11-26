// default-changer — set/query the default app for a file extension (Launch Services).
// Card: default-changer/default-changer.feature
import Foundation
import CoreServices
import UniformTypeIdentifiers
import AppKit

func die(_ s: String) -> Never { FileHandle.standardError.write((s + "\n").data(using: .utf8)!); exit(1) }
let a = Array(CommandLine.arguments.dropFirst())
guard a.count >= 2 else { die("usage: default-changer-bin get|set|list <ext> [bundle-id]") }
let ext = a[1].hasPrefix(".") ? String(a[1].dropFirst()) : a[1]
guard let ut = UTType(filenameExtension: ext) else { die("no UTI for .\(ext)") }
let uti = ut.identifier as CFString

func current() -> String? { LSCopyDefaultRoleHandlerForContentType(uti, .all)?.takeRetainedValue() as String? }

switch a[0] {
case "get":
    print("\(ut.identifier)\t\(current() ?? "(none)")")
case "list":
    let ids = (LSCopyAllRoleHandlersForContentType(uti, .all)?.takeRetainedValue() as? [String]) ?? []
    let cur = current()?.lowercased()
    for i in ids { print((i.lowercased() == cur ? "* " : "  ") + i) }
case "set":
    guard a.count >= 3 else { die("set needs bundle-id") }
    let st = LSSetDefaultRoleHandlerForContentType(uti, .all, a[2] as CFString)
    if st != noErr { die("LSSetDefaultRoleHandlerForContentType failed: \(st)") }
    // also bind the bare extension's dynamic type if it differs
    print("\(ut.identifier)\t\(current() ?? "?")")
default: die("unknown verb \(a[0])")
}
