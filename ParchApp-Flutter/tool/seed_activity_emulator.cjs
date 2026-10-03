// Local emulator fixtures only. Uses Node 22's fetch, no Admin SDK credentials.
const fs = require('node:fs');
const path = require('node:path');
const project = 'demo-parchapp';
const email = 'organizer@parchapp.test';
const password = 'ParchApp123!';

async function request(url, body, owner = false) {
  const response = await fetch(url, {method: 'POST', headers: {
    'Content-Type': 'application/json', ...(owner ? {Authorization: 'Bearer owner'} : {}),
  }, body: JSON.stringify(body)});
  const result = await response.json();
  if (!response.ok) throw new Error(result.error?.message ?? `HTTP ${response.status}`);
  return result;
}

function value(input) {
  if (typeof input === 'string') return {stringValue: input};
  if (typeof input === 'number') return {integerValue: String(input)};
  if (Array.isArray(input)) return {arrayValue: {values: input.map(value)}};
  return {mapValue: {fields: fields(input)}};
}
function fields(input) { return Object.fromEntries(Object.entries(input).map(([key, entry]) => [key, value(entry)])); }

async function main() {
  let account;
  const authUrl = 'http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/accounts:';
  try {
    account = await request(`${authUrl}signUp?key=emulator`, {email, password, returnSecureToken: true});
  } catch (error) {
    if (!error.message.includes('EMAIL_EXISTS')) throw error;
    account = await request(`${authUrl}signInWithPassword?key=emulator`, {email, password, returnSecureToken: true});
  }
  const base = `http://127.0.0.1:8080/v1/projects/${project}/databases/(default)/documents`;
  const group = await request(`${base}/groups`, {fields: fields({
    name: 'Flutter integration group', icon: '📚', planTitle: '',
    members: [{id: account.localId, name: 'Emulator Organizer', initials: 'EO', busy: [], preferredStart: 600, preferredEnd: 1200}],
    memberIds: [account.localId], goingIds: [], maybeIds: [], pendingInvites: [],
  })}, true);
  const activity = await request(`${base}/activities`, {fields: {
    ...fields({groupId: group.name.split('/').pop(), createdBy: account.localId,
      title: 'Flutter emulator activity', description: 'Unscheduled activity for callable verification.',
      category: 'study', date: '', time: '', location: 'Library', status: 'PROPOSED'}),
    createdAt: {timestampValue: new Date().toISOString()},
  }}, true);
  const fixture = {EMULATOR_ACTIVITY_ID: activity.name.split('/').pop(), EMULATOR_EMAIL: email, EMULATOR_PASSWORD: password};
  const destination = path.join(__dirname, '..', 'build', 'emulator_fixture.json');
  fs.mkdirSync(path.dirname(destination), {recursive: true});
  fs.writeFileSync(destination, JSON.stringify(fixture, null, 2));
  console.log(`Created activities/${fixture.EMULATOR_ACTIVITY_ID} in ${project}.`);
  console.log(`Email: ${email} | Emulator password: ${password}`);
  console.log(`Test configuration: ${destination}`);
}
main().catch(error => { console.error(error.message); process.exitCode = 1; });
