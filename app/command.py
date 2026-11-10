import subprocess,sys,re
if len(sys.argv)==3 and sys.argv[1]=='workspace' and re.fullmatch('[1-6]',sys.argv[2]):
 result=subprocess.run(['hyprctl','dispatch','workspace',sys.argv[2]],capture_output=True)
 if result.returncode:subprocess.run(['hyprctl','eval','hl.dispatch(hl.dsp.workspace('+sys.argv[2]+'))'],capture_output=True)
