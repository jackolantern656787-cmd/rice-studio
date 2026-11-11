#!/usr/bin/env python3
import subprocess,sys
ssid=sys.argv[1];password=sys.stdin.readline().rstrip('\n')
if not ssid or ssid.startswith('-') or len(ssid.encode())>32 or '\r' in password or len(password)>256:raise SystemExit(2)
p=subprocess.run(['nmcli','--ask','--wait','25','device','wifi','connect',ssid],input=password+'\n',text=True,capture_output=True,timeout=30)
if p.returncode:print('Could not connect. Check the password or connection settings.',file=sys.stderr)
raise SystemExit(p.returncode)
