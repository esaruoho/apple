// DualCam — front AND rear iPhone cameras at once, fullscreen, for USB screen capture.
//
// macOS cannot receive an iPhone's front camera. Continuity Camera exposes the phone as ONE
// AVCaptureDevice wired to the rear system, and it reports position=unspecified — there is no
// front/back selector to flip. The capture therefore has to happen ON the phone.
//
// iOS can do what macOS cannot: AVCaptureMultiCamSession (A12 / iPhone XS and later) runs both
// sensors simultaneously. This app composites them on the phone's own screen; the Mac then picks
// that screen up over USB through the CoreMediaIO path iPhoneMirror already uses — the path with
// no device ceiling, so four phones is still four phones.
//
// Everything here serves being FILMED rather than being used:
//   • no chrome, no status bar, black background — the screen IS the deliverable
//   • the idle timer is disabled, because a rig that sleeps after 30 seconds is not a rig
//   • layouts cycle on tap; there is no UI to crop out
//
// FEATURE-CARD >> features/dualcam.feature

import AVFoundation
import UIKit

// MARK: - Layouts

enum Layout: Int, CaseIterable {
    case sideBySide, rearWithFrontPiP, frontWithRearPiP, rearOnly, frontOnly

    var label: String {
        switch self {
        case .sideBySide:       return "side by side"
        case .rearWithFrontPiP: return "rear + front PiP"
        case .frontWithRearPiP: return "front + rear PiP"
        case .rearOnly:         return "rear only"
        case .frontOnly:        return "front only"
        }
    }
}

final class ViewController: UIViewController {

    private let session = AVCaptureMultiCamSession()
    private var rearLayer: AVCaptureVideoPreviewLayer!
    private var frontLayer: AVCaptureVideoPreviewLayer!
    private let banner = UILabel()
    private var layout: Layout = .sideBySide

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        // A capture rig that dims and locks after the idle timeout is useless, and this is the
        // one line that decides whether it survives being left running for an hour.
        UIApplication.shared.isIdleTimerDisabled = true

        guard AVCaptureMultiCamSession.isMultiCamSupported else {
            // Be explicit rather than showing a black screen: on an unsupported device the
            // honest outcome is "this phone cannot do it", not a mysterious failure.
            showFatal("This iPhone does not support running both cameras at once.\n"
                      + "AVCaptureMultiCamSession needs A12 (iPhone XS) or later.")
            return
        }

        rearLayer = makePreview()
        frontLayer = makePreview()
        view.layer.addSublayer(rearLayer)
        view.layer.addSublayer(frontLayer)

        banner.textColor = .white
        banner.font = .monospacedSystemFont(ofSize: 13, weight: .semibold)
        banner.textAlignment = .center
        banner.alpha = 0
        view.addSubview(banner)

        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(cycleLayout)))

        AVCaptureDevice.requestAccess(for: .video) { [weak self] ok in
            DispatchQueue.main.async {
                guard let self else { return }
                guard ok else { self.showFatal("Camera access was denied."); return }
                self.configure()
            }
        }
    }

    private func makePreview() -> AVCaptureVideoPreviewLayer {
        let l = AVCaptureVideoPreviewLayer()
        l.setSessionWithNoConnection(session)   // connections are made by hand for multi-cam
        l.videoGravity = .resizeAspectFill
        return l
    }

    // MARK: - Session

    private func configure() {
        session.beginConfiguration()
        defer { session.commitConfiguration() }

        guard add(position: .back, to: rearLayer), add(position: .front, to: frontLayer) else {
            showFatal("Could not add both cameras to the session.")
            return
        }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.startRunning()
        }
        flash("DualCam · \(layout.label) · tap to change")
    }

    /// Multi-cam sessions must be wired EXPLICITLY: `addInput`/`addOutput` convenience methods
    /// form connections that assume exclusive use of a device, which is precisely what multi-cam
    /// is not. So: add with no connections, then connect the port to the layer by hand.
    private func add(position: AVCaptureDevice.Position, to layer: AVCaptureVideoPreviewLayer) -> Bool {
        let types: [AVCaptureDevice.DeviceType] = [.builtInWideAngleCamera]
        let disco = AVCaptureDevice.DiscoverySession(deviceTypes: types, mediaType: .video, position: position)
        guard let device = disco.devices.first,
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else { return false }
        session.addInputWithNoConnections(input)

        guard let port = input.ports(for: .video,
                                     sourceDeviceType: device.deviceType,
                                     sourceDevicePosition: position).first else { return false }
        let conn = AVCaptureConnection(inputPort: port, videoPreviewLayer: layer)
        guard session.canAddConnection(conn) else { return false }
        session.addConnection(conn)
        return true
    }

    // MARK: - Layout

    @objc private func cycleLayout() {
        let all = Layout.allCases
        layout = all[(all.firstIndex(of: layout)! + 1) % all.count]
        flash(layout.label)
        view.setNeedsLayout()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard rearLayer != nil, frontLayer != nil else { return }
        let b = view.bounds
        // Portrait stacks, landscape splits — a rig gets turned sideways and the layout should
        // follow rather than letterbox itself into a stripe.
        let landscape = b.width > b.height
        let pip = CGRect(x: b.maxX - b.width * 0.30 - 16,
                         y: b.maxY - b.width * 0.30 * 1.4 - 16,
                         width: b.width * 0.30, height: b.width * 0.30 * 1.4)

        CATransaction.begin()
        CATransaction.setDisableActions(true)   // no implicit animation on a captured screen
        switch layout {
        case .sideBySide:
            if landscape {
                rearLayer.frame = CGRect(x: 0, y: 0, width: b.width / 2, height: b.height)
                frontLayer.frame = CGRect(x: b.width / 2, y: 0, width: b.width / 2, height: b.height)
            } else {
                rearLayer.frame = CGRect(x: 0, y: 0, width: b.width, height: b.height / 2)
                frontLayer.frame = CGRect(x: 0, y: b.height / 2, width: b.width, height: b.height / 2)
            }
            rearLayer.isHidden = false; frontLayer.isHidden = false
        case .rearWithFrontPiP:
            rearLayer.frame = b; frontLayer.frame = pip
            rearLayer.isHidden = false; frontLayer.isHidden = false
            view.layer.insertSublayer(frontLayer, above: rearLayer)
        case .frontWithRearPiP:
            frontLayer.frame = b; rearLayer.frame = pip
            rearLayer.isHidden = false; frontLayer.isHidden = false
            view.layer.insertSublayer(rearLayer, above: frontLayer)
        case .rearOnly:
            rearLayer.frame = b; rearLayer.isHidden = false; frontLayer.isHidden = true
        case .frontOnly:
            frontLayer.frame = b; frontLayer.isHidden = false; rearLayer.isHidden = true
        }
        CATransaction.commit()
        banner.frame = CGRect(x: 0, y: b.maxY - 60, width: b.width, height: 24)
    }

    // MARK: - Chrome (deliberately minimal — this screen gets filmed)

    override var prefersStatusBarHidden: Bool { true }
    override var prefersHomeIndicatorAutoHidden: Bool { true }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .all }

    private func flash(_ s: String) {
        banner.text = s
        banner.alpha = 1
        UIView.animate(withDuration: 0.4, delay: 1.6, options: []) { self.banner.alpha = 0 }
    }

    private func showFatal(_ s: String) {
        let l = UILabel(frame: view.bounds.insetBy(dx: 24, dy: 24))
        l.numberOfLines = 0
        l.textAlignment = .center
        l.textColor = .white
        l.font = .systemFont(ofSize: 17, weight: .medium)
        l.text = s
        view.addSubview(l)
    }
}

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ app: UIApplication,
                     didFinishLaunchingWithOptions o: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let w = UIWindow(frame: UIScreen.main.bounds)
        w.rootViewController = ViewController()
        w.makeKeyAndVisible()
        window = w
        return true
    }
}
