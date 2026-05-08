// list_cameras.swift — print AVFoundation video capture devices as JSON.
// Apple-native: ships with macOS via /usr/bin/swift.
// Used by image-capture-exporter; safe to call standalone.

import AVFoundation
import Foundation

let session = AVCaptureDevice.DiscoverySession(deviceTypes: [
    .builtInWideAngleCamera,
    .external,
    .deskViewCamera,
    .continuityCamera,
], mediaType: .video, position: .unspecified)

var out: [[String: Any]] = []
for d in session.devices {
    var formats: [[String: Any]] = []
    for f in d.formats.prefix(8) {
        let dims = CMVideoFormatDescriptionGetDimensions(f.formatDescription)
        let frs = f.videoSupportedFrameRateRanges.map { ["min": $0.minFrameRate, "max": $0.maxFrameRate] }
        formats.append([
            "width": dims.width,
            "height": dims.height,
            "frame_rates": frs,
        ])
    }
    out.append([
        "name": d.localizedName,
        "unique_id": d.uniqueID,
        "model_id": d.modelID,
        "device_type": d.deviceType.rawValue,
        "manufacturer": d.manufacturer,
        "is_connected": d.isConnected,
        "is_in_use_by_another_app": d.isInUseByAnotherApplication,
        "format_count": d.formats.count,
        "formats_sample": formats,
    ])
}

let data = try JSONSerialization.data(withJSONObject: out, options: [.prettyPrinted])
FileHandle.standardOutput.write(data)
FileHandle.standardOutput.write("\n".data(using: .utf8)!)
