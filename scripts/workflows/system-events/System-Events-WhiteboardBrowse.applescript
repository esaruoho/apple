-- WhiteboardBrowse: Button press — pick project → topic, show first board.
-- Triggers: whiteboardbrowse, button, press, pick, project, topic, show, first
-- Category: System Events
-- Loupedeck button: this script only.

set s to load script POSIX file "/Users/esaruoho/work/apple/scripts/workflows/system-events/compiled/WhiteboardKnob.scpt"
tell s to browse()
