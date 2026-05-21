#!/usr/bin/env bash
# Double-click to open every Safari tab you'll need.
cd "$(dirname "$0")"
open -a Safari "https://github.com/jamiepine/voicebox/releases/latest"
open -a Safari "https://github.com/jamiepine/voicebox"
open -a Safari "http://127.0.0.1:17493/health"
echo "Opened 3 Safari tabs."
sleep 2
