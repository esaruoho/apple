Goal: activate the new `!pk voice` command in pakettibot here. I SCP'd two files earlier; a daemon restart may have left commands.js without the wiring.

1) Verify the new file is present:
   ls -la /Users/esaruoho/work/pakettibot-agent/src/commands/voice-commands.js

2) Check src/commands.js has BOTH:
   - import { voice } from './commands/voice-commands.js';
   - in the handlers map next to `cloudcity: agentCommands.cloudcity,`:
       voice: voice,
       say: voice,
   If missing, add them (other commands/* imports show the pattern).

3) Restart pakettibot:
   pkill -f "node index.js" ; sleep 3
   (supervisor PPID 20790 respawns; if not: cd /Users/esaruoho/work/pakettibot-agent && nohup /opt/homebrew/bin/node index.js > /tmp/pakettibot-out.log 2>&1 &)

4) Verify exactly ONE pakettibot (kill stragglers):
   pgrep -fl "node index.js" | grep -v PDFWorkshop

5) Smoke-test via bridge:
   echo 'voice list' > /Users/esaruoho/work/comms/queue/pakettibot-inbox/voice-list-$(date +%s).cmd
   sleep 8
   cat /Users/esaruoho/work/comms/queue/pakettibot-outbox/voice-list-*.out.txt | tail -15
   Expect 6 profiles: Esa, Erickson, Bearden, Rob Teaching, Rob Sleep, Heart.

6) Commit + push so future restarts keep it:
   cd /Users/esaruoho/work/pakettibot-agent
   git add src/commands/voice-commands.js src/commands.js
   git commit -m "voice: !pk voice <profile> <text> command + archive"
   git push origin main

If voice list errors, check:
   curl -m 2 -sS http://127.0.0.1:17493/profiles | head
   launchctl print gui/$(id -u)/com.esa.voicebox-worker 2>&1 | grep -E "state|pid"

Once green: `!pk voice bearden "Talk to me about Tesla."` in Discord opens a thread with WAV attached; archive at ~/work/apple/voicebox-archive/index.jsonl by content-addressed id.
