"""Build a public repository archive from this kit, never from an installed DSH home."""
from pathlib import Path
import sys,subprocess,json,hashlib,zipfile,argparse
root=Path(__file__).resolve().parents[1]
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('output',nargs='?',type=Path)
parser.add_argument('--electron-archive',type=Path)
args=parser.parse_args()
manifest=json.loads((root/'manifest.json').read_text('utf-8'))
target=args.output.resolve() if args.output else root.parent/('dsh-env-kit-'+manifest['version']+'.zip')
if target.is_relative_to(root):raise SystemExit('Output must be outside the source kit.')
subprocess.run([sys.executable,str(root/'tests/audit.py')],check=True)
manifest=json.loads((root/'manifest.json').read_text('utf-8'))
if args.electron_archive:
 if hashlib.sha256(args.electron_archive.read_bytes()).hexdigest()!=manifest['companion']['sha256']:
  raise SystemExit('Electron archive checksum mismatch; no release produced.')
allowed={'README.md','LICENSE','manifest.json','payload-files.json','third-party.json','THIRD_PARTY_NOTICES.md',
         'CHECKSUMS.sha256','.gitignore','.github','scripts','tests','tools','docs','vendor'}
unexpected={p.name for p in root.iterdir()}-allowed-{'.git'}
if unexpected:raise SystemExit('Review unexpected root entries before packaging: '+repr(sorted(unexpected)))
files=[p for p in sorted(root.rglob('*')) if p.is_file() and '.git' not in p.relative_to(root).parts]
for p in files:
 if p.is_symlink():raise SystemExit('No linked release files: '+str(p))
 if set(p.relative_to(root).parts)&{'__pycache__','sessions','storages','.credentials','electron-user-data'}:raise SystemExit('Private/runtime directory in release')
checks=[hashlib.sha256(p.read_bytes()).hexdigest()+'  '+p.relative_to(root).as_posix() for p in files if p.name!='CHECKSUMS.sha256']
(root/'CHECKSUMS.sha256').write_text('\n'.join(checks)+'\n',encoding='utf-8')
files=[p for p in sorted(root.rglob('*')) if p.is_file() and '.git' not in p.relative_to(root).parts]
with zipfile.ZipFile(target,'w',zipfile.ZIP_DEFLATED,compresslevel=2) as archive:
 for p in files:archive.write(p,'dsh-env-kit/'+p.relative_to(root).as_posix())
digest=hashlib.sha256(target.read_bytes()).hexdigest()
target.with_suffix(target.suffix+'.sha256').write_text(digest+'  '+target.name+'\n',encoding='utf-8')
print(json.dumps({'archive':target.name,'bytes':target.stat().st_size,'sha256':digest}))
release_files=[target]
if args.electron_archive:
 offline=target.with_name('dsh-env-kit-'+manifest['version']+'-offline-win-x64.zip')
 guide='''# 完整离线安装（Windows x64）

> **CHAT 已修复文字头像账号密码登录后空白。** 当前为 0.2.26 修复候选（PR #20 待作者处理），已实际验证登录、切换、刷新和重启。详细来源及验证边界见 `dsh-env-kit/docs/chat-text-avatar-0.2.26.md`。

先安装官方 DSH 0.2.2-rc.1 与 PowerShell 7。本包不含 DSH 主程序、模型、个人配置或密钥。
把整个压缩包解压到同一个目录，保留 dsh-env-kit 文件夹与 electron-v45.1.0-win32-x64.zip 的相对位置。
在解压目录打开 PowerShell 7，进入 dsh-env-kit：

```powershell
cd .\\dsh-env-kit
pwsh -NoProfile -ExecutionPolicy Bypass -File .\\scripts\\Install-DSHKit.ps1 `
  -DshExe 'C:\\Apps\\DSH\\DeepSeek Harness.exe' `
  -DshHome 'C:\\DSH-kit-home' `
  -ElectronArchive '..\\electron-v45.1.0-win32-x64.zip'
pwsh -NoProfile -ExecutionPolicy Bypass -File .\\scripts\\Start-DSH.ps1 `
  -DshHome 'C:\\DSH-kit-home'
```

请把官方程序路径换成自己的安装位置，并为 DshHome 选择一个尚不存在的新目录。
安装后在设置里填写自己的云端密钥或本地模型路径。完整说明、校验与回滚步骤见 dsh-env-kit/README.md。
'''
 with zipfile.ZipFile(offline,'w',zipfile.ZIP_STORED) as archive:
  for p in files:archive.write(p,'dsh-env-kit/'+p.relative_to(root).as_posix())
  archive.write(args.electron_archive,'electron-v45.1.0-win32-x64.zip')
  archive.writestr('INSTALL-OFFLINE.zh-CN.md',guide.encode('utf-8'))
 release_files.append(offline)
 print(json.dumps({'offlineArchive':offline.name,'bytes':offline.stat().st_size}))
sumfile=target.with_name('dsh-env-kit-'+manifest['version']+'-SHA256SUMS.txt')
sumfile.write_text(''.join(hashlib.sha256(p.read_bytes()).hexdigest()+'  '+p.name+'\n' for p in release_files),encoding='utf-8')
