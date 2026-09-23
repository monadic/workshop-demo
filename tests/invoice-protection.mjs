import assert from 'node:assert/strict';
import { readFileSync, mkdtempSync, rmSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';
const root = new URL('../2-my-fixes-survive/expected/invoice-protection/', import.meta.url);
const receipt = JSON.parse(readFileSync(new URL('receipt.json', root)));
for (const [path, hash] of Object.entries(receipt.files)) assert.equal(createHash('sha256').update(readFileSync(new URL(path, root))).digest('hex'), hash, path);
assert.equal(receipt.cases.length, 2);
for (const c of receipt.cases) {
  assert.equal(c.exitCodes.length, 7); assert.ok(c.exitCodes.every(code => code === 0));
  assert.equal(c.commands.some(args => args.includes('--protect')), c.protected);
}
const temp = mkdtempSync(join(tmpdir(), 'invoice-protection-'));
function diff(before, after) {
  const output = join(temp, `${Math.random()}.json`);
  const r = spawnSync('cub', ['config','diff',fileURLToPath(new URL(before,root)),fileURLToPath(new URL(after,root)),'--out',output],{encoding:'utf8',timeout:30000});
  assert.equal(r.status,0,r.stderr || r.error?.message);
  return JSON.parse(readFileSync(output));
}
try {
  const fields = diff(receipt.localEdits,'unprotected-after.yaml').changes.flatMap(c => c.fields);
  assert.deepEqual(fields.map(f => f.path), ['/spec/replicas','/spec/template/spec/containers/api/livenessProbe']);
  assert.equal(fields[0].before,4); assert.equal(fields[0].after,5);
  assert.equal(diff(receipt.expectedProtected,'protected-after.yaml').equal,true);
  const protectedFields = diff(receipt.localEdits,'protected-after.yaml').changes.flatMap(c => c.fields);
  assert.deepEqual(protectedFields.map(f => [f.path,f.operation]),[['/spec/template/spec/containers/api/livenessProbe','add']]);
} finally { rmSync(temp,{recursive:true,force:true}); }
console.log('Protected and unprotected same-field observations verified offline.');
