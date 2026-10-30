// Read-only HTTP integration with existing Auth fixtures. No seed or accepted writes.
const assert=require('node:assert/strict'),fs=require('node:fs'),path=require('node:path');
const base='http://127.0.0.1:5001/demo-parchapp/us-central1';
async function post(url,body,token){const response=await fetch(url,{method:'POST',headers:{'Content-Type':'application/json',...(token?{Authorization:`Bearer ${token}`}:{})},body:JSON.stringify(body),signal:AbortSignal.timeout(25000)});return {status:response.status,body:await response.json()};}
(async()=>{
 const names=['discover','getSharedProfile','getActivityMaterials','saveActivityMaterials','setTopicCompletion','createShareLink','resolveShareLink','joinSharedGroup','getShareLinks','revokeShareLink','exportActivityCalendar','getCalendarImportStatus','markNotificationEventsRead'];
 for(const name of names)assert.equal((await post(`${base}/${name}`,{data:{}})).status,401,`${name} registration/Auth`);
 const accounts=[];
 for(const [email,password]of[['a.va@test.com','12345678'],['participant@parchapp.test','ParchApp123!']]){
  const login=await post('http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=emulator',{email,password,returnSecureToken:true});assert.equal(login.status,200);
  async function call(name,data={},expected=200){const result=await post(`${base}/${name}`,{data},login.body.idToken);assert.equal(result.status,expected,`${name}: ${JSON.stringify(result.body)}`);return result.body.result??result.body.data;}
  const before=await call('getProfile');
  const search=await call('discover',{query:'',kind:'all',category:'all',limit:2});assert.ok(search.results.length);assert.ok(search.scope.includes('Your groups'));
  if(search.cursor)await call('discover',{query:'',kind:'all',category:'all',limit:2,cursor:search.cursor});
  const peerSearch=await call('discover',{query:'',kind:'people',category:'all'});
  if(peerSearch.results.length){const p=await call('getSharedProfile',{userId:peerSearch.results[0].id});assert.equal(typeof p.name,'string');assert.equal(p.studentId,undefined);}
  const {activities}=await call('getActivities');const activity=activities[0];assert.ok(activity);
  const material=await call('getActivityMaterials',{activityId:activity.id});assert.ok(Array.isArray(material.topics));
  const calendar=await call('getCalendarImportStatus');assert.equal(calendar.automatic,false);
  await call('getShareLinks',{entityId:activity.groupId});await call('getAlerts');
  await call('createShareLink',{requestId:'phase-d-rejected',kind:'group',entityId:'phase-d-no-permission',hours:24},403);
  await call('resolveShareLink',{token:'invalid'},400);await call('joinSharedGroup',{token:'invalid'},400);
  await call('saveActivityMaterials',{activityId:activity.id,expectedVersion:'never-current',topics:[],resources:[{id:'bad',title:'Bad',url:'javascript:alert(1)'}]},400);
  const after=await call('getProfile');assert.deepEqual(after,before);
  accounts.push({name:before.name,searchResults:search.results.length,peers:peerSearch.results.length,materialVersion:material.version,lastImport:calendar.lastImportedAt});
 }
 const report={checkedAt:new Date().toISOString(),project:'demo-parchapp',result:'PASS',mode:'HTTP Auth/Functions; reads and rejected writes only; fixtures preserved',accounts};
 const output=path.join(__dirname,'..','build','phase-d-http.json');fs.mkdirSync(path.dirname(output),{recursive:true});fs.writeFileSync(output,JSON.stringify(report,null,2));console.log(JSON.stringify(report,null,2));
})().catch(error=>{console.error(error.message);process.exitCode=1;});
