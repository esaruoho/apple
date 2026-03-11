#!/usr/bin/env python3
"""GitHub Watcher Dashboard — serves PR & CI status on port 3008.
Same pattern as climate-server.py on port 3007."""

import http.server
import json
import os
import sys

PORT = 3008
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
STATE_DIR = os.path.join(SCRIPT_DIR, ".state")
REPOS_FILE = os.path.join(SCRIPT_DIR, "repos.json")


def load_repos():
    with open(REPOS_FILE) as f:
        return json.load(f)


def load_state(owner, repo, kind):
    safe = f"{owner}_{repo}_{kind}.json"
    path = os.path.join(STATE_DIR, safe)
    if os.path.exists(path):
        try:
            with open(path) as f:
                return json.load(f)
        except (json.JSONDecodeError, IOError):
            return []
    return []


def get_status():
    repos_config = load_repos()
    repos = []
    for entry in repos_config:
        owner = entry["owner"]
        repo = entry["repo"]
        repos.append({
            "owner": owner,
            "name": repo,
            "label": entry.get("label", repo),
            "group": entry.get("group", "Other"),
            "prs": load_state(owner, repo, "prs"),
            "runs": load_state(owner, repo, "runs"),
        })
    return {"repos": repos}


class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=SCRIPT_DIR, **kwargs)

    def do_GET(self):
        if self.path == "/api/status":
            data = json.dumps(get_status())
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Access-Control-Allow-Origin", "*")
            self.end_headers()
            self.wfile.write(data.encode())
        elif self.path == "/":
            self.path = "/dashboard.html"
            super().do_GET()
        else:
            super().do_GET()

    def log_message(self, format, *args):
        pass  # silent


if __name__ == "__main__":
    server = http.server.HTTPServer(("", PORT), Handler)
    print(f"GitHub Watcher dashboard: http://localhost:{PORT}")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nStopped.")
        sys.exit(0)
