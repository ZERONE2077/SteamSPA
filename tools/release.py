# -*- coding: utf-8 -*-
"""SteamSPA 发布：commit + push（push 必须走 python，见 docs/维护笔记.md）。"""
import subprocess, sys, io, os

ROOT = r'D:\Dev\SteamSPA'


def run(args):
    p = subprocess.run(['git'] + args, cwd=ROOT, capture_output=True,
                       text=True, encoding='utf-8', errors='replace', timeout=300)
    return p.returncode, (p.stdout or ''), (p.stderr or '')


def main():
    msg_file = sys.argv[1] if len(sys.argv) > 1 else None
    out = []

    rc, so, se = run(['status', '--porcelain'])
    if not (so + se).strip():
        print('nothing to commit')
        return 0

    rc, so, se = run(['add', '-A'])
    out.append('add rc=%d %s%s' % (rc, so, se))

    if msg_file:
        rc, so, se = run(['commit', '-F', msg_file])
    else:
        rc, so, se = run(['commit', '-m', 'Update SteamSPA'])
    out.append('commit rc=%d\n%s%s' % (rc, so, se))
    if rc != 0:
        print('\n'.join(out))
        return rc

    rc, so, se = run(['push', 'origin', 'main'])
    out.append('push rc=%d\n%s%s' % (rc, so, se))

    rc, so, se = run(['ls-remote', 'origin'])
    out.append('--- remote HEAD ---\n%s' % (so or se))

    txt = '\n'.join(out)
    print(txt)
    with io.open(os.path.join(ROOT, 'temp', '_release.log'), 'w', encoding='utf-8') as f:
        f.write(txt)
    return 0


if __name__ == '__main__':
    sys.exit(main())
