-- snap.applescript — capture a single JPG from the FaceTime camera.
-- Bind to a Loupedeck button. Files land in
--   ~/work/apple/exported/image-capture/snaps/<timestamp>.jpg

set repoRoot to (POSIX path of (path to home folder)) & "work/apple"
set cmd to repoRoot & "/image-capture-exporter/scripts/image-capture-exporter snap --camera FaceTime"

try
	set output to do shell script "bash -lc " & quoted form of cmd
	display notification (output as text) with title "Snap saved"
on error errMsg
	display notification ("Snap failed: " & errMsg) with title "Image Capture"
end try
