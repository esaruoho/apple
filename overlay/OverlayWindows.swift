// OverlayWindows — the first AnchorResolver.
//
// Built as `MacWindowAnchorResolver`, not as `followWindow()`, because the SDD is
// right that this is the first instance of a general abstraction rather than one
// feature. What persists is selector semantics; CGWindowID and pid are runtime hints
// this file may use and must never store as identity.
//
// Tier A on purpose: CGWindowList only. It needs NO TCC grant at all, so window
// anchoring works the moment the app launches. AXObserver (tier B) is event-driven
// and more precise but costs an Accessibility prompt; the anchor record is identical
// either way, which is the point of putting the selectors in the durable form first.
//
// Coordinates: CGWindowList reports TOP-LEFT space measured from the primary display.
// Everything here converts to AppKit bottom-left before it touches a canvas, because
// mixing the two silently is how annotations end up mirrored down the screen.
//
// FEATURE-CARD >> overlay/overlay.feature

import Cocoa

public enum WindowList {

    /// Every on-screen window, as plain facts.
    public static func onScreen() -> [WindowDescriptor] {
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let raw = CGWindowListCopyWindowInfo(options, kCGNullWindowID)
                as? [[String: Any]] else { return [] }

        return raw.compactMap { info in
            guard let pid = info[kCGWindowOwnerPID as String] as? Int,
                  let number = info[kCGWindowNumber as String] as? Int,
                  let boundsDict = info[kCGWindowBounds as String] as? [String: Any],
                  let rect = CGRect(dictionaryRepresentation: boundsDict as CFDictionary)
            else { return nil }

            return WindowDescriptor(
                pid: pid,
                owner: info[kCGWindowOwnerName as String] as? String ?? "",
                title: info[kCGWindowName as String] as? String ?? "",
                number: number,
                frame: rect,
                layer: info[kCGWindowLayer as String] as? Int ?? 0)
        }
    }

    /// Windows a person could mean, with our own panels excluded.
    public static func addressable() -> [WindowDescriptor] {
        WindowMatcher.addressable(onScreen(), excludingOwner: "Overlay")
    }

    /// The topmost addressable window containing a point, in AppKit bottom-left
    /// global coordinates. CGWindowList returns front-to-back, so first hit wins.
    public static func window(atAppKitPoint p: CGPoint) -> WindowDescriptor? {
        let flipped = topLeftPoint(fromAppKit: p)
        return addressable().first { $0.frame.contains(flipped) }
    }

    // ── coordinate conversion, in one place ──

    /// Height of the primary display — the origin CGWindowList measures down from.
    public static var primaryHeight: CGFloat {
        (NSScreen.screens.first { $0.frame.origin == .zero } ?? NSScreen.screens.first)?
            .frame.height ?? 0
    }

    public static func topLeftPoint(fromAppKit p: CGPoint) -> CGPoint {
        CGPoint(x: p.x, y: primaryHeight - p.y)
    }

    /// A CGWindowList frame → AppKit global rect.
    public static func appKitRect(fromTopLeft r: CGRect) -> CGRect {
        CGRect(x: r.minX, y: primaryHeight - r.maxY, width: r.width, height: r.height)
    }
}

/// Resolves a window anchor against what is on screen right now.
public struct MacWindowAnchorResolver {

    /// Bumped whenever the display arrangement changes, so a geometry recorded under
    /// the old arrangement is detectably stale rather than quietly reused.
    public static var surfaceEpoch: Int = 0

    public init() {}

    /// The whole contract: an anchor in, a graded Resolution out.
    ///
    /// Never returns "the closest window". Zero matches is `.unavailable`, several is
    /// `.ambiguous`, and only exactly one is `.resolved` — because an annotation that
    /// silently rebinds to a different window is worse than one that admits it is lost.
    public func resolve(_ binding: WindowBinding,
                        among windows: [WindowDescriptor]? = nil,
                        now: Double = Date().timeIntervalSince1970)
        -> (resolution: Resolution, window: WindowDescriptor?, rect: CGRect?) {

        let pool = windows ?? WindowList.addressable()
        let found = WindowMatcher.candidates(for: binding.anchor, among: pool)

        guard found.matches.count == 1, let target = found.matches[0] as WindowDescriptor? else {
            let resolution = Resolution.grade(candidates: found.matches.count,
                                              method: found.method,
                                              confidence: found.weight,
                                              rect: nil,
                                              surfaceEpoch: Self.surfaceEpoch, t: now)
            return (resolution, nil, nil)
        }

        // Place the mark back inside the window it was bound to, in AppKit space.
        let windowAppKit = WindowList.appKitRect(fromTopLeft: target.frame)
        let placed = WindowMatcher.place(binding.rel, in: windowAppKit)

        let resolution = Resolution.grade(candidates: 1, method: found.method,
                                          confidence: found.weight,
                                          rect: binding.rel,
                                          surfaceEpoch: Self.surfaceEpoch, t: now)
        return (resolution, target, placed)
    }
}

/// Watches the windows that anchored marks are attached to.
///
/// Polls, because tier A has no event source — but only while something is actually
/// anchored, and at 10 Hz rather than per frame. CGWindowList is a cheap call and
/// this stops entirely when the last anchored mark goes away. Tier B replaces the
/// timer with AXObserver notifications and changes nothing else.
public final class WindowTracker {

    private var timer: Timer?
    private let onTick: () -> Void
    /// True while anything is anchored; the tracker owns nothing else.
    public private(set) var running = false

    public init(onTick: @escaping () -> Void) {
        self.onTick = onTick
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil, queue: .main) { _ in
                // The arrangement changed: every recorded geometry is now suspect.
                MacWindowAnchorResolver.surfaceEpoch += 1
                NSLog("Overlay: surface epoch → \(MacWindowAnchorResolver.surfaceEpoch)")
            }
    }

    public func sync(anchoredCount: Int) {
        if anchoredCount > 0, timer == nil {
            running = true
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) {
                [weak self] _ in self?.onTick()
            }
            NSLog("Overlay: window tracker started (\(anchoredCount) anchored)")
        } else if anchoredCount == 0, timer != nil {
            timer?.invalidate(); timer = nil
            running = false
            NSLog("Overlay: window tracker stopped — nothing anchored")
        }
    }

    deinit { timer?.invalidate() }
}
