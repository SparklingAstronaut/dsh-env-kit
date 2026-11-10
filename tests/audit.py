"""Offline public release audit. No account, model or original-machine files needed."""
from pathlib import Path, PurePosixPath
import hashlib, json, re, sys, zipfile
root=Path(__file__).resolve().parents[1]
manifest=json.loads((root/'manifest.json').read_text('utf-8'))
archive=root/manifest['payload']['file']
assert hashlib.sha256(archive.read_bytes()).hexdigest()==manifest['payload']['sha256']
expected=json.loads((root/'payload-files.json').read_text('utf-8'))
failures=[]
forbidden_dirs={'sessions','storages','.credentials','electron-user-data','.git'}
with zipfile.ZipFile(archive) as z:
    actual={p.filename for p in z.infolist() if not p.is_dir()}
    assert actual==set(expected),'Unexpected or missing payload files'
    for name in sorted(actual):
        parts=PurePosixPath(name).parts
        assert not (set(parts)&forbidden_dirs) and '..' not in parts
        assert not name.startswith('/') and ':' not in name
        data=z.read(name)
        assert hashlib.sha256(data).hexdigest()==expected[name],name
        assert not name.endswith(('.gguf','.safetensors','.log','.bak','.sqlite'))
        try:text=data.decode('utf-8-sig')
        except UnicodeError:continue
        # Upstream examples use u, me, ..., and the ellipsis character, not real user identities.
        for rule in [r'(?i)(?<![\w])[A-Z]:[\\/]+Users[\\/]+(?![\\/])(?!(?:Public|Default|u|me)(?:[\\/]|\b)|\.{3}|…|<)[^\s"<>]+',
                     r'(?i)[A-Z]:[\\/]+AI[\\/]',
                     r'(?<![\w-])sk-[A-Za-z0-9]{24,}',r'AIza[A-Za-z0-9_-]{30,}',
                     r'-----BEGIN (?:RSA |OPENSSH )?PRIVATE KEY-----']:
            if re.search(rule,text):failures.append({'file':name,'rule':rule})
    profile=json.loads(z.read('profiles/desktop/package.json'))
    assert len(profile['dependencies'])==13
    assert set(profile['dependencies'])=={p['name'] for p in manifest['plugins']}
    assert all(not v.startswith(('file:','link:','^','~')) for v in profile['dependencies'].values())
    patch=z.read('profiles/desktop/cordis.patch.yml').decode()
    assert all(key not in patch for key in ['apiKey:','llamaDir:','providers:'])
assert not failures,json.dumps(failures,ensure_ascii=False)
print(json.dumps({'passed':True,'filesChecked':len(expected),'plugins':13,'secretAndPathFindings':0}))
