# -*- coding: utf-8 -*-
"""只抓「写入类」操作：下载落盘 / 复制目标 / 新建 / 写文件 / 解压目标 / 注册表写入 / 任务服务 / 启动进程。
输出 temp/steamcn/samples-writes.md，带行号便于人工复核。
"""
import os, re, io

ROOT = r'D:\Dev\SteamSPA'
SCRIPTS = os.path.join(ROOT, 'scripts')
OUT = os.path.join(ROOT, 'temp', 'steamcn', 'samples-writes.md')

PATS = [
    ('OutFile', re.compile(r'-(?:OutFile|Destination)\s+("([^"]{1,160})"|\'([^\']{1,160})\'|(\$[\w:.]+))', re.I)),
    ('Copy', re.compile(r'Copy-Item\s+[^\r\n]{0,200}', re.I)),
    ('Move', re.compile(r'Move-Item\s+[^\r\n]{0,200}', re.I)),
    ('NewItem', re.compile(r'New-Item\s+[^\r\n]{0,200}', re.I)),
    ('WriteFile', re.compile(r'\[(?:System\.)?IO\.File\]::(?:WriteAllText|WriteAllBytes|WriteAllLines|AppendAllText|Create)\s*\(\s*("([^"]{1,160})"|\$[\w:.]+)', re.I)),
    ('SetContent', re.compile(r'(?:Set-Content|Add-Content|Out-File)\s+[^\r\n]{0,200}', re.I)),
    ('Expand', re.compile(r'Expand-Archive\s+[^\r\n]{0,220}', re.I)),
    ('RegWrite', re.compile(r'(?:New-ItemProperty|Set-ItemProperty|Remove-ItemProperty)\s+[^\r\n]{0,220}', re.I)),
    ('RegNew', re.compile(r'New-Item\s+-Path\s+["\']?(HKCU|HKLM|HKEY_[A-Z_]+)[^\r\n]{0,200}', re.I)),
    ('Task', re.compile(r'(?:schtasks[^\r\n]{0,200}|Register-ScheduledTask[^\r\n]{0,200})', re.I)),
    ('Service', re.compile(r'(?:\bsc(?:\.exe)?\s+create[^\r\n]{0,160}|New-Service[^\r\n]{0,160})', re.I)),
    ('StartProc', re.compile(r'Start-Process\s+[^\r\n]{0,160}', re.I)),
    ('Defender', re.compile(r'Add-MpPreference\s+[^\r\n]{0,180}', re.I)),
    ('Firewall', re.compile(r'(?:netsh\s+advfirewall[^\r\n]{0,180}|New-NetFirewallRule[^\r\n]{0,180})', re.I)),
    ('NetConfig', re.compile(r'(?:netsh\s+winhttp[^\r\n]{0,160}|Set-DnsClientServerAddress[^\r\n]{0,160}|Set-ItemProperty\s+-Path\s+"HKLM:[^"]*Tcpip[^\r\n]{0,140})', re.I)),
]

def main():
    files = []
    for dirpath, _, names in os.walk(SCRIPTS):
        for n in sorted(names):
            if n.lower().endswith('.ps1'):
                files.append(os.path.join(dirpath, n))
    files.sort()

    out = io.open(OUT, 'w', encoding='utf-8')
    out.write('# 样本「写入类」操作明细（人工复核用）\n\n')
    total = 0
    for f in files:
        rel = os.path.relpath(f, ROOT)
        text = io.open(f, encoding='utf-8', errors='replace').read()
        lines = text.split('\n')
        hits = []
        for i, ln in enumerate(lines, 1):
            s = ln.strip()
            if not s or s.startswith('#'):
                continue
            for tag, rx in PATS:
                for m in rx.finditer(ln):
                    raw = re.sub(r'\s+', ' ', m.group(0)).strip()[:185]
                    hits.append((i, tag, raw))
                    break
        out.write('## %s  (%d 行, %d 命中)\n\n' % (rel, len(lines), len(hits)))
        for i, tag, raw in hits:
            out.write('- `%d` **%s** %s\n' % (i, tag, raw))
        out.write('\n')
        total += len(hits)
    out.close()
    print('files=%d hits=%d' % (len(files), total))

if __name__ == '__main__':
    main()
