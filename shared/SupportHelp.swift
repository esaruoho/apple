// SupportHelp — the ONE Help + "support Esa" panel every Apple-native app shares.
//
// GROUNDED RULE (see ~/work/apple/CLAUDE.md): every app we make — Guidance,
// Fleet, Converse, Recburn, … — ships this same Help, with the same donation
// methods. Do not fork the links per app; change them here, once.
//
// Drop-in for any SwiftUI app (compile this file alongside the app's .swift):
//   1) In the App scene:   .commands { AppHelpCommand(appName: "YourApp") }
//   2) In the root view:   @State private var showHelp = false
//        …attach to a "?" button:  .popover(isPresented: $showHelp) {
//                                      AppHelpView(appName: "YourApp",
//                                                  tagline: "…", usage: […]) }
//        …and:  .onReceive(NotificationCenter.default.publisher(for: .showAppHelp)) {
//                   _ in showHelp = true }
// The Help menu item, ⌘?, and the "?" button all open the same panel.

import SwiftUI

/// Canonical donation methods — verified from Esa's own files
/// (rbi-esa.md + Paketti promo notes). The single source of truth.
enum SupportLinks {
    static let all: [(label: String, url: String)] = [
        ("GitHub Sponsors", "https://github.com/sponsors/esaruoho"),
        ("PayPal", "https://paypal.me/esaruoho"),
        ("Ko-fi", "https://ko-fi.com/esaruoho"),
        ("Patreon", "https://patreon.com/esaruoho"),
        ("Buy Me a Coffee", "https://buymeacoffee.com/esaruoho"),
        ("Paketti · Gumroad", "https://lackluster.gumroad.com/l/paketti"),
        ("Lackluster · Bandcamp", "https://lackluster.bandcamp.com/"),
        ("HLER · Bandcamp", "https://hler.bandcamp.com/"),
    ]
}

extension Notification.Name {
    /// Post this to open the app's Help panel (wired from the Help menu / ⌘?).
    static let showAppHelp = Notification.Name("showAppHelp")
}

/// The shared donation block — identical across every app.
struct SupportEsaView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("SUPPORT ESA — free, unpaid work")
                .font(.system(size: 9)).bold().foregroundColor(.secondary).tracking(1)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 8)],
                      alignment: .leading, spacing: 6) {
                ForEach(SupportLinks.all, id: \.label) { link in
                    Link(link.label, destination: URL(string: link.url)!).font(.caption)
                }
            }
        }
    }
}

/// A complete Help panel: app blurb + usage bullets + the shared donation block.
struct AppHelpView: View {
    let appName: String
    let tagline: String
    var usage: [(icon: String, text: String)] = []
    var note: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(appName).font(.headline)
            Text(tagline).font(.caption).fixedSize(horizontal: false, vertical: true)
            if !usage.isEmpty {
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(usage, id: \.text) { u in
                        Label(u.text, systemImage: u.icon)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }.font(.caption)
            }
            if let note {
                Text(note).font(.caption2).foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Divider()
            SupportEsaView()
        }
        .padding(16).frame(width: 400)
    }
}

/// Standard Help-menu command for every app: replaces the broken default
/// ("Help isn't available") with a working "<App> Help" item (⌘?) that opens
/// the shared panel. Use in the App scene's `.commands { AppHelpCommand(...) }`.
struct AppHelpCommand: Commands {
    let appName: String
    var body: some Commands {
        CommandGroup(replacing: .help) {
            Button("\(appName) Help") {
                NotificationCenter.default.post(name: .showAppHelp, object: nil)
            }
            .keyboardShortcut("/", modifiers: .command)
        }
    }
}
