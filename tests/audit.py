"""Offline public release audit. No account, model or original-machine files needed."""
from pathlib import Path, PurePosixPath
import hashlib, io, json, re, sys, tarfile, zipfile
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
    assert set(profile['dependencies'])=={p['name'] for p in manifest['plugins']}
    assert profile['dsh']['profile']['bundles']==manifest['bundles']
    for plugin in manifest['plugins']:
        name=plugin['name']
        source=plugin.get('source',plugin['version'])
        assert profile['dependencies'][name]==source
        installed_root='profiles/desktop/node_modules/'+name+'/'
        assert json.loads(z.read(installed_root+'package.json'))['version']==plugin['version']
        assert 'source' in plugin, 'Every shipped plugin must be reproducible from its local archive'
        if 'source' in plugin:
            # Only a checked-in, relative, immutable tarball is allowed as a pin.
            assert source.startswith('file:./pinned-packages/')
            relative=source[len('file:./'):]
            assert '..' not in PurePosixPath(relative).parts and ':' not in relative and '\\' not in relative
            tarbytes=z.read('profiles/desktop/'+relative)
            assert hashlib.sha256(tarbytes).hexdigest()==plugin['sha256']
            with tarfile.open(fileobj=io.BytesIO(tarbytes)) as t:
                for item in t:
                    assert not item.issym() and not item.islnk()
                    assert item.name.startswith('package/') and '..' not in PurePosixPath(item.name).parts
                    if item.isfile():
                        assert t.extractfile(item).read()==z.read(installed_root+item.name[len('package/'):]),item.name
        else:
            assert re.fullmatch(r'\d+\.\d+\.\d+(?:[-+][\w.-]+)?',source),source
    assert profile['dshEnvKit']['version']==manifest['version']
    assert 'profiles/desktop/pnpm-lock.yaml' in actual
    voice=next(p for p in manifest['plugins'] if p['name']=='dsh-gemini-voice')
    assert voice['version']=='0.3.7' and voice['release']=='v0.3.7'
    chat=next(p for p in manifest['plugins'] if p['name']=='dsh-deepseek-chat')
    assert chat['source'].startswith('file:./pinned-packages/')
    chatroot='profiles/desktop/node_modules/dsh-deepseek-chat/'
    chatmeta=json.loads(z.read(chatroot+'package.json'))
    assert json.loads(z.read(chatroot+'node_modules/zod/package.json'))['version']==chatmeta['dependencies']['zod']
    patch=z.read('profiles/desktop/cordis.patch.yml').decode()
    assert all(key not in patch for key in ['apiKey:','llamaDir:','providers:'])
assert not failures,json.dumps(failures,ensure_ascii=False)
print(json.dumps({'passed':True,'filesChecked':len(expected),'plugins':len(manifest['plugins']),'pinnedGoogleLogin':True,'secretAndPathFindings':0}))
