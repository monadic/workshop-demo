import assert from 'node:assert/strict';
import { readFileSync, mkdtempSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
const root = new URL('../2-my-fixes-survive/expected/invoice-preservation/', import.meta.url);
const read = name => JSON.parse(readFileSync(new URL(name, root)));
const receipt = read('receipt.json');
assert.equal(receipt.status, 'passed');
assert.equal(receipt.exitCodes.length, 9);
assert.ok(receipt.exitCodes.every(code => code === 0));
for (const [name, hash] of Object.entries(receipt.files)) {
  assert.equal(createHash('sha256').update(readFileSync(new URL(name, root))).digest('hex'), hash, name);
}
for (const [name, before, after] of [
  ['rewrite-review.json', 'downstream-before.yaml', 'upstream-after.yaml'],
  ['server-before.json', 'downstream-before.yaml', 'server-downstream-before.yaml'],
  ['server-change.json', 'downstream-before.yaml', 'server-downstream-after.yaml'],
  ['server-expected.json', 'expected-downstream-after.yaml', 'server-downstream-after.yaml'],
]) {
  const report = read(name);
  assert.equal(report.before.sha256, `sha256:${receipt.files[before]}`);
  assert.equal(report.after.sha256, `sha256:${receipt.files[after]}`);
}
assert.equal(read('server-before.json').equal, true);
assert.equal(read('server-expected.json').equal, true);
assert.equal(read('rewrite-review.json').changes.flatMap(change => change.fields).length, 7);
const change = read('server-change.json');
assert.equal(change.summary.added, 0); assert.equal(change.summary.removed, 0);
assert.deepEqual(change.changes.flatMap(item => item.fields).map(field => [field.path, field.operation]),
  [['/spec/template/spec/containers/api/livenessProbe', 'add']]);
assert.equal(receipt.assertions.sixLocalEditsPreserved, true);
assert.equal(receipt.assertions.onlyRequestedLivenessProbeAdded, true);
assert.equal(receipt.assertions.matchesExpectedSemantically, true);
// Recompute from YAML, not only the recorded reports. Requires the same cub
// config diff command used by the demo; it makes no server or registry calls.
const temporary = mkdtempSync(join(tmpdir(), 'invoice-preservation-'));
try {
  for (const [name, before, after] of [
    ['rewrite-review.json', 'downstream-before.yaml', 'upstream-after.yaml'],
    ['server-before.json', 'downstream-before.yaml', 'server-downstream-before.yaml'],
    ['server-change.json', 'downstream-before.yaml', 'server-downstream-after.yaml'],
    ['server-expected.json', 'expected-downstream-after.yaml', 'server-downstream-after.yaml'],
  ]) {
    const output = join(temporary, name);
    const result = spawnSync('cub', ['config', 'diff', fileURLToPath(new URL(before, root)),
      fileURLToPath(new URL(after, root)), '--out', output], { encoding: 'utf8', timeout: 30000 });
    assert.equal(result.status, 0, result.stderr || result.error?.message);
    const actual = JSON.parse(readFileSync(output));
    assert.deepEqual(actual.changes, read(name).changes, `recomputed field changes: ${name}`);
    assert.equal(actual.equal, read(name).equal, `recomputed equality: ${name}`);
  }
} finally { rmSync(temporary, { recursive: true, force: true }); }
console.log('Invoice preservation receipt: hashes and seven-to-one field-change evidence verified. No live server call.');
