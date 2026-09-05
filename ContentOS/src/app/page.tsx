const cards = [
  ['Capture & Upload','Record in-browser, upload source media, import approved assets, and keep originals in the Content Inbox.'],
  ['AI Studio','Transcribe, detect hooks, cut clips, rewrite openings, create captions/CTAs, subtitle styles, covers and platform variants.'],
  ['Account Network','Connect many owned accounts, assign each an editorial role, audience, niche and posting rules.'],
  ['Calendar & Queue','Drag-and-drop schedule, per-account timing optimization, approval states, retries and failed-post recovery.'],
  ['Unified Inbox','Bring supported comments, mentions, messages and reviews into one triage queue with AI reply drafts and escalation.'],
  ['Analytics Brain','Normalize reach, views, watch time, saves, shares, clicks and conversions; feed winners back into future editing decisions.'],
];

const workflow = ['Record / Upload','Transcribe','Find Moments','Edit & Render','Create Variants','Select Accounts','Optimize Timing','Approve','Publish','Engage','Measure','Learn'];

export default function Home() {
  return <main style={{fontFamily:'Inter,system-ui,sans-serif',maxWidth:1180,margin:'0 auto',padding:'42px 24px 80px',color:'#111827'}}>
    <header style={{display:'flex',justifyContent:'space-between',gap:24,alignItems:'center',marginBottom:50}}>
      <div><div style={{fontSize:13,fontWeight:700,letterSpacing:1.5}}>THEAIGINCY</div><h1 style={{fontSize:52,lineHeight:1.02,margin:'10px 0 12px'}}>Content OS</h1><p style={{maxWidth:690,fontSize:19,color:'#4b5563',lineHeight:1.55}}>One command center to record, repurpose, schedule, publish, engage and learn across a differentiated network of social accounts.</p></div>
      <button style={{border:0,borderRadius:12,padding:'14px 18px',background:'#111827',color:'white',fontWeight:700}}>Connect account</button>
    </header>

    <section style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(250px,1fr))',gap:14,marginBottom:48}}>
      {cards.map(([title,body]) => <article key={title} style={{border:'1px solid #e5e7eb',borderRadius:18,padding:22,background:'#fff'}}><h2 style={{fontSize:18,margin:'0 0 10px'}}>{title}</h2><p style={{margin:0,lineHeight:1.55,color:'#6b7280'}}>{body}</p></article>)}
    </section>

    <section style={{border:'1px solid #e5e7eb',borderRadius:20,padding:24,marginBottom:28}}><h2 style={{marginTop:0}}>Production workflow</h2><div style={{display:'flex',gap:8,flexWrap:'wrap'}}>{workflow.map((step,i)=><span key={step} style={{background:'#f3f4f6',padding:'10px 12px',borderRadius:999,fontSize:14}}>{i+1}. {step}</span>)}</div></section>

    <section style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(300px,1fr))',gap:18}}>
      <article style={{border:'1px solid #e5e7eb',borderRadius:20,padding:24}}><h2 style={{marginTop:0}}>Notifications</h2><p style={{color:'#4b5563',lineHeight:1.55}}>Yes — notifications live inside Content OS. The notification center is designed for new high-priority comments, reply approvals, failed posts, expiring connections, account errors, viral spikes, strategy recommendations and completed render jobs. Push/email delivery can be layered on top.</p></article>
      <article style={{border:'1px solid #e5e7eb',borderRadius:20,padding:24}}><h2 style={{marginTop:0}}>Network rules</h2><p style={{color:'#4b5563',lineHeight:1.55}}>Each connected account receives its own audience, editorial role and creative angle. Content OS routes differentiated variants rather than coordinating artificial engagement or identical spam reposts.</p></article>
    </section>
  </main>
}
