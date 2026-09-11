#!/usr/bin/env bash
# Harness entrypoint for deepseek-harness-config.
#
#   ./init.sh                 offline checks only — no credential, no network
#   ./init.sh --with-doctor   also run scripts/doctor.sh (needs a live key)
#
# Run at the start of every session; a failing baseline is repaired before new
# scope. Exits non-zero on the first failed check.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO"

step() { printf '\n=== %s ===\n' "$1"; }
fail() { printf '  FAIL %s\n' "$*" >&2; exit 1; }

command -v node >/dev/null 2>&1 || { echo "FAIL: node is required (dsh needs Node 20+)"; exit 1; }

step 'build: bash syntax check (bash -n)'
while IFS= read -r f; do
  bash -n "$f"
  echo "  ok $f"
done < <(find . -path ./.git -prune -o -name '*.sh' -print | sort)

step 'test: feature_list.json shape and one-feature-at-a-time'
node - <<'JS'
const { readFileSync } = require('node:fs');
const { features } = JSON.parse(readFileSync('feature_list.json', 'utf8'));
if (!Array.isArray(features) || features.length === 0) throw new Error('features[] missing');
const statuses = new Set(['not-started', 'in-progress', 'blocked', 'done']);
const ids = new Set();
for (const f of features) {
  for (const key of ['id', 'name', 'description', 'status', 'evidence']) {
    if (typeof f[key] !== 'string') throw new Error(`${f.id ?? '?'}: ${key} must be a string`);
  }
  if (ids.has(f.id)) throw new Error(`duplicate feature id ${f.id}`);
  ids.add(f.id);
  if (!statuses.has(f.status)) throw new Error(`${f.id}: unknown status ${f.status}`);
  if (f.status === 'done' && !f.evidence.trim()) throw new Error(`${f.id}: done without evidence`);
}
const active = features.filter((f) => f.status === 'in-progress');
if (active.length > 1) throw new Error('more than one feature is in-progress');
console.log(`  ok ${features.length} feature(s), ${active.length} in-progress`);
JS

step 'test: settings.yaml parses and agent-default-model resolves'
if python3 -c 'import yaml' >/dev/null 2>&1; then
  python3 - <<'PY'
import yaml
cfg = yaml.safe_load(open('settings.yaml'))
providers = cfg['llm-pi-ai']['providers']
default = cfg['agent-default-model']
provider = providers.get(default['provider'])
assert provider, f"agent-default-model.provider {default['provider']!r} is not a declared provider"
ids = {m['id'] for m in provider['models']}
assert default['model'] in ids, f"agent-default-model.model {default['model']!r} is not declared by {default['provider']!r}"
print(f"  ok {len(providers)} provider(s); default {default['provider']}/{default['model']}")
PY
else
  echo '  skip: python3 + PyYAML not available'
fi

if command -v dsh >/dev/null 2>&1; then
  dsh --profile headless --dump-config >/dev/null
  echo '  ok settings compose (dsh --profile headless --dump-config)'
fi

step 'test: every skill bundle declares name + description'
node - <<'JS'
const { readFileSync, readdirSync } = require('node:fs');
const dirs = readdirSync('skills', { withFileTypes: true }).filter((d) => d.isDirectory());
if (dirs.length === 0) throw new Error('skills/ contains no bundles');
for (const d of dirs) {
  const text = readFileSync(`skills/${d.name}/SKILL.md`, 'utf8');
  const end = text.indexOf('---', 3);
  const front = end === -1 ? text : text.slice(0, end);
  for (const key of ['name', 'description']) {
    if (!new RegExp(`^${key}:`, 'm').test(front)) {
      throw new Error(`skills/${d.name}/SKILL.md: frontmatter is missing ${key}`);
    }
  }
}
console.log(`  ok ${dirs.length} skill bundle(s)`);
JS

step 'test: plugins.json is a pinned, de-duplicated plugin set'
node - <<'JS'
const { readFileSync } = require('node:fs');
try {
  const { plugins } = JSON.parse(readFileSync('plugins.json', 'utf8'));
  if (!Array.isArray(plugins) || plugins.length === 0) throw new Error('plugins[] missing');
  const seen = new Set();
  for (const p of plugins) {
    for (const key of ['profile', 'package']) {
      if (typeof p[key] !== 'string' || !p[key].trim()) throw new Error(`each plugin needs a non-empty ${key}`);
    }
    const at = p.package.lastIndexOf('@');
    const version = p.package.slice(at + 1);
    if (at <= 0 || !version || version === 'latest' || version === '*' || /^[~^]/.test(version)) {
      throw new Error(`${p.package}: pin an exact version (name@x.y.z), never a range or latest`);
    }
    const key = `${p.profile}/${p.package.slice(0, at)}`;
    if (seen.has(key)) throw new Error(`duplicate plugin entry: ${key}`);
    seen.add(key);
  }
  console.log(`  ok ${plugins.length} plugin(s) pinned for ${[...new Set(plugins.map((p) => p.profile))].join(', ')}`);
} catch (err) {
  console.error(`  FAIL ${err.message}`);
  process.exit(1);
}
JS

step 'test: install.sh still applies the plugin manifest'
grep -qF '"$REPO/scripts/install-plugins.sh"' install.sh || fail 'install.sh no longer calls scripts/install-plugins.sh'

step 'test: the CI workflow still runs this gate'
CI_WORKFLOW='.github/workflows/verify.yml'
[ -f "$CI_WORKFLOW" ] || fail "$CI_WORKFLOW is missing — CI must run the gate"
[ -f .nvmrc ] || fail '.nvmrc is missing — CI needs a pinned Node major'
grep -qE '^[[:space:]]*run:.*init\.sh' "$CI_WORKFLOW" || fail "$CI_WORKFLOW no longer runs ./init.sh"
grep -q 'pip install pyyaml' "$CI_WORKFLOW" \
  || fail "$CI_WORKFLOW must install PyYAML, or the settings.yaml cross-check silently skips there"
if grep -q 'secrets\.' "$CI_WORKFLOW"; then
  fail "$CI_WORKFLOW references secrets — this repo keeps credentials off CI"
fi
if python3 -c 'import yaml' >/dev/null 2>&1; then
  python3 - <<'PY'
import yaml
wf = yaml.safe_load(open('.github/workflows/verify.yml'))
# PyYAML implements YAML 1.1, where a bare `on:` key parses as boolean True.
triggers = wf.get('on', wf.get(True))
assert isinstance(triggers, dict), 'workflow has no on: triggers'
for event in ('push', 'pull_request'):
    assert event in triggers, f'missing trigger: {event}'
jobs = wf['jobs']
assert len(jobs) == 1, f'expected one job, found {len(jobs)}'
steps = next(iter(jobs.values()))['steps']
assert any('./init.sh' in s.get('run', '') for s in steps), 'no step runs ./init.sh'
print('  ok verify.yml parses: push + pull_request, 1 job, runs ./init.sh')
PY
else
  echo '  skip: python3 + PyYAML not available for the workflow parse'
fi

if command -v shellcheck >/dev/null 2>&1; then
  step 'lint: shellcheck'
  shellcheck -S warning install.sh init.sh scripts/*.sh
  echo '  ok shellcheck (warning severity)'
else
  echo '  skip lint: shellcheck not installed'
fi

if [ "${1:-}" = '--with-doctor' ]; then
  step 'doctor: machine-level check'
  ./scripts/doctor.sh
fi

echo
echo '=== Verification complete ==='
echo
echo 'Next steps:'
echo '1. Read feature_list.json to see the current feature state'
echo '2. Pick ONE unfinished feature to work on'
echo '3. Implement only that feature'
echo '4. Re-run ./init.sh before claiming done'
