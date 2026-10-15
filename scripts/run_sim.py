#!/usr/bin/env python3
"""Run unchanged course Verilog-2001 benches; require PASS text as well as exit 0."""
import argparse
from pathlib import Path
import re
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
BENCHES = {
    'tb_reaction_fsm': 'ALL TESTS PASSED',
    'tb_vga_timing': 'VGA TIMING TESTS PASSED',
    'tb_vga_renderer': 'VGA RENDERER TESTS PASSED',
    'tb_buzzer_player': 'BUZZER TESTS PASSED',
}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--simulator', choices=['xsim', 'iverilog'], default='xsim')
    args = ap.parse_args()
    executables = ['xvlog', 'xelab', 'xsim'] if args.simulator == 'xsim' else ['iverilog', 'vvp']
    resolved = {name: shutil.which(name) for name in executables}
    if not all(resolved.values()):
        print('Missing simulator tools: ' + ', '.join(k for k, v in resolved.items() if not v), file=sys.stderr)
        return 2
    sources = [str(p) for p in sorted((ROOT / 'rtl').glob('*.v'))]
    for bench, marker in BENCHES.items():
        cwd = ROOT / 'build' / 'sim' / bench
        cwd.mkdir(parents=True, exist_ok=True)
        inputs = sources + [str(ROOT / 'sim' / (bench + '.v'))]
        if args.simulator == 'xsim':
            commands = [[resolved['xvlog'], *inputs], [resolved['xelab'], bench, '-s', 'snapshot'], [resolved['xsim'], 'snapshot', '-runall']]
        else:
            commands = [[resolved['iverilog'], '-g2001', '-s', bench, '-o', 'simulation.vvp', *inputs], [resolved['vvp'], 'simulation.vvp']]
        transcript = ''
        for command in commands:
            completed = subprocess.run(command, cwd=cwd, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=180)
            transcript += completed.stdout
            (cwd / 'transcript.log').write_text(transcript)
            if completed.returncode:
                print(f'FAIL {bench}: tool returned {completed.returncode}; see {cwd}')
                return 1
        if marker not in transcript or re.search(r'(^FAIL:|TESTS FAILED)', transcript, re.M):
            print(f'FAIL {bench}: assertions or PASS marker; see {cwd}')
            return 1
        print('PASS ' + bench)
    return 0


if __name__ == '__main__':
    sys.exit(main())
