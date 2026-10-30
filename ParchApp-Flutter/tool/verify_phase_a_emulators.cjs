// Read-only integration check: existing local fixtures, no seed/reset or RSVP.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const project = 'demo-parchapp';
const functions = `http://127.0.0.1:5001/${project}/us-central1`;
const firestore = `http://127.0.0.1:8080/v1/projects/${project}/databases/(default)/documents:runQuery`;
async function post(url, body, token) {
  const response = await fetch(url, {method: 'POST',
    headers: {'Content-Type': 'application/json', ...(token ? {Authorization: `Bearer ${token}`} : {})},
    body: JSON.stringify(body), signal: AbortSignal.timeout(15000)});
  return {ok: response.ok, status: response.status, data: await response.json()};
}
async function verify(email, password) {
  const login = await post('http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=emulator',
      {email, password, returnSecureToken: true});
  assert.ok(login.ok, `Login failed for ${email}`);
  const {localId: uid, idToken: token} = login.data;
  async function call(name) {
    const result = await post(`${functions}/${name}`, {data: {}}, token);
    assert.ok(result.ok, `${name} failed (${result.status})`);
    return result.data.result ?? result.data.data;
  }
  const [profile, activities, alerts, groups] = await Promise.all([
    call('getProfile'), call('getActivities'), call('getAlerts'),
    post(firestore, {structuredQuery: {from: [{collectionId: 'groups'}],
      where: {fieldFilter: {field: {fieldPath: 'memberIds'}, op: 'ARRAY_CONTAINS',
        value: {stringValue: uid}}}}}, token),
  ]);
  assert.equal(profile.id, uid);
  assert.ok(profile.name);
  assert.ok(groups.ok, `Membership query rejected (${groups.status})`);
  const docs = groups.data.filter(row => row.document).map(row => row.document);
  const ids = new Set(docs.map(doc => doc.name.split('/').at(-1)));
  assert.ok(ids.size >= 2, 'Expected existing local testing groups');
  assert.equal(profile.activeGroups, ids.size);
  for (const activity of activities.activities) assert.ok(ids.has(activity.groupId));
  for (const alert of alerts.alerts) {
    assert.ok(activities.activities.some(activity => activity.id === alert.studySessionId));
  }
  // Exercise the exact per-group latest-activity query used by the Flutter repository.
  for (const id of ids) {
    const latest = await post(firestore, {structuredQuery: {from: [{collectionId: 'activities'}],
      where: {fieldFilter: {field: {fieldPath: 'groupId'}, op: 'EQUAL', value: {stringValue: id}}},
      orderBy: [{field: {fieldPath: 'createdAt'}, direction: 'DESCENDING'}], limit: 1}}, token);
    assert.ok(latest.ok, `Latest activity query rejected (${latest.status})`);
  }
  return {uid, name: profile.name, groups: ids.size,
    activities: activities.activities.length, alerts: alerts.alerts.length,
    unread: alerts.alerts.filter(alert => !alert.isRead && !alert.response).length};
}
(async () => {
  const people = [];
  people.push(await verify('a.va@test.com', '12345678'));
  people.push(await verify('participant@parchapp.test', 'ParchApp123!'));
  assert.notEqual(people[0].uid, people[1].uid);
  const unauthorized = await post(`${functions}/getProfile`, {data: {}});
  assert.ok(!unauthorized.ok, 'Unauthenticated profile request must be denied');
  const privateGroups = await post(firestore, {structuredQuery: {from: [{collectionId: 'groups'}]}});
  assert.ok(!privateGroups.ok, 'Unauthenticated group query must be denied');
  const report = {checkedAt: new Date().toISOString(), project,
    result: 'PASS', mode: 'existing fixtures; read-only queries; no seed/reset', people,
    authorization: 'unauthenticated profile and group access denied'};
  const output = path.join(__dirname, '..', 'build', 'phase-a-emulators.json');
  fs.mkdirSync(path.dirname(output), {recursive: true});
  fs.writeFileSync(output, JSON.stringify(report, null, 2));
  console.log(JSON.stringify(report, null, 2));
})().catch(error => { console.error(error.message); process.exitCode = 1; });
