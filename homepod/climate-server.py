#!/usr/bin/env python3
"""Minimal local server for the climate dashboard.
Serves static files and provides /update endpoint to trigger a new reading."""

import http.server
import json
import os
import re
import subprocess
import sys

PORT = 3007
ENV_DIR = os.path.dirname(os.path.abspath(__file__))
LOG_DIR = os.path.join(ENV_DIR, "climate-logs")
SCRIPT = os.path.join(ENV_DIR, "homepod-climate.sh")

DATE_RE = re.compile(r"^\d{4}-\d{2}-\d{2}$")


class ClimateHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=ENV_DIR, **kwargs)

    def do_GET(self):
        if self.path == "/api/days":
            return self._api_days()
        m = re.match(r"^/api/day/(\d{4}-\d{2}-\d{2})$", self.path)
        if m:
            return self._api_day(m.group(1))
        return super().do_GET()

    def _api_days(self):
        days = sorted(
            f.replace(".jsonl", "")
            for f in os.listdir(LOG_DIR)
            if f.endswith(".jsonl") and DATE_RE.match(f.replace(".jsonl", ""))
        )
        self._json_response(days)

    def _api_day(self, date):
        if not DATE_RE.match(date):
            self._json_response({"error": "invalid date"}, 400)
            return
        path = os.path.join(LOG_DIR, date + ".jsonl")
        if not os.path.isfile(path):
            self._json_response([], 200)
            return
        readings = []
        with open(path) as f:
            for line in f:
                line = line.strip()
                if line:
                    readings.append(json.loads(line))
        self._json_response(readings)

    def _json_response(self, data, status=200):
        body = json.dumps(data).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        self.wfile.write(body)

    def do_POST(self):
        if self.path == "/update":
            try:
                result = subprocess.run(
                    [SCRIPT, "--stdout"],
                    capture_output=True, text=True, timeout=30
                )
                # Also run full logging version
                subprocess.run([SCRIPT], capture_output=True, text=True, timeout=30)
                self._json_response(
                    json.loads(result.stdout.strip()) if result.stdout.strip() else {}
                )
            except Exception as e:
                self._json_response({"error": str(e)}, 500)
        else:
            self.send_response(404)
            self.end_headers()

    def log_message(self, format, *args):
        pass  # silent


if __name__ == "__main__":
    print(f"Climate dashboard: http://localhost:{PORT}/climate-graph.html")
    server = http.server.HTTPServer(("0.0.0.0", PORT), ClimateHandler)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nStopped.")
