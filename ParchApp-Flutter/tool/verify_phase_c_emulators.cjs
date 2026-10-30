// Auth/Functions smoke against existing fixtures: reads and rejected writes only.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const base = 'http://127.0.0.1:5001/demo-parchapp/us-central1';
async function post(url, body, token) {
  const response = await fetch(url, {method: 'POST', headers: {'Content-Type': 'application/json', ...(token ? {Authorization: `Bearer ${token}`} : {})}, body: JSON.stringify(body), signal: AbortSignal.timeout(20000)});
  return {status: response.status, body: await response.json()};
}
(async () => {
  const names = ['getCommunityPeers','createGroup','getGroupInvitations','respondGroupInvitation','revokeGroupInvitation','getGroupDetails','updatePresence','updatePreferences'];
  for (const name of names) assert.equal((await post(`${base}/${name}`, {data: {}})).status, 401, `${name} registration/auth`);
  const accounts = [];
  for (const [email, password] of [['a.va@test.com', '12345678'], ['participant@parchapp.test', 'ParchApp123!']]) {
    const login = await post('http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=emulator', {email, password, returnSecureToken: true});
    assert.equal(login.status, 200, 'Fixture login failed');
    const token = login.body.idToken;
    async function call(name, data = {}, expected = 200) {
      const result = await post(`${base}/${name}`, {data}, token);
      assert.equal(result.status, expected, `${name} HTTP ${result.status}: ${JSON.stringify(result.body)}`);
      return result.body.result ?? result.body.data;
    }
    const before = await call('getProfile');
    assert.ok(before.preferences); assert.equal(typeof before.preferences.invitationBadges, 'boolean');
    const {peers} = await call('getCommunityPeers'); assert.ok(peers.length);
    const {activities} = await call('getActivities'); assert.ok(activities.length);
    const detail = await call('getGroupDetails', {groupId: activities[0].groupId});
    assert.ok(detail.members.some(m => m.id === before.id)); assert.ok(Array.isArray(detail.activities));
    const scoped = await call('getScheduleFriends', {groupId: detail.id});
    assert.ok(scoped.friends.every(f => detail.members.some(m => m.id === f.id)));
    const {invitations} = await call('getGroupInvitations'); assert.ok(Array.isArray(invitations));
    await call('getGroupDetails', {groupId: 'phase-c-not-authorized'}, 403);
    await call('createGroup', {requestId: 'phase-c-rejected-check', name: '', category: 'study', inviteeIds: []}, 400);
    await call('updatePresence', {status: 'focused', visibility: 'private', expiresAt: '2000-01-01T00:00:00Z'}, 400);
    await call('updatePreferences', {preferences: {scheduleVisibility: 'private'}}, 400);
    const after = await call('getProfile');
    assert.deepEqual(after, before, 'Rejected checks must not change the profile');
    accounts.push({name: before.name, group: detail.name, members: detail.members.length, history: detail.activities.length, peers: peers.length, invitations: invitations.length});
  }
  const report = {checkedAt: new Date().toISOString(), project: 'demo-parchapp', result: 'PASS', mode: 'HTTP Auth/Functions; existing fixtures preserved; all writes rejected', accounts};
  const output = path.join(__dirname, '..', 'build', 'phase-c-http.json'); fs.mkdirSync(path.dirname(output), {recursive: true}); fs.writeFileSync(output, JSON.stringify(report, null, 2));
  console.log(JSON.stringify(report, null, 2));
})().catch(error => { console.error(error.message); process.exitCode = 1; });
