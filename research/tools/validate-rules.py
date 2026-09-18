# -*- coding: utf-8 -*-
"""校验 uninstall.ps1 内嵌的规则 JSON。

用法：python tools/validate-rules.py [uninstall.ps1 路径]

不要写死行号范围抽 JSON —— 规则增删会让边界漂移（2026-09-15 踩过）。
用 here-string 锚点 + 括号配对定位，自动跳过字符串内的花括号。
"""
import json, os, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PATH = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, 'uninstall.ps1')

t = open(PATH, encoding='utf-8').read()
anchor = t.find('$EmbeddedTargetsJson = @')
if anchor < 0:
    print('FAIL: anchor $EmbeddedTargetsJson not found')
    sys.exit(1)
body_start = t.find('{', anchor)

depth, in_str, esc, end = 0, False, False, None
i = body_start
while i < len(t):
    c = t[i]
    if esc:
        esc = False
    elif c == '\\':
        esc = True
    elif c == '"':
        in_str = not in_str
    elif not in_str:
        if c == '{':
            depth += 1
        elif c == '}':
            depth -= 1
            if depth == 0:
                end = i + 1
                break
    i += 1

print('json range: line %d ~ %d (%d chars)' % (
    t[:body_start].count('\n') + 1, t[:end].count('\n') + 1, end - body_start))

try:
    cfg = json.loads(t[body_start:end])
except Exception as e:
    print('JSON FAIL: %r' % e)
    sys.exit(1)

rules = cfg['rules']
print('JSON OK  rules=%d' % len(rules))

ids = [r['id'] for r in rules]
dup = sorted({x for x in ids if ids.count(x) > 1})
print('dup-ids: %s' % (','.join(dup) if dup else '(none)'))

dis = [r['id'] for r in rules if not r.get('enabled')]
print('disabled: %s' % (','.join(dis) if dis else '(none)'))

ty = sorted({a['type'] for r in rules for a in r['actions']})
print('action-types: %s' % ','.join(ty))

missing, refs = [], set()
for r in rules:
    for s in r.get('sources', []):
        if s.startswith('scripts/'):
            refs.add(s)
            if not os.path.exists(os.path.join(ROOT, s.replace('/', '\\'))):
                missing.append(s)
print('source-refs: %d   missing: %s' % (len(refs), ','.join(sorted(set(missing))) or '(none)'))

if dup or missing:
    sys.exit(2)
print('ALL CHECKS PASSED')
