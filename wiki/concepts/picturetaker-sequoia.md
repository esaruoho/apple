# Sal's PictureTaker Helper.app Broken on Sequoia

Sal's 2016 `PictureTaker Helper.app` (one of the 5 helper apps shipped in CitrusPeel255.zip, lives at `~/Applications/Dictation Helper Apps/`) opens the legacy `IKPictureTaker` panel — on macOS Sequoia this panel surfaces the **avatar picker** (default flowers / yin-yang / gingerbread / rose) rather than the live camera tab. The camera mode exists in the panel but the user can't click into it from the avatar surface as expected.

**Replacement:** `bin/sal-take-photo.swift` — native AVFoundation `AVCaptureVideoDataOutput` capture. Compiles to `bin/sal-take-photo`, called by the user "Take My Picture" Shortcut. Works on Sequoia; saves JPEG to `~/Pictures/sal-snap-<timestamp>.jpg`; reveals in Finder.

The matcher routes "take my picture" preferentially to the user Shortcut (USER_BOOST=1.5) so Sal's broken `takeVSnapshotAndAddToPhotos` handler is never selected.

