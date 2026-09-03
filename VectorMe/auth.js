'use strict';
const crypto=require('crypto');
const SESSION_TTL=60*60*24*30;
function b64url(buf){return Buffer.from(buf).toString('base64url');}
function sign(data,secret){return b64url(crypto.createHmac('sha256',secret).update(data).digest());}
function createSession(userId,secret){const payload=b64url(JSON.stringify({sub:String(userId),exp:Math.floor(Date.now()/1000)+SESSION_TTL}));return `${payload}.${sign(payload,secret)}`;}
function verifySession(token,secret){if(!token||!secret)return null;const [payload,sig]=String(token).split('.');if(!payload||!sig)return null;const expected=sign(payload,secret);const a=Buffer.from(sig),b=Buffer.from(expected);if(a.length!==b.length||!crypto.timingSafeEqual(a,b))return null;try{const obj=JSON.parse(Buffer.from(payload,'base64url').toString('utf8'));if(!obj.sub||obj.exp<Math.floor(Date.now()/1000))return null;return obj;}catch{return null;}}
function parseCookies(header=''){return Object.fromEntries(header.split(';').map(v=>v.trim()).filter(Boolean).map(v=>{const i=v.indexOf('=');return i<0?[v,'']:[decodeURIComponent(v.slice(0,i)),decodeURIComponent(v.slice(i+1))];}));}
function hashPassword(password){return new Promise((resolve,reject)=>{const salt=crypto.randomBytes(16);crypto.scrypt(password,salt,64,{N:16384,r:8,p:1},(e,key)=>e?reject(e):resolve(`scrypt$${b64url(salt)}$${b64url(key)}`));});}
function verifyPassword(password,stored){return new Promise((resolve)=>{const [alg,saltB64,keyB64]=String(stored||'').split('$');if(alg!=='scrypt'||!saltB64||!keyB64)return resolve(false);const salt=Buffer.from(saltB64,'base64url'),expected=Buffer.from(keyB64,'base64url');crypto.scrypt(password,salt,expected.length,{N:16384,r:8,p:1},(e,key)=>resolve(!e&&key.length===expected.length&&crypto.timingSafeEqual(key,expected)));});}
function validateEmail(email){return /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/i.test(String(email||'').trim())&&String(email).length<=254;}
function validatePassword(p){return typeof p==='string'&&p.length>=10&&p.length<=128;}
module.exports={createSession,verifySession,parseCookies,hashPassword,verifyPassword,validateEmail,validatePassword};
