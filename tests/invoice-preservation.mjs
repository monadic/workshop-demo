import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
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
console.log('Invoice preservation receipt: hashes and seven-to-one field-change evidence verified. No live server call.');
