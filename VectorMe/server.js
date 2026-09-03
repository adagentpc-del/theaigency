'use strict';
const path=require('path');
const fs=require('fs');
const crypto=require('crypto');
const express=require('express');
const helmet=require('helmet');
const Stripe=require('stripe');
const {createDB}=require('./db');
const {createSession,verifySession,parseCookies,hashPassword,verifyPassword,validateEmail,validatePassword}=require('./auth');

const app=express();
const db=createDB();
const PORT=Number(process.env.PORT||8080);
const BASE_URL=(process.env.BASE_URL||`http://localhost:${PORT}`).replace(/\/$/,'');
const SESSION_SECRET=process.env.SESSION_SECRET||'dev-only-change-me';
const isProd=process.env.NODE_ENV==='production';
if(isProd&&SESSION_SECRET==='dev-only-change-me') throw new Error('SESSION_SECRET is required in production');
const stripe=process.env.STRIPE_SECRET_KEY?new Stripe(process.env.STRIPE_SECRET_KEY):null;
const CREDIT_PACKS={small:{credits:20,amount:499,name:'20 Vector Me exports'},pro:{credits:100,amount:999,name:'100 Vector Me exports'}};

app.disable('x-powered-by');
app.use(helmet({contentSecurityPolicy:{directives:{defaultSrc:["'self'"],scriptSrc:["'self'"],styleSrc:["'self'","'unsafe-inline'"],imgSrc:["'self'","blob:","data:"],connectSrc:["'self'"],objectSrc:["'none'"],baseUri:["'self'"],frameAncestors:["'none'"]}}}));

const buckets=new Map();
function rateLimit(windowMs,max){return(req,res,next)=>{const now=Date.now(),key=(req.ip||req.socket.remoteAddress||'unknown')+':'+req.path,entry=buckets.get(key)||{start:now,count:0};if(now-entry.start>windowMs){entry.start=now;entry.count=0;}entry.count++;buckets.set(key,entry);if(entry.count>max)return res.status(429).json({error:'too_many_requests'});next();};}
function requireSameOrigin(req,res,next){if(!['POST','PUT','PATCH','DELETE'].includes(req.method))return next();const origin=req.get('origin');if(!origin||origin===BASE_URL)return next();return res.status(403).json({error:'origin_rejected'});}
function attachUser(req,res,next){const token=parseCookies(req.headers.cookie||'').vm_session;req.session=verifySession(token,SESSION_SECRET);next();}
async function requireUser(req,res,next){if(!req.session)return res.status(401).json({error:'authentication_required'});const u=await db.getUser(req.session.sub);if(!u)return res.status(401).json({error:'authentication_required'});req.user=u;next();}
function setSession(res,userId){const token=createSession(userId,SESSION_SECRET);res.setHeader('Set-Cookie',`vm_session=${encodeURIComponent(token)}; Path=/; HttpOnly; SameSite=Lax; Max-Age=${60*60*24*30}${isProd?'; Secure':''}`);}
function clearSession(res){res.setHeader('Set-Cookie',`vm_session=; Path=/; HttpOnly; SameSite=Lax; Max-Age=0${isProd?'; Secure':''}`);}

app.post('/api/stripe/webhook',express.raw({type:'application/json',limit:'1mb'}),async(req,res)=>{if(!stripe||!process.env.STRIPE_WEBHOOK_SECRET)return res.status(503).send('stripe_not_configured');let event;try{event=stripe.webhooks.constructEvent(req.body,req.headers['stripe-signature'],process.env.STRIPE_WEBHOOK_SECRET);}catch{return res.status(400).send('invalid_signature');}if(event.type==='checkout.session.completed'){const s=event.data.object,userId=s.metadata?.user_id,pack=s.metadata?.pack;const cfg=CREDIT_PACKS[pack];if(userId&&cfg&&s.payment_status==='paid')await db.recordPurchase(event.id,userId,cfg.credits,Number(s.amount_total||cfg.amount));}res.json({received:true});});

app.use(express.json({limit:'2mb'}));
app.use(requireSameOrigin);
app.use(attachUser);

app.get('/api/health',(req,res)=>res.json({ok:true,service:'vector-me'}));
app.post('/api/auth/register',rateLimit(15*60_000,20),async(req,res)=>{const email=String(req.body?.email||'').trim().toLowerCase(),password=req.body?.password;if(!validateEmail(email)||!validatePassword(password))return res.status(400).json({error:'invalid_credentials_format'});try{const user=await db.createUser(email,await hashPassword(password));setSession(res,user.id);res.status(201).json({user});}catch(e){if(e.code==='EMAIL_EXISTS')return res.status(409).json({error:'email_exists'});throw e;}});
app.post('/api/auth/login',rateLimit(15*60_000,30),async(req,res)=>{const email=String(req.body?.email||'').trim().toLowerCase(),password=req.body?.password||'';const u=await db.getUserByEmail(email);if(!u||!await verifyPassword(password,u.password_hash))return res.status(401).json({error:'invalid_login'});setSession(res,u.id);res.json({user:db.publicUser?db.publicUser(u):{id:String(u.id),email:u.email,credits:Number(u.credits||0)}});});
app.post('/api/auth/logout',(req,res)=>{clearSession(res);res.json({ok:true});});
app.get('/api/me',async(req,res)=>{if(!req.session)return res.json({user:null});const u=await db.getUser(req.session.sub);res.json({user:u?(db.publicUser?db.publicUser(u):{id:String(u.id),email:u.email,credits:Number(u.credits||0)}):null});});

function validProject(body){return body&&typeof body.name==='string'&&body.name.length<=120&&typeof body.svg==='string'&&body.svg.length<=1_500_000&&/^<svg[\s>]/i.test(body.svg)&&!/<(?:script|image|foreignObject|iframe|object|embed)\b/i.test(body.svg)&&!/(?:javascript:|data:text\/html|on\w+\s*=)/i.test(body.svg);}
app.get('/api/projects',requireUser,async(req,res)=>res.json({projects:await db.listProjects(req.user.id)}));
app.post('/api/projects',rateLimit(60_000,30),requireUser,async(req,res)=>{if(!validProject(req.body))return res.status(400).json({error:'invalid_project'});const p=await db.saveProject(req.user.id,{name:req.body.name.trim()||'Untitled',use_case:String(req.body.use_case||'General').slice(0,80),mode:['trace','rebuild'].includes(req.body.mode)?req.body.mode:'trace',svg:req.body.svg,print_status:String(req.body.print_status||'READY').slice(0,40),print_warnings:Array.isArray(req.body.print_warnings)?req.body.print_warnings.slice(0,30).map(v=>String(v).slice(0,300)):[]});res.status(201).json({project:p});});
app.get('/api/projects/:id',requireUser,async(req,res)=>{const p=await db.getProject(req.user.id,req.params.id);if(!p)return res.status(404).json({error:'not_found'});res.json({project:p});});
app.delete('/api/projects/:id',requireUser,async(req,res)=>{if(!await db.deleteProject(req.user.id,req.params.id))return res.status(404).json({error:'not_found'});res.json({ok:true});});

app.post('/api/events',rateLimit(60_000,120),async(req,res)=>{const name=String(req.body?.event_name||'');if(!/^[a-z0-9_]{2,64}$/.test(name))return res.status(400).json({error:'invalid_event'});const meta=req.body?.metadata&&typeof req.body.metadata==='object'?JSON.parse(JSON.stringify(req.body.metadata).slice(0,4000)):{};await db.recordEvent({user_id:req.session?.sub||null,event_name:name,metadata:meta});res.status(204).end();});
app.get('/api/pricing',(req,res)=>res.json({packs:CREDIT_PACKS}));
app.post('/api/checkout',requireUser,rateLimit(60_000,10),async(req,res)=>{const pack=String(req.body?.pack||''),cfg=CREDIT_PACKS[pack];if(!cfg)return res.status(400).json({error:'invalid_pack'});if(!stripe)return res.status(503).json({error:'payments_not_configured'});const session=await stripe.checkout.sessions.create({mode:'payment',success_url:`${BASE_URL}/?checkout=success`,cancel_url:`${BASE_URL}/?checkout=cancelled`,customer_email:req.user.email,line_items:[{quantity:1,price_data:{currency:'usd',unit_amount:cfg.amount,product_data:{name:cfg.name}}}],metadata:{user_id:String(req.user.id),pack}});res.json({url:session.url});});

const seo={
 '/png-to-vector':['PNG to Vector Converter','Convert PNG logos and artwork to scalable SVG and vector PDF files.'],
 '/jpg-to-vector':['JPG to Vector Converter','Convert JPG artwork into scalable vector paths for print and production.'],
 '/image-to-svg':['Image to SVG Converter','Turn raster artwork into a genuine SVG made from vector paths.'],
 '/logo-to-vector':['Logo to Vector Converter','Make your logo scalable and print-ready without Illustrator.'],
 '/ai-image-to-vector':['AI Image to Vector','Turn AI-generated logos and graphics into production-ready vector artwork.'],
 '/chatgpt-image-to-vector':['ChatGPT Image to Vector','Convert artwork created with ChatGPT into SVG and vector PDF files for printers and manufacturers.'],
 '/logo-for-tshirt-printing':['Logo Files for T-Shirt Printing','Prepare scalable logo artwork for apparel and T-shirt printing.'],
 '/logo-for-screen-printing':['Logo Files for Screen Printing','Prepare clean, reduced-color vector artwork for screen printing.'],
 '/logo-for-embroidery':['Logo Files for Embroidery','Prepare clean vector artwork for embroidery digitization.'],
 '/logo-for-sign-printing':['Logo Files for Sign Printing','Create scalable vector artwork for signs, banners and large-format graphics.'],
 '/png-to-svg':['PNG to SVG Converter','Convert PNG artwork into genuine SVG vector paths.']
};
const indexPath=path.join(__dirname,'index.html');
function pageHtml(route){let html=fs.readFileSync(indexPath,'utf8');const data=seo[route];if(data){html=html.replace(/<title>.*?<\/title>/,`<title>${data[0]} — Vector Me</title>`).replace(/<meta name="description" content="[^"]*" \/>/,`<meta name="description" content="${data[1]}" />`).replace('</head>',`<link rel="canonical" href="${BASE_URL}${route}" /></head>`);}return html;}
Object.keys(seo).forEach(route=>app.get(route,(req,res)=>res.type('html').send(pageHtml(route))));
app.get('/robots.txt',(req,res)=>res.type('text').send(`User-agent: *\nAllow: /\nSitemap: ${BASE_URL}/sitemap.xml\n`));
app.get('/sitemap.xml',(req,res)=>{const routes=['/',...Object.keys(seo)];res.type('application/xml').send(`<?xml version="1.0" encoding="UTF-8"?><urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">${routes.map(r=>`<url><loc>${BASE_URL}${r==='/'?'':r}</loc></url>`).join('')}</urlset>`);});
app.use(express.static(__dirname,{index:false,maxAge:isProd?'1h':0,setHeaders(res,file){if(file.endsWith('.html'))res.setHeader('Cache-Control','no-store');}}));
app.get('/',(req,res)=>res.sendFile(indexPath));
app.use((req,res)=>res.status(404).json({error:'not_found'}));
app.use((err,req,res,next)=>{console.error(err);res.status(500).json({error:'internal_error'});});

async function start(){await db.init();return app.listen(PORT,()=>console.log(`Vector Me listening on ${PORT}`));}
if(require.main===module)start().catch(e=>{console.error(e);process.exit(1);});
module.exports={app,db,start,CREDIT_PACKS};
