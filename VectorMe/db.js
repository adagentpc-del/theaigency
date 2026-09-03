'use strict';
const { Pool } = require('pg');

class MemoryDB {
  constructor(){ this.users=new Map(); this.projects=new Map(); this.events=[]; this.purchases=new Set(); this.nextUser=1; this.nextProject=1; }
  async init(){}
  async createUser(email,passwordHash){ if([...this.users.values()].some(u=>u.email===email)) throw Object.assign(new Error('email_exists'),{code:'EMAIL_EXISTS'}); const user={id:String(this.nextUser++),email,password_hash:passwordHash,credits:0,created_at:new Date().toISOString()}; this.users.set(user.id,user); return this.publicUser(user); }
  async getUserByEmail(email){ return [...this.users.values()].find(u=>u.email===email)||null; }
  async getUser(id){ return this.users.get(String(id))||null; }
  publicUser(u){ return u?{id:String(u.id),email:u.email,credits:Number(u.credits||0),created_at:u.created_at}:null; }
  async addCredits(userId,amount){ const u=await this.getUser(userId); if(!u) return null; u.credits=Number(u.credits||0)+amount; return this.publicUser(u); }
  async consumeCredit(userId){ const u=await this.getUser(userId); if(!u||u.credits<1)return false; u.credits--; return true; }
  async saveProject(userId,p){ const id=String(this.nextProject++),row={id,user_id:String(userId),...p,created_at:new Date().toISOString(),updated_at:new Date().toISOString()}; this.projects.set(id,row); return row; }
  async listProjects(userId){ return [...this.projects.values()].filter(p=>p.user_id===String(userId)).sort((a,b)=>b.created_at.localeCompare(a.created_at)); }
  async getProject(userId,id){ const p=this.projects.get(String(id)); return p&&p.user_id===String(userId)?p:null; }
  async deleteProject(userId,id){ const p=await this.getProject(userId,id); if(!p)return false; this.projects.delete(String(id)); return true; }
  async recordEvent(event){ this.events.push({...event,created_at:new Date().toISOString()}); }
  async recordPurchase(eventId,userId,credits,amount){ if(this.purchases.has(eventId))return false; this.purchases.add(eventId); await this.addCredits(userId,credits); return true; }
}

class PostgresDB {
  constructor(url){ this.pool=new Pool({connectionString:url,ssl:process.env.PGSSLMODE==='disable'?false:{rejectUnauthorized:false}}); }
  async init(){ await this.pool.query(`
    create table if not exists vm_users(id bigserial primary key,email text unique not null,password_hash text not null,credits integer not null default 0,created_at timestamptz not null default now());
    create table if not exists vm_projects(id bigserial primary key,user_id bigint not null references vm_users(id) on delete cascade,name text not null,use_case text not null,mode text not null,svg text not null,print_status text not null,print_warnings jsonb not null default '[]',created_at timestamptz not null default now(),updated_at timestamptz not null default now());
    create table if not exists vm_events(id bigserial primary key,user_id bigint null,event_name text not null,metadata jsonb not null default '{}',created_at timestamptz not null default now());
    create table if not exists vm_purchases(event_id text primary key,user_id bigint not null references vm_users(id) on delete cascade,credits integer not null,amount integer not null,created_at timestamptz not null default now());
  `); }
  publicUser(u){ return u?{id:String(u.id),email:u.email,credits:Number(u.credits||0),created_at:u.created_at}:null; }
  async createUser(email,passwordHash){ try{const r=await this.pool.query('insert into vm_users(email,password_hash) values($1,$2) returning *',[email,passwordHash]);return this.publicUser(r.rows[0]);}catch(e){if(e.code==='23505')throw Object.assign(new Error('email_exists'),{code:'EMAIL_EXISTS'});throw e;} }
  async getUserByEmail(email){ const r=await this.pool.query('select * from vm_users where email=$1',[email]);return r.rows[0]||null; }
  async getUser(id){ const r=await this.pool.query('select * from vm_users where id=$1',[id]);return r.rows[0]||null; }
  async addCredits(userId,amount){ const r=await this.pool.query('update vm_users set credits=credits+$2 where id=$1 returning *',[userId,amount]);return this.publicUser(r.rows[0]); }
  async consumeCredit(userId){ const r=await this.pool.query('update vm_users set credits=credits-1 where id=$1 and credits>0 returning id',[userId]);return r.rowCount===1; }
  async saveProject(userId,p){ const r=await this.pool.query('insert into vm_projects(user_id,name,use_case,mode,svg,print_status,print_warnings) values($1,$2,$3,$4,$5,$6,$7::jsonb) returning *',[userId,p.name,p.use_case,p.mode,p.svg,p.print_status,JSON.stringify(p.print_warnings||[])]);return r.rows[0]; }
  async listProjects(userId){ const r=await this.pool.query('select id,name,use_case,mode,print_status,print_warnings,created_at,updated_at from vm_projects where user_id=$1 order by created_at desc limit 100',[userId]);return r.rows; }
  async getProject(userId,id){ const r=await this.pool.query('select * from vm_projects where id=$1 and user_id=$2',[id,userId]);return r.rows[0]||null; }
  async deleteProject(userId,id){ const r=await this.pool.query('delete from vm_projects where id=$1 and user_id=$2',[id,userId]);return r.rowCount===1; }
  async recordEvent(e){ await this.pool.query('insert into vm_events(user_id,event_name,metadata) values($1,$2,$3::jsonb)',[e.user_id||null,e.event_name,JSON.stringify(e.metadata||{})]); }
  async recordPurchase(eventId,userId,credits,amount){ const client=await this.pool.connect();try{await client.query('begin');const ins=await client.query('insert into vm_purchases(event_id,user_id,credits,amount) values($1,$2,$3,$4) on conflict do nothing returning event_id',[eventId,userId,credits,amount]);if(!ins.rowCount){await client.query('rollback');return false;}await client.query('update vm_users set credits=credits+$2 where id=$1',[userId,credits]);await client.query('commit');return true;}catch(e){await client.query('rollback');throw e;}finally{client.release();} }
}

function createDB(){ return process.env.DATABASE_URL?new PostgresDB(process.env.DATABASE_URL):new MemoryDB(); }
module.exports={createDB,MemoryDB,PostgresDB};
