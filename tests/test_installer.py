from pathlib import Path
import unittest,tempfile,os,sys,json,importlib.util,shutil
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT))
import install,uninstall
class Installer(unittest.TestCase):
 def setUp(self):
  self.temp=tempfile.TemporaryDirectory();self.home=Path(self.temp.name);self.previous=os.environ.get('RICE_STUDIO_HOME');os.environ['RICE_STUDIO_HOME']=str(self.home)
  self.oldpath=os.environ['PATH'];bindir=self.home/'mock-bin';bindir.mkdir()
  tool=bindir/'hyprctl';tool.write_text('''#!/usr/bin/env python3
import sys,json
if sys.argv[1]=='getoption':
 key=sys.argv[2]
 print(json.dumps({'gradient':'abcdef12 0deg'} if key.endswith('border') and 'col.' in key else {'css':'4 4 4 4'} if 'gaps' in key else {'int':8}))
elif sys.argv[1]=='version':print('Hyprland 0.57.0')
else:print('ok')
''');tool.chmod(0o755)
  os.environ['PATH']=str(bindir)+':'+self.oldpath
 def tearDown(self):
  os.environ['PATH']=self.oldpath
  if self.previous is None:os.environ.pop('RICE_STUDIO_HOME',None)
  else:os.environ['RICE_STUDIO_HOME']=self.previous
  self.temp.cleanup()
 def test_check_is_read_only(self):
  before=set(self.home.rglob('*'));install.install(self.home,True,False);self.assertEqual(before,set(self.home.rglob('*')))
 def test_install_upgrade_and_uninstall(self):
  original=self.home/'.config/hypr/hyprland.conf';original.parent.mkdir(parents=True);original.write_text('MY MONITORS AND BINDS')
  install.install(self.home,check_deps=False)
  state=self.home/'.local/state/rice-studio-portable';baseline=state/'original-main.json';first=baseline.read_bytes();profiles=self.home/'.config/rice-studio-portable/profiles.json'
  data=json.loads(profiles.read_text());self.assertEqual(len(data),17);data['monochrome']['label']='Personal edit';profiles.write_text(json.dumps(data))
  notes=self.home/'.local/share/rice-studio-portable/user-file.txt';notes.write_text('keep')
  install.install(self.home,check_deps=False)
  self.assertEqual(first,baseline.read_bytes());self.assertEqual(json.loads(profiles.read_text())['monochrome']['label'],'Personal edit')
  self.assertEqual(original.read_text(),'MY MONITORS AND BINDS')
  uninstall.uninstall(self.home,restore=False)
  self.assertTrue(profiles.exists());self.assertTrue(notes.exists());self.assertTrue(baseline.exists());self.assertFalse((self.home/'.local/bin/rice-studio').exists())
 def test_kitty_follows_presets_and_restores_main(self):
  kitty=self.home/'.config/kitty/kitty.conf'
  kitty.parent.mkdir(parents=True)
  original='background #123456'
  kitty.write_text(original)
  install.install(self.home,check_deps=False)
  app=self.home/'.local/share/rice-studio-portable'
  state=self.home/'.local/state/rice-studio-portable'
  config=state/'kitty-active.conf'
  self.assertEqual(config.read_text(),'')
  adapter=install.load(app/'control.py','kitty_test_control')
  adapter.write_current('tideglass')
  self.assertIn('/terminals/tideglass.conf',config.read_text())
  self.assertIn('terminal-shell tideglass',config.read_text())
  adapter.set_options=lambda _:None
  adapter.start_components=lambda:None
  adapter.restore_snapshot(adapter.ensure_main())
  self.assertEqual(config.read_text(),'')
  install.install(self.home,check_deps=False)
  self.assertEqual(kitty.read_text().count('include '+str(config)),1)
  uninstall.uninstall(self.home,restore=False)
  self.assertEqual(kitty.read_text(),original)

 def test_collision_does_not_overwrite(self):
  p=self.home/'.local/bin/rice-studio';p.parent.mkdir(parents=True);p.write_text('original')
  with self.assertRaises(RuntimeError):install.install(self.home,check_deps=False)
  self.assertEqual(p.read_text(),'original');self.assertFalse((self.home/'.local/state/rice-studio-portable/original-main.json').exists())
 def test_bad_baseline_does_not_reset(self):
  p=self.home/'.local/state/rice-studio-portable/original-main.json';p.parent.mkdir(parents=True);p.write_text('{}')
  with self.assertRaises(ValueError):install.install(self.home,check_deps=False)
  self.assertEqual(p.read_text(),'{}')
 def test_adapter_exact_options_and_failure(self):
  m=install.load(ROOT/'app/control.py','adapter_test');value=m.ensure_main();self.assertEqual(value['options']['general:col.active_border'],'rgba(cdef12ab) 0deg')
  first=json.dumps(value);self.assertEqual(first,json.dumps(m.ensure_main()))
  calls=[];m.run=lambda args:(calls.append(args) or 'Hyprland 0.57.0' if args[1]=='version' else calls.append(args) or 'ok')
  m.set_options(value['options']);self.assertTrue(any(a[1]=='eval' for a in calls));code=next(a[2] for a in calls if a[1]=='eval');self.assertIn('["colors"]',code);self.assertIn('["top"]',code)
if __name__=='__main__':unittest.main()
