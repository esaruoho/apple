// OverlayLivefile — the bridge from a spatial mark to a durable document.
//
// Converse settled this argument already, and its rule applies here:
//
//     The transcript is a view. The event log is the document.
//
// Overlay had only the view. Marks lived in memory, session.json was written and never
// read, and every exchange died with Esc. So a question you asked about something on
// your screen left no trace anywhere.
//
// This writes overlay activity into a Converse session directory, in Converse's own
// `envoy-livefile-v1` shape — same `evt_NNNNNN` ids, same `t`/`type`/`actor`/`body`
// fields, reusing its existing `agent.requested` / `agent.responded` / `vision.ocr`
// types rather than inventing a parallel vocabulary. The result is a portable folder
// that Converse can already read and ENVOY can already adapt.
//
// The event log is authoritative; `transcript.md` is regenerated from it and says so.
//
// FEATURE-CARD >> overlay/overlay.feature

import Foundation

/// One line of the log. Deliberately a dictionary rather than a struct-per-type: the
/// doctrine says "schemas can evolve, events stay explicit", and a closed Swift enum
/// would fight that every time Converse adds a field.
public struct LivefileEvent {
    public var type: String
    public var actor: String
    public var body: String?
    public var extra: [String: Any]

    public init(type: String, actor: String = "local-user",
                body: String? = nil, extra: [String: Any] = [:]) {
        self.type = type; self.actor = actor; self.body = body; self.extra = extra
    }
}

public enum Livefile {

    /// `evt_000001` — six digits, matching every existing Converse session so the two
    /// writers can interleave in one file without anyone special-casing ids.
    public static func eventID(_ n: Int) -> String {
        String(format: "evt_%06d", n)
    }

    /// Converse writes RFC3339 with milliseconds and a Z. Anything else sorts wrong
    /// against its lines.
    public static func stamp(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        return f.string(from: date)
    }

    /// Session directory names are `YYYY-MM-DD-HHMMSS` in LOCAL time, as Converse does.
    public static func sessionStamp(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd-HHmmss"
        return f.string(from: date)
    }

    /// One JSONL line. Keys sorted so a diff of the log is readable.
    public static func encode(_ event: LivefileEvent, id: String, at date: Date) -> String? {
        var object: [String: Any] = event.extra
        object["id"] = id
        object["t"] = stamp(date)
        object["type"] = event.type
        object["actor"] = event.actor
        if let body = event.body { object["body"] = body }
        guard JSONSerialization.isValidJSONObject(object),
              let data = try? JSONSerialization.data(withJSONObject: object,
                                                     options: [.sortedKeys]),
              let line = String(data: data, encoding: .utf8) else { return nil }
        return line
    }

    /// Render the human-readable view. Not authoritative, and it says so at the top —
    /// the same header Converse writes, so nobody edits the wrong file.
    public static func transcript(from events: [[String: Any]], sessionID: String) -> String {
        var out = """
        <!--
        This transcript is derived from livefile.jsonl.
        Do not treat this file alone as the source of truth.
        -->

        # Overlay session \(sessionID)

        """

        for event in events {
            let type = event["type"] as? String ?? "?"
            let t = (event["t"] as? String ?? "").replacingOccurrences(of: "T", with: " ")
                .replacingOccurrences(of: "Z", with: "")
            let body = event["body"] as? String ?? ""

            switch type {
            case "session.created":
                out += "\n_started \(t)_\n"
            case "overlay.region.captured":
                let rect = event["rect"] as? String ?? ""
                out += "\n---\n\n**Region** `\(rect)`\n"
                if let app = event["app"] as? String, !app.isEmpty {
                    out += "in **\(app)**\n"
                }
            case "vision.ocr":
                if !body.isEmpty { out += "\n> \(body)\n" }
            case "agent.requested":
                out += "\n**you:** \(event["instruction"] as? String ?? body)\n"
            case "agent.responded":
                let ms = event["latency_ms"] as? Int
                out += "\n**\(event["agent"] as? String ?? "agent"):** \(body)"
                out += ms.map { "  _(\($0) ms)_\n" } ?? "\n"
            case "overlay.image.generated":
                let prompt = event["prompt"] as? String ?? ""
                let file = event["file"] as? String ?? ""
                out += "\n**image** — \(prompt)\n\n![generated](\(file))\n"
            case "overlay.mark.added":
                out += "\n_marked: \(body)_\n"
            case "session.closed":
                out += "\n_closed \(t)_\n"
            default:
                if !body.isEmpty { out += "\n_\(type): \(body)_\n" }
            }
        }
        return out
    }
}

/// Appends overlay activity to one Converse-shaped session on disk.
///
/// Created lazily: an overlay that is only being drawn on does not deserve a folder.
/// The first event that is worth remembering — a question, a render — brings the
/// session into existence.
public final class LivefileWriter {

    public let directory: URL
    public let sessionID: String
    private var counter = 0
    private let queue = DispatchQueue(label: "com.esaruoho.overlay.livefile")
    private var started = false

    /// Sessions live beside Converse's own, so one folder holds every conversation
    /// this machine has had, whatever surface it happened on.
    public static var sessionsRoot: URL {
        URL(fileURLWithPath: NSHomeDirectory())
            .appendingPathComponent("work/converse/sessions")
    }

    public init(now: Date = Date()) {
        sessionID = Livefile.sessionStamp(now) + "-overlay"
        directory = LivefileWriter.sessionsRoot.appendingPathComponent(sessionID)
    }

    public var logURL: URL { directory.appendingPathComponent("livefile.jsonl") }
    public var transcriptURL: URL { directory.appendingPathComponent("transcript.md") }
    private var manifestURL: URL { directory.appendingPathComponent("manifest.json") }

    private func startIfNeeded(now: Date) {
        guard !started else { return }
        started = true
        try? FileManager.default.createDirectory(at: directory,
                                                 withIntermediateDirectories: true)
        let manifest: [String: Any] = [
            "app": "overlay",
            "app_version": "0.1.0",
            "doctrine": "envoy-livefile-v1",
            "doctrine_note": "The transcript is a view. The event log is the document.",
            "event_log": "livefile.jsonl",
            "transcript": "transcript.md",
            "id": sessionID,
            "started_at": Livefile.stamp(now),
        ]
        if let data = try? JSONSerialization.data(withJSONObject: manifest,
                                                  options: [.prettyPrinted, .sortedKeys]) {
            try? data.write(to: manifestURL)
        }
        appendLine(LivefileEvent(type: "session.created", body: sessionID, extra: [
            "app": "overlay", "app_version": "0.1.0",
            "doctrine": "envoy-livefile-v1",
            "session_id": sessionID, "transcript": "transcript.md",
        ]), now: now)
    }

    private func appendLine(_ event: LivefileEvent, now: Date) {
        counter += 1
        guard let line = Livefile.encode(event, id: Livefile.eventID(counter), at: now),
              let data = (line + "\n").data(using: .utf8) else { return }
        if let handle = try? FileHandle(forWritingTo: logURL) {
            handle.seekToEndOfFile()
            handle.write(data)
            try? handle.close()
        } else {
            try? data.write(to: logURL)
        }
    }

    /// Append one event. Serialised on its own queue: the ask path answers from a
    /// background thread and the draw path from the main one.
    public func append(_ event: LivefileEvent, now: Date = Date()) {
        queue.async { [weak self] in
            guard let self = self else { return }
            self.startIfNeeded(now: now)
            self.appendLine(event, now: now)
            self.renderTranscript()
        }
    }

    /// Regenerate the readable view from the log — always from the log, never from
    /// whatever the app happens to remember.
    private func renderTranscript() {
        guard let text = try? String(contentsOf: logURL, encoding: .utf8) else { return }
        let events: [[String: Any]] = text.split(separator: "\n").compactMap {
            guard let data = $0.data(using: .utf8) else { return nil }
            return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
        }
        let rendered = Livefile.transcript(from: events, sessionID: sessionID)
        try? rendered.write(to: transcriptURL, atomically: true, encoding: .utf8)
    }
}
