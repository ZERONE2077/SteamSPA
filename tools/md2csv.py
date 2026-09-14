# -*- coding: utf-8 -*-
"""把 data/痕迹总表.md 的表格同步成 CSV（UTF-8 BOM，Excel/AI 通用）。

用法:
    python tools/md2csv.py                      # 默认 data/痕迹总表.md -> .csv
    python tools/md2csv.py <some.md> [out.csv]

规则:
- 只取以 | 开头的行；跳过分隔行（全是 - 和空格）。
- 表头行（首行）原样作为 CSV 表头；可选做英文 key 映射。
- 单元格去反引号、去 ** 粗体。
"""
import io, os, re, sys, csv

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# 中文表头 -> 英文列名（AI 友好、省 token）
HEADER_MAP = {
    '条目': 'name', '名称': 'name',
    '类型': 'type',
    '来源': 'src',
    '我方规则': 'ours', '我方规则': 'ours',
    '处置': 'action',
    '备注': 'note',
}


def is_sep(s):
    t = s.replace('|', '').replace(' ', '')
    return bool(t) and set(t) <= set('-:')


def main():
    src = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, 'data', '痕迹总表.md')
    dst = sys.argv[2] if len(sys.argv) > 2 else os.path.splitext(src)[0] + '.csv'

    rows, header, zone = [], None, ''
    for line in io.open(src, encoding='utf-8'):
        s = line.strip()
        mh = re.match(r'^#{2,3}\s+(.+?)\s*(?:[（(]\d+[)）])?\s*$', s)
        if mh:
            zone = mh.group(1)
            continue
        if not s.startswith('|') or is_sep(s):
            continue
        cells = [c.strip().strip('`').replace('**', '') for c in s.strip('|').split('|')]
        # 表头行：首格是「条目」/name（每个分区重复一次，只在首次初始化）
        if cells[0] in ('条目', 'name'):
            if header is None:
                header = ['zone'] + [HEADER_MAP.get(c, c) for c in cells]
            continue
        if header is None or len(cells) + 1 != len(header):
            header = None  # 另一张表（如来源对照表），跳过
            continue
        rows.append([zone] + cells)

    if header is None:
        print('no table found: %s' % src)
        return 1

    with io.open(dst, 'w', encoding='utf-8-sig', newline='') as f:
        w = csv.writer(f)
        w.writerow(header)
        w.writerows(rows)
    print('%s -> %s  rows=%d' % (os.path.basename(src), os.path.basename(dst), len(rows)))
    return 0


if __name__ == '__main__':
    sys.exit(main())
