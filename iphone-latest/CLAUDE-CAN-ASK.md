# "Claude, show me" — letting a Claude session ask for an iPhone photo

**Question (2026-11-10):** can Claude say "show me that thing", Esa takes a photo, and this session gets it? Is that MCP?

## Yes, and the pieces already exist

Claude can already look at images: the Read tool renders a JPEG straight into the session. The missing piece is a command Claude can run that:

1. tells iPhoneLatest.app to open the iPhone camera,
2. waits for Esa to shoot and tap Use Photo,
3. prints the saved path.

Claude then Reads that path and sees the photo.

## Two ways to wire it

### A. URL scheme + CLI (recommended first)
- iPhoneLatest.app registers `iphonelatest://take`, which does exactly what clicking 📱 does.
- `bin/iphone-snap` opens that URL, waits for the next `~/Pictures/iPhone-Latest/Continuity-*.jpg` to appear (with a timeout), and prints its path.
- Claude runs `bin/iphone-snap`, then Reads the path. Zero dependencies, works in this repo today, and it's the zero-roundtrip pattern the apple skill already uses.

### B. MCP server (the general version)
- MCP (Model Context Protocol) is exactly this concept: a small server that offers tools a model can call. Here that would be `take_iphone_photo` → returns the image.
- Pros: works in any MCP client (Claude Code in any repo, Claude Desktop) without Bash, and the image comes back directly as tool output.
- Cons: one more process and config entry. It would call the same `iphonelatest://take` + wait logic underneath.

## Recommendation
Build A first: the URL scheme plus `bin/iphone-snap`, plus a note in the apple skill telling Claude when to use it. Wrap it as an MCP server (B) once it's proven, so other repos and Claude Desktop get it too.
