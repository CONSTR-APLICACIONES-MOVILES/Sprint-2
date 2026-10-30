// Read-only HTTP smoke using the existing local accounts. No seed, RSVP or lifecycle mutation.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const base = 'http://127.0.0.1:5001/demo-parchapp/us-central1';
async function post(url, body, token) {
  const response = await fetch(url, {method: 'POST', headers: {'Content-Type': 'application/json',
    ...(token ? {Authorization: `Bearer ${token}`} : {})}, body: JSON.stringify(body), signal: AbortSignal.timeout(20000)});
  return {status: response.status, body: await response.json()};
}
(async () => {
  for (const name of ['validatePlanningSlot', 'publishActivity', 'updateActivityDetails', 'cancelActivity']) {
    const result = await post(`${base}/${name}`, {data: {}});
    assert.equal(result.status, 401, `${name} must be registered and require authentication`);
  }
  const accounts = [];
  for (const [email, password] of [['a.va@test.com', '12345678'], ['participant@parchapp.test', 'ParchApp123!']]) {
    const login = await post('http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=emulator',
      {email, password, returnSecureToken: true});
    assert.equal(login.status, 200, 'Fixture login failed');
    const token = login.body.idToken;
    async function call(name, data = {}, expected = 200) {
      const result = await post(`${base}/${name}`, {data}, token);
      assert.equal(result.status, expected, `${name}: unexpected HTTP status ${result.status}`);
      return result.body.result ?? result.body.data;
    }
    const profile = await call('getProfile');
    assert.equal(profile.id, login.body.localId);
    const {activities} = await call('getActivities');
    const summary = activities.find(activity => !activity.cancelled);
    assert.ok(summary, 'Expected an existing active fixture activity');
    const detail = await call('getActivity', {activityId: summary.id});
    assert.equal(typeof detail.version, 'string'); assert.ok(detail.version.length > 0);
    assert.equal(typeof detail.cancelled, 'boolean');
    assert.equal(summary.attendance.total, detail.participants.length);
    const forbiddenStatus = detail.createdBy === profile.id ? 409 : 403;
    // Deliberately stale version: rejection occurs before any mutation.
    await call('updateActivityDetails', {activityId: detail.id, expectedVersion: 'never-current-version', fields: {title: 'Rejected check'}}, forbiddenStatus);
    await call('cancelActivity', {activityId: detail.id, expectedVersion: 'never-current-version'}, forbiddenStatus);
    await call('publishActivity', {requestId: 'phase-b-rejected-validation', groupId: detail.groupId, fields: {title: ''}}, 400);
    const unchanged = await call('getActivity', {activityId: detail.id});
    assert.equal(unchanged.version, detail.version);
    assert.equal(unchanged.title, detail.title); assert.equal(unchanged.cancelled, detail.cancelled);
    accounts.push({name: profile.name, activities: activities.length, authorizationAndVersion: 'PASS'});
  }
  const report = {checkedAt: new Date().toISOString(), project: 'demo-parchapp', result: 'PASS',
    mode: 'HTTP Auth/Functions; rejected mutation checks only; existing fixtures unchanged', accounts};
  const output = path.join(__dirname, '..', 'build', 'phase-b-http.json');
  fs.mkdirSync(path.dirname(output), {recursive: true});
  fs.writeFileSync(output, JSON.stringify(report, null, 2));
  console.log(JSON.stringify(report, null, 2));
})().catch(error => { console.error(error.message); process.exitCode = 1; });
