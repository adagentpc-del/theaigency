'use strict';
const test=require('node:test');
const assert=require('node:assert/strict');
const {app}=require('../server');
let server,base;

test.before(async()=>{await new Promise(resolve=>{server=app.listen(0,()=>{base=`http://127.0.0.1:${server.address().port}`;resolve();});});});
test.after(()=>new Promise(resolve=>server.close(resolve)));

async function req(path,options={}){return fetch(base+path,{...options,headers:{'Content-Type':'application/json',...(options.headers||{})}});}
async function register(){const email=`user-${Date.now()}-${Math.random().toString(16).slice(2)}@example.com`,r=await req('/api/auth/register',{method:'POST',body:JSON.stringify({email,password:'correct-horse-battery-staple'})});assert.equal(r.status,201);return{cookie:r.headers.get('set-cookie').split(';')[0],email,user:(await r.json()).user};}

test('health and SEO endpoints respond',async()=>{let r=await req('/api/health');assert.equal(r.status,200);assert.equal((await r.json()).ok,true);r=await fetch(base+'/chatgpt-image-to-vector');assert.equal(r.status,200);const html=await r.text();assert.match(html,/ChatGPT Image to Vector/);r=await fetch(base+'/sitemap.xml');assert.equal(r.status,200);assert.match(await r.text(),/logo-to-vector/);});

test('registration, session and login work',async()=>{const {cookie,email,user}=await register();assert.equal(user.email,email);let r=await req('/api/me',{headers:{Cookie:cookie}});assert.equal((await r.json()).user.email,email);r=await req('/api/auth/logout',{method:'POST',headers:{Cookie:cookie},body:'{}'});assert.equal(r.status,200);r=await req('/api/auth/login',{method:'POST',body:JSON.stringify({email,password:'wrong-password'})});assert.equal(r.status,401);r=await req('/api/auth/login',{method:'POST',body:JSON.stringify({email,password:'correct-horse-battery-staple'})});assert.equal(r.status,200);});

test('projects are private to their owner and malicious SVG is rejected',async()=>{const a=await register(),b=await register();const svg='<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 10 10"><path fill="rgb(0 0 0)" d="M 0 0 L 10 0 L 10 10 Z"/></svg>';let r=await req('/api/projects',{method:'POST',headers:{Cookie:a.cookie},body:JSON.stringify({name:'logo',use_case:'T-shirt / apparel',mode:'trace',svg,print_status:'READY',print_warnings:[]})});assert.equal(r.status,201);const project=(await r.json()).project;r=await req(`/api/projects/${project.id}`,{headers:{Cookie:b.cookie}});assert.equal(r.status,404);r=await req('/api/projects',{method:'POST',headers:{Cookie:a.cookie},body:JSON.stringify({name:'bad',use_case:'x',mode:'trace',svg:'<svg><script>alert(1)</script></svg>',print_status:'READY',print_warnings:[]})});assert.equal(r.status,400);r=await req(`/api/projects/${project.id}`,{method:'DELETE',headers:{Cookie:a.cookie},body:'{}'});assert.equal(r.status,200);});

test('export credits cannot go negative',async()=>{const u=await register();const r=await req('/api/exports/consume',{method:'POST',headers:{Cookie:u.cookie},body:'{}'});assert.equal(r.status,402);const me=await req('/api/me',{headers:{Cookie:u.cookie}});assert.equal((await me.json()).user.credits,0);});
