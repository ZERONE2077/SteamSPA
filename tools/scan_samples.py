# -*- coding: utf-8 -*-
"""扫描 scripts/ 下全部假入库样本，提取落地物（文件/目录/注册表/任务/服务/进程/排除/URL），
并与 uninstall.ps1 内嵌规则的条目比对，输出缺口。

输出：
  temp/steamcn/samples-artifacts.md  明细
  temp/steamcn/samples-gap.md        缺口比对
"""
import os, re, json, io, sys
from collections import OrderedDict

ROOT = r'D:\Dev\SteamSPA'
SCRIPTS = os.path.join(ROOT, 'scripts')
OUT_ART = os.path.join(ROOT, 'temp', 'steamcn', 'samples-artifacts.md')
OUT_GAP = os.path.join(ROOT, 'temp', 'steamcn', 'samples-gap.md')

VAR_MAP = [
    (re.compile(r'^steampath$|^steam$|^spath$', re.I), '${SteamPath}'),
    (re.compile(r'^env:localappdata$|^localappdata$', re.I), '${LOCALAPPDATA}'),
    (re.compile(r'^env:appdata$|^appdata$', re.I), '${APPDATA}'),
    (re.compile(r'^env:temp$|^temp$|^tempdir$|^tmpdir$', re.I), '${TEMP}'),
    (re.compile(r'^env:programfiles$|^env:programfiles\(x86\)$', re.I), '${ProgramFiles}'),
    (re.compile(r'^env:userprofile$|^userprofile$', re.I), '${USERPROFILE}'),
    (re.compile(r'^psscriptroot$|^scriptroot$', re.I), '${ScriptRoot}'),
]

def norm_var(v):
    name = v.lstrip('$').strip()
    for rx, repl in VAR_MAP:
        if rx.match(name):
            return repl
    return '?<' + name + '>'

def norm_path(p):
    p = p.strip().strip('"').strip("'")
    p = p.replace('/', '\\')
    p = re.sub(r'\\+', lambda m: '\\', p)
    p = re.sub(r'\\+$', '', p)
    return p

JOIN = re.compile(r'Join-Path\s+(\$[\w:.]+)\s+(?:"([^"]{1,160})"|\'([^\']{1,160})\')', re.I)
LIT_WIN = re.compile(r'"([A-Za-z]:\\[^"<>|\r\n]{2,140})"')
REG = re.compile(r'((?:HKCU|HKLM|HKEY_[A-Z_]+)[:\\][\\\w\s\.\-\{\}\(\)]{2,140})', re.I)
OUTFILE = re.compile(r'-(?:OutFile|DestinationPath|Destination|LiteralPath|FilePath)\s+(?:"([^"]{1,160})"|\'([^\']{1,160})\')', re.I)
URL = re.compile(r'https?://([\w\.\-]{3,80})')
EXCL_PATH = re.compile(r'Add-MpPreference\s+-ExclusionPath\s+(?:"([^"]+)"|(\$[\w:.]+))', re.I)
EXCL_EXT = re.compile(r'Add-MpPreference\s+-ExclusionExtension\s+(?:"([^"]+)"|(\$[\w:.]+))', re.I)
EXCL_PROC = re.compile(r'Add-MpPreference\s+-ExclusionProcess\s+(?:"([^"]+)"|(\$[\w:.]+))', re.I)
KEYWORD = [
    ('计划任务', re.compile(r'(schtasks[^\r\n]{0,200}|Register-ScheduledTask[^\r\n]{0,200})', re.I)),
    ('服务', re.compile(r'(\bsc(?:\.exe)?\s+create[^\r\n]{0,160}|New-Service[^\r\n]{0,160})', re.I)),
    ('启动项', re.compile(r'(CurrentVersion\\Run[^\r\n"]{0,80}|shell:startup[^\r\n"]{0,60})', re.I)),
    ('进程', re.compile(r'Start-Process\s+(?:-FilePath\s+)?(?:"([^"]{1,120})"|(\S{1,120}))', re.I)),
    ('注册表写入', re.compile(r'(New-ItemProperty[^\r\n]{0,200}|Set-ItemProperty[^\r\n]{0,200}|reg\s+add[^\r\n]{0,200})', re.I)),
]

def scan(text):
    res = OrderedDict()
    res['steam_root'] = []
    res['other_paths'] = []
    res['registry'] = []
    res['exclusions'] = []
    res['keywords'] = OrderedDict((k, []) for k, _ in KEYWORD)
    res['urls'] = []
    res['dynamic'] = []

    for m in JOIN.finditer(text):
        var = m.group(1)
        sub = m.group(2) or m.group(3) or ''
        base = norm_var(var)
        full = norm_path(base + '\\' + sub) if sub else base
        if base == '${SteamPath}':
            res['steam_root'].append(full)
        elif base.startswith('?<'):
            res['dynamic'].append(full + '   [from %s]' % var)
        else:
            res['other_paths'].append(full)

    for m in LIT_WIN.finditer(text):
        p = norm_path(m.group(1))
        if re.search(r'(steam|\\dll|\\exe)', p, re.I):
            res['other_paths'].append(p)

    for m in REG.finditer(text):
        res['registry'].append(norm_path(m.group(1)))

    for m in OUTFILE.finditer(text):
        res['other_paths'].append('(outfile) ' + norm_path(m.group(1) or m.group(2)))

    for rx, tag in ((EXCL_PATH, 'path'), (EXCL_EXT, 'ext'), (EXCL_PROC, 'proc')):
        for m in rx.finditer(text):
            v = m.group(1) or m.group(2)
            res['exclusions'].append('[%s] %s' % (tag, v))

    for k, rx in KEYWORD:
        for m in rx.finditer(text):
            s = (m.group(0) or '').strip()
            if s:
                res['keywords'][k].append(re.sub(r'\s+', ' ', s)[:170])

    for m in URL.finditer(text):
        res['urls'].append(m.group(1).lower())

    for k in res:
        if isinstance(res[k], list):
            seen = []
            for x in res[k]:
                if x not in seen:
                    seen.append(x)
            res[k] = seen
        elif isinstance(res[k], OrderedDict):
            for kk in res[k]:
                seen = []
                for x in res[k][kk]:
                    if x not in seen:
                        seen.append(x)
                res[k][kk] = seen
    return res

def rules():
    p = os.path.join(ROOT, 'uninstall.ps1')
    lines = io.open(p, encoding='utf-8', errors='replace').read().split('\n')
    chunk = '\n'.join(lines[62:997])
    cfg = json.loads(chunk)
    items = []
    for r in cfg['rules']:
        for a in r.get('actions', []):
            items.append({
                'rule': r['id'], 'risk': r.get('risk'), 'type': a.get('type'),
                'path': a.get('path'), 'name': a.get('name'), 'contains': a.get('contains'),
            })
    return cfg, items

def main():
    cfg, ritems = rules()
    files = []
    for dirpath, _, names in os.walk(SCRIPTS):
        for n in sorted(names):
            if n.lower().endswith(('.ps1', '.txt', '.html')):
                files.append(os.path.join(dirpath, n))
    files.sort()

    art = io.open(OUT_ART, 'w', encoding='utf-8')
    art.write('# scripts/ 全部样本落地物扫描\n\n共 %d 个文件\n\n' % len(files))

    sample_steam = []
    sample_reg = []
    for f in files:
        rel = os.path.relpath(f, ROOT)
        try:
            text = io.open(f, encoding='utf-8', errors='replace').read()
        except Exception as e:
            art.write('## %s\n读取失败: %s\n\n' % (rel, e))
            continue
        r = scan(text)
        art.write('## %s   (%d bytes)\n\n' % (rel, len(text.encode('utf-8', 'replace'))))
        def dump(title, arr):
            if arr:
                art.write('**%s**\n\n```\n' % title)
                art.write('\n'.join(arr[:120]))
                art.write('\n```\n\n')
        dump('Steam 根目录', r['steam_root'])
        dump('其他路径', r['other_paths'])
        dump('注册表', r['registry'])
        dump('Defender 排除', r['exclusions'])
        for k, v in r['keywords'].items():
            dump(k, v[:25])
        dump('域名', sorted(set(r['urls']))[:40])
        dump('动态路径(变量未识别)', r['dynamic'][:30])
        sample_steam += r['steam_root']
        sample_reg += r['registry']

    # ---- 归一化去重 ----
    def key(p):
        p = p.lower().replace('/', '\\')
        p = p.replace('${steampath}', '')
        p = re.sub(r'^\\+', '', p)
        return p

    s_all = OrderedDict()
    for p in sample_steam:
        p2 = p.replace('${SteamPath}\\', '').replace('${SteamPath}', '')
        s_all.setdefault(p2, []).append(p)
    rule_all = OrderedDict()
    for it in ritems:
        if it['path']:
            rp = it['path'].replace('${SteamPath}\\', '').replace('${SteamPath}', '')
            rule_all.setdefault(rp.lower(), []).append(it)

    gap = []
    for name in s_all:
        if name.lower() not in rule_all:
            gap.append(name)
    covered = [n for n in s_all if n.lower() in rule_all]

    g = io.open(OUT_GAP, 'w', encoding='utf-8')
    g.write('# 样本 vs uninstall.ps1 缺口\n\n')
    g.write('- 样本里出现的 Steam 根条目（去重）：**%d**\n' % len(s_all))
    g.write('- 规则已覆盖：**%d**\n' % len(covered))
    g.write('- **缺口：%d**\n\n' % len(gap))
    g.write('## 缺口清单（样本有 / 规则无）\n\n```\n')
    g.write('\n'.join(sorted(gap, key=str.lower)))
    g.write('\n```\n\n## 已覆盖\n\n```\n')
    g.write('\n'.join(sorted(covered, key=str.lower)))
    g.write('\n```\n\n')
    g.write('## 注册表（样本出现，未去重）\n\n```\n')
    g.write('\n'.join(sorted(set(sample_reg), key=str.lower)))
    g.write('\n```\n')
    g.close()
    art.close()
    print('files=%d steam=%d gap=%d' % (len(files), len(s_all), len(gap)))

if __name__ == '__main__':
    main()
