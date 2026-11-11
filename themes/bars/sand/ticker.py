#!/usr/bin/env python3
"""Public ETH/USDT market price; sends no local or account data."""
import json,time,urllib.request
from pathlib import Path
cache=Path.home()/'.cache/bar-switcher/sand-ethusdt.json';data=None
try:data=json.loads(cache.read_text())
except (OSError,ValueError):pass
if not data or time.time()-data.get('fetched',0)>300:
 try:
  url='https://data-api.binance.vision/api/v3/ticker/24hr?symbol=ETHUSDT'
  with urllib.request.urlopen(url,timeout=5)as response:raw=json.load(response)
  data={'price':float(raw['lastPrice']),'change':float(raw['priceChangePercent']),'fetched':time.time()}
  cache.parent.mkdir(parents=True,exist_ok=True);cache.write_text(json.dumps(data))
 except Exception:pass
if data:
 stale=time.time()-data['fetched']>900
 print(json.dumps({'text':f"ETHUSDT {'↓'if data['change']<0 else'↑'} {data['price']:.1f}$",'tooltip':f"ETH/USDT • Binance public market data\n24h change: {data['change']:+.2f}%"+('\nLast available price'if stale else''),'class':'stale'if stale else'normal'}))
else:print(json.dumps({'text':'ETHUSDT —','tooltip':'Public market price unavailable','class':'unavailable'}))
