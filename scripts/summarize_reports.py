#!/usr/bin/env python3
"""Parse original or rerun Vivado reports. No third-party Python dependencies."""
import argparse
import csv
import json
import re
from pathlib import Path


def parse_case(folder):
    hierarchy = (folder / 'utilization_hierarchical.rpt').read_text()
    timing = (folder / 'timing_summary.rpt').read_text()
    if not all('Synthesized' in text for text in (hierarchy, timing)):
        raise ValueError(f'{folder}: expected synthesis-stage reports')
    rows = {}
    for line in hierarchy.splitlines():
        cols = [v.strip() for v in line.split('|')[1:-1]]
        if len(cols) == 10 and cols[0] in ('reaction_top', 'u_lfsr_random', 'u_score_history', 'u_buzzer_player'):
            rows[cols[0]] = dict(lut=int(cols[2]), ff=int(cols[6]), dsp=int(cols[9]))
    if len(rows) != 4:
        raise ValueError(f'{folder}: missing hierarchy rows')
    section = timing.split('| Design Timing Summary', 1)[1]
    match = re.search(r'^\s*(-?\d+\.\d+)\s+(-?\d+\.\d+)\s+(\d+)\s+(\d+)\s+', section, re.M)
    if not match:
        raise ValueError(f'{folder}: missing timing summary')
    rows['reaction_top'].update(wns_ns=float(match[1]), tns_ns=float(match[2]), setup_failing_endpoints=int(match[3]))
    return rows


def main():
    root = Path(__file__).resolve().parents[1]
    ap = argparse.ArgumentParser()
    ap.add_argument('--reports', type=Path, default=root / 'reports')
    ap.add_argument('--output', type=Path, default=root / 'build' / 'summary')
    args = ap.parse_args()
    data = {case: parse_case(args.reports / case) for case in ('baseline', 'ai_draft')}
    args.output.mkdir(parents=True, exist_ok=True)
    (args.output / 'metrics.json').write_text(json.dumps(data, indent=2) + '\n')
    with (args.output / 'metrics.csv').open('w', newline='') as handle:
        writer = csv.DictWriter(handle, fieldnames=['case', 'instance', 'lut', 'ff', 'dsp', 'wns_ns', 'tns_ns', 'setup_failing_endpoints'])
        writer.writeheader()
        for case, rows in data.items():
            for instance, values in rows.items():
                writer.writerow(dict(case=case, instance=instance, **values))
    print('| 综合方案 | LUT | FF | DSP | WNS/ns | TNS/ns | Setup失败端点 |')
    print('|---|---:|---:|---:|---:|---:|---:|')
    for case, rows in data.items():
        v = rows['reaction_top']
        print(f"| {case} | {v['lut']} | {v['ff']} | {v['dsp']} | {v['wns_ns']:+.3f} | {v['tns_ns']:.3f} | {v['setup_failing_endpoints']} |")
    print('\nModule rows are hierarchy-attributed resources, not isolated synthesis; WNS is top-level only.')


if __name__ == '__main__':
    main()
