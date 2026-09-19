# -*- coding: utf-8 -*-
"""SteamSPA 发布：commit + push（push 必须走 python，见 research/docs/维护笔记.md）。"""
import subprocess, sys, io, os, time


def _find_root(start):
    """向上找到含 data/ 子目录的仓库根，避免把本机绝对路径写进仓库。"""
    d = start
    for _ in range(5):
        if os.path.isdir(os.path.join(d, 'data')):
            return d
        parent = os.path.dirname(d)
        if parent == d:
            break
        d = parent
    return start


ROOT = _find_root(os.path.dirname(os.path.abspath(__file__)))


def run(args, env=None):
    p = subprocess.run(['git'] + args, cwd=ROOT, capture_output=True,
                       text=True, encoding='utf-8', errors='replace',
                       timeout=300, env=env)
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

    # git push 在这个环境里会返回 exit=128 且零输出：
    # 必须显式指定 wincred，默认的 GCM(manager) 在沙箱里读不到凭据。
    env = dict(os.environ)
    env['GIT_TERMINAL_PROMPT'] = '0'
    env['GCM_INTERACTIVE'] = 'never'
    for attempt in (1, 2, 3):
        rc, so, se = run(['-c', 'credential.helper=wincred', 'push', 'origin', 'main'], env)
        out.append('push try%d rc=%d\n%s%s' % (attempt, rc, so, se))
        if rc == 0:
            break
        time.sleep(3)

    rc, so, se = run(['ls-remote', 'origin'])
    out.append('--- remote HEAD ---\n%s' % (so or se))

    txt = '\n'.join(out)
    print(txt)
    with io.open(os.path.join(ROOT, 'temp', '_release.log'), 'w', encoding='utf-8') as f:
        f.write(txt)
    return 0


if __name__ == '__main__':
    sys.exit(main())
