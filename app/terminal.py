from pathlib import Path
import json,subprocess,os
h=Path.home();state=h/'.local/state/rice-studio-portable'
key=(state/'current').read_text().strip() if (state/'current').exists() else 'main'
p=h/'.config/rice-studio-portable/terminals'/(key+'.conf')
args=['kitty']+(['--config',str(p)] if p.is_file() and key!='main' else [])
os.execvp(args[0],args)
