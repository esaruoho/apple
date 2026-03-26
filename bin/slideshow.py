#!/usr/bin/env python3
"""
Slideshow — fullscreen image viewer on any screen.

The underlying principle: folder of images → fullscreen on target screen.
Any folder. Any screen. Sequential or random. One command, one result.

Usage:
    python3 slideshow.py                        # folder picker dialog
    python3 slideshow.py /path/to/images        # direct path
    python3 slideshow.py --shuffle /path        # random order
    python3 slideshow.py --interval 3 /path     # 3 seconds per slide
    python3 slideshow.py --screen 0 /path       # main screen (default: secondary)
    python3 slideshow.py --screen 1 /path       # secondary screen

Controls:
    Escape / Q  — quit
    Right / Space — next
    Left — previous
    P — pause/resume auto-advance

Requires: Pillow (pip3 install Pillow)

Pattern: This is the same principle as WhiteboardKnob (folder → browse images)
but unattended. WhiteboardKnob = manual knob control. Slideshow = auto-advance.
Both start from the same seed: a folder of images is a presentation waiting to happen.
"""

import tkinter as tk
from tkinter import filedialog
from PIL import Image, ImageTk
import subprocess
import glob
import os
import sys
import random
import argparse


def get_screens():
    """Get all screen geometries via Swift/NSScreen. Returns list of dicts."""
    try:
        result = subprocess.run(
            ["swift", "-e", """
import AppKit
for (i, screen) in NSScreen.screens.enumerated() {
    let f = screen.frame
    let name = screen.localizedName
    print("\\(i),\\(name),\\(Int(f.origin.x)),\\(Int(f.origin.y)),\\(Int(f.width)),\\(Int(f.height))")
}
"""],
            capture_output=True, text=True, timeout=10
        )
        screens = []
        for line in result.stdout.strip().split("\n"):
            if not line:
                continue
            parts = line.split(",", 5)
            screens.append({
                "index": int(parts[0]),
                "name": parts[1],
                "x": int(parts[2]),
                "y": int(parts[3]),
                "w": int(parts[4]),
                "h": int(parts[5]),
            })
        return screens
    except Exception:
        return []


def find_images(folder):
    """Find all images recursively (PNG, JPG, JPEG, GIF, WEBP, TIFF)."""
    extensions = ["png", "jpg", "jpeg", "gif", "webp", "tiff", "tif", "bmp"]
    files = []
    for ext in extensions:
        files.extend(glob.glob(os.path.join(folder, f"**/*.{ext}"), recursive=True))
        files.extend(glob.glob(os.path.join(folder, f"**/*.{ext.upper()}"), recursive=True))
    return sorted(set(files))


class Slideshow:
    def __init__(self, root, files, screen, interval=5):
        self.root = root
        self.files = files
        self.index = 0
        self.interval = interval
        self.paused = False
        self.timer_id = None

        # Configure window
        self.root.configure(bg="black")
        self.root.overrideredirect(True)

        # Position on target screen
        if screen:
            self.screen_w = screen["w"]
            self.screen_h = screen["h"]
            self.root.geometry(f"{screen['w']}x{screen['h']}+{screen['x']}+{screen['y']}")
        else:
            self.screen_w = 1920
            self.screen_h = 1080
            self.root.attributes("-fullscreen", True)

        # Canvas for image display
        self.canvas = tk.Canvas(root, bg="black", highlightthickness=0)
        self.canvas.pack(fill=tk.BOTH, expand=True)

        # Counter label (top-right, subtle)
        self.counter = tk.Label(
            root, text="", fg="#666666", bg="black",
            font=("Helvetica", 14)
        )
        self.counter.place(relx=1.0, y=10, anchor="ne")

        # Bind keys
        self.root.bind("<Escape>", lambda e: self.quit())
        self.root.bind("q", lambda e: self.quit())
        self.root.bind("<Right>", lambda e: self.next())
        self.root.bind("<space>", lambda e: self.next())
        self.root.bind("<Left>", lambda e: self.prev())
        self.root.bind("p", lambda e: self.toggle_pause())

        # Force focus
        self.root.focus_force()
        self.root.lift()
        self.root.after(100, self.root.focus_force)

        # Start
        self.show_current()
        self.schedule_next()

    def show_current(self):
        if not self.files:
            return

        filepath = self.files[self.index]
        self.canvas.delete("all")

        try:
            pil_img = Image.open(filepath)
            pil_img = pil_img.convert("RGBA")

            self.root.update_idletasks()
            cw = self.canvas.winfo_width() or self.screen_w
            ch = self.canvas.winfo_height() or self.screen_h

            # Scale to fit, preserving aspect ratio (LANCZOS = high quality)
            iw, ih = pil_img.size
            scale = min(cw / iw, ch / ih)
            pil_img = pil_img.resize((int(iw * scale), int(ih * scale)), Image.LANCZOS)

            img = ImageTk.PhotoImage(pil_img)
            self.current_image = img  # prevent GC
            self.canvas.create_image(cw // 2, ch // 2, image=img, anchor="center")

        except Exception:
            self.canvas.create_text(
                self.screen_w // 2, self.screen_h // 2,
                text=f"Could not load:\n{os.path.basename(filepath)}",
                fill="#cc0000", font=("Helvetica", 24), justify="center"
            )

        self.counter.configure(text=f"{self.index + 1} / {len(self.files)}")

    def next(self):
        self.index = (self.index + 1) % len(self.files)
        self.show_current()
        self.reschedule()

    def prev(self):
        self.index = (self.index - 1) % len(self.files)
        self.show_current()
        self.reschedule()

    def toggle_pause(self):
        self.paused = not self.paused
        if self.paused:
            if self.timer_id:
                self.root.after_cancel(self.timer_id)
                self.timer_id = None
            self.counter.configure(fg="#ff6600")  # orange = paused
        else:
            self.counter.configure(fg="#666666")
            self.schedule_next()

    def schedule_next(self):
        if not self.paused:
            self.timer_id = self.root.after(self.interval * 1000, self._auto_next)

    def reschedule(self):
        if self.timer_id:
            self.root.after_cancel(self.timer_id)
        self.schedule_next()

    def _auto_next(self):
        self.next()

    def quit(self):
        self.root.destroy()


def main():
    parser = argparse.ArgumentParser(
        description="Fullscreen slideshow on any screen. One folder, one command.",
        epilog="Controls: Escape/Q=quit, Right/Space=next, Left=prev, P=pause"
    )
    parser.add_argument("folder", nargs="?", help="Folder to scan (default: folder picker dialog)")
    parser.add_argument("--interval", "-i", type=int, default=5, help="Seconds per slide (default: 5)")
    parser.add_argument("--shuffle", "-s", action="store_true", help="Randomize order")
    parser.add_argument("--screen", type=int, default=None, help="Screen index (default: secondary if available, else main)")
    args = parser.parse_args()

    # Get folder — dialog if not provided
    folder = args.folder
    if not folder:
        tmp = tk.Tk()
        tmp.withdraw()
        folder = filedialog.askdirectory(title="Choose folder for slideshow")
        tmp.destroy()
        if not folder:
            print("No folder selected.")
            sys.exit(1)

    folder = os.path.expanduser(folder)
    if not os.path.isdir(folder):
        print(f"Not a directory: {folder}")
        sys.exit(1)

    # Find images
    files = find_images(folder)
    if not files:
        print(f"No images found in {folder}")
        sys.exit(1)

    if args.shuffle:
        random.shuffle(files)

    print(f"{len(files)} images in {folder}")

    # Detect screens
    screens = get_screens()
    screen = None

    if args.screen is not None:
        # Explicit screen choice
        matches = [s for s in screens if s["index"] == args.screen]
        if matches:
            screen = matches[0]
        else:
            print(f"Screen {args.screen} not found, using main")
    elif len(screens) > 1:
        # Default: secondary screen
        screen = screens[1]

    if screen:
        print(f"Screen: {screen['name']} ({screen['w']}x{screen['h']})")
    else:
        print("Screen: main (fullscreen)")

    # Launch
    root = tk.Tk()
    root.title("Slideshow")
    Slideshow(root, files, screen, interval=args.interval)
    root.mainloop()


if __name__ == "__main__":
    main()
