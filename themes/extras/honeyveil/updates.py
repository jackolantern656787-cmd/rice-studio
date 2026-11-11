#!/usr/bin/env python3
import json,subprocess
# Installed pacman database only: no refresh, sudo, network or package changes.
try:
 p=subprocess.run(['pacman','-Qu'],capture_output=True,text=True,timeout=8)
 n=len(p.stdout.splitlines());print(json.dumps({'text':'󰚰 '+str(n),'tooltip':'Updates known to the local package database; may be stale'}))
except Exception:print(json.dumps({'text':'󰚰 —','tooltip':'Update count unavailable'}))
