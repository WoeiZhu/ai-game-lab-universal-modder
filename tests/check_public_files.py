"""Stdlib-only publication check. Findings never echo matched content."""
from __future__ import annotations

import argparse
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
PUBLIC_FILES = {
    '.gitattributes', '.gitignore', 'README.md', 'AGENTS.md', 'CLAUDE.md',
    'config/.env.example', 'config/upstream.json',
    'docs/ARCHITECTURE.md', 'docs/COST_AND_RISKS.md', 'docs/TEST_PLAN.md',
    'docs/RESULT_TEMPLATE.md', 'docs/INITIALIZATION_AUDIT.md',
    'docs/LOCAL_TEST_RESULTS.md',
    'scripts/Common.ps1', 'scripts/00-Preflight.ps1', 'scripts/10-Install-UM.ps1',
    'scripts/20-Test-ComfyUI.ps1', 'scripts/30-Test-Blender.ps1',
    'tests/check_public_files.py', 'tests/test_public_check.py',
    'tests/Test-Repository.ps1',
}
RULES = {
    'credential-prefix': re.compile(
        r'(?:gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}'
        r'|sk-[A-Za-z0-9_-]{20,}|AIza[A-Za-z0-9_-]{30,}|AKIA[A-Z0-9]{16})'),
    'private-key': re.compile(r'-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----'),
    'credential-assignment': re.compile(
        r'(?im)^\s*[\w]*(?:api[_-]?key|token|secret|password|fal_key)'
        r'\s*[=:]\s*[\"\']?[A-Za-z0-9_+/.-]{20,}'),
    'absolute-windows-path': re.compile(r'\b[A-Za-z]:[\\/]'),
    'private-unix-home': re.compile(r'/(?:Users|home)/[A-Za-z0-9_.-]+/'),
    'private-drive-url': re.compile(r'https?://(?:drive|docs)\.google\.com/', re.I),
    'signed-url': re.compile(r'https?://\S+[?&](?:sig|token|access_token)=', re.I),
    'email': re.compile(r'\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b', re.I),
}


def inspect(path: str, data: bytes) -> list[tuple[str, int, str]]:
    findings = []
    if path not in PUBLIC_FILES:
        findings.append((path, 0, 'not-in-public-allowlist'))
    try:
        content = data.decode('utf-8-sig')
    except UnicodeDecodeError:
        return findings + [(path, 0, 'non-utf8')]
    if '\x00' in content:
        findings.append((path, 0, 'binary-content'))
    for label, pattern in RULES.items():
        for match in pattern.finditer(content):
            findings.append((path, content.count('\n', 0, match.start()) + 1, label))
    return findings


def git(*args: str) -> bytes:
    return subprocess.check_output(['git', *args], cwd=ROOT)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--staged', action='store_true', help='inspect exact Git index bytes')
    args = parser.parse_args()
    options = ['ls-files', '--cached', '-z']
    if not args.staged:
        options += ['--others', '--exclude-standard']
    paths = sorted(set(git(*options).decode('utf-8').rstrip('\x00').split('\x00')) - {''})
    findings = []
    if set(paths) != PUBLIC_FILES:
        for path in sorted(PUBLIC_FILES - set(paths)):
            findings.append((path, 0, 'required-public-file-missing'))
    for path in paths:
        data = git('show', ':' + path) if args.staged else (ROOT / path).read_bytes()
        findings += inspect(path, data)
    for path, line, label in findings:
        print(f'{path}:{line}: {label}')
    if findings:
        print(f'FAIL: {len(findings)} finding(s); values redacted.')
        return 1
    print(f'PASS: {len(paths)} public files; no configured sensitive patterns detected.')
    return 0


if __name__ == '__main__':
    sys.exit(main())
