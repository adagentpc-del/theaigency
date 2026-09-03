(() => {
  'use strict';

  const $ = (id) => document.getElementById(id);
  const els = {
    fileInput: $('fileInput'), uploadButton: $('uploadButton'), uploadError: $('uploadError'), workspace: $('workspace'),
    fileName: $('fileName'), originalPreview: $('originalPreview'), vectorPreview: $('vectorPreview'), vectorizeButton: $('vectorizeButton'),
    colorCount: $('colorCount'), removeBackground: $('removeBackground'), detail: $('detail'), statusText: $('statusText'),
    useCases: $('useCases'), printCheck: $('printCheck'), printStatus: $('printStatus'), printWarnings: $('printWarnings'),
    exports: $('exports'), downloadSvg: $('downloadSvg'), downloadPdf: $('downloadPdf'), downloadPng: $('downloadPng'), resetButton: $('resetButton')
  };

  const useCases = ['T-shirt / apparel','Jersey / uniform','Hat / embroidery','Screen printing','Sign / banner','Vinyl / decal','Sticker','Packaging','Business printing','Web / digital','Just give me the vector'];
  let state = { file:null, image:null, mode:'trace', useCase:useCases[0], result:null, svg:null, sourceUrl:null };

  function initUseCases(){
    els.useCases.innerHTML='';
    useCases.forEach((name,i)=>{
      const b=document.createElement('button'); b.type='button'; b.className='chip'+(i===0?' active':''); b.textContent=name;
      b.addEventListener('click',()=>{ state.useCase=name; [...els.useCases.children].forEach(x=>x.classList.toggle('active',x===b)); if(state.result) renderPrintCheck(); });
      els.useCases.appendChild(b);
    });
  }

  function setView(view){
    document.querySelectorAll('.tab').forEach(b=>b.classList.toggle('active',b.dataset.view===view));
    els.originalPreview.classList.toggle('hidden',view!=='original');
    els.vectorPreview.classList.toggle('hidden',view!=='vector');
  }

  function validateFile(file){
    if(!file) return 'Choose an image first.';
    const allowed=['image/png','image/jpeg','image/webp'];
    if(!allowed.includes(file.type)) return 'Please upload a PNG, JPG, or WEBP image.';
    if(file.size>20*1024*1024) return 'This file is larger than the 20 MB MVP limit.';
    return '';
  }

  function handleFile(file){
    const error=validateFile(file); els.uploadError.textContent=error; if(error)return;
    if(state.sourceUrl) URL.revokeObjectURL(state.sourceUrl);
    state.file=file; state.sourceUrl=URL.createObjectURL(file); state.result=null; state.svg=null;
    const img=new Image();
    img.onload=()=>{
      if(img.naturalWidth<16||img.naturalHeight<16){ els.uploadError.textContent='This image is too small to vectorize reliably.'; return; }
      if(img.naturalWidth*img.naturalHeight>36_000_000){ els.uploadError.textContent='This image has too many pixels. Resize it below 36 megapixels and try again.'; return; }
      state.image=img; els.originalPreview.src=state.sourceUrl; els.fileName.textContent=file.name; els.workspace.classList.remove('hidden');
      els.printCheck.classList.add('hidden'); els.exports.classList.add('hidden'); els.vectorPreview.innerHTML=''; setView('original');
      els.statusText.textContent=`${img.naturalWidth} × ${img.naturalHeight}px loaded. Choose settings and vectorize.`;
      els.workspace.scrollIntoView({behavior:'smooth',block:'start'});
    };
    img.onerror=()=>{ els.uploadError.textContent='The image could not be decoded. It may be corrupt or mislabeled.'; };
    img.src=state.sourceUrl;
  }

  function rasterizeForProcessing(){
    const maxDim=1100, w=state.image.naturalWidth, h=state.image.naturalHeight, scale=Math.min(1,maxDim/Math.max(w,h));
    const cw=Math.max(1,Math.round(w*scale)), ch=Math.max(1,Math.round(h*scale));
    const canvas=document.createElement('canvas'); canvas.width=cw; canvas.height=ch;
    const ctx=canvas.getContext('2d',{willReadFrequently:true});
    ctx.imageSmoothingEnabled=true; ctx.imageSmoothingQuality='high'; ctx.drawImage(state.image,0,0,cw,ch);
    return {canvas,ctx,imageData:ctx.getImageData(0,0,cw,ch)};
  }

  function vectorize(){
    if(!state.image)return;
    els.vectorizeButton.disabled=true; els.statusText.textContent='Analyzing colors and tracing shapes…';
    requestAnimationFrame(()=>setTimeout(()=>{
      try{
        const {imageData}=rasterizeForProcessing();
        state.result=VectorCore.vectorize(imageData,{colorCount:Number(els.colorCount.value),removeBackground:els.removeBackground.checked,detail:els.detail.value,mode:state.mode});
        if(!state.result.shapes.length) throw new Error('No vector shapes found');
        state.svg=VectorCore.resultToSvg(state.result); els.vectorPreview.innerHTML=state.svg; els.vectorPreview.classList.add('vector-preview');
        renderPrintCheck(); els.exports.classList.remove('hidden'); setView('vector');
        const nodes=state.result.shapes.reduce((n,s)=>n+s.points.length,0);
        els.statusText.textContent=`Created ${state.result.shapes.length} vector shapes with ${nodes.toLocaleString()} path nodes.`;
      }catch(err){
        console.error(err); els.statusText.textContent='This image could not be vectorized with the current settings. Try fewer colors or lower detail.';
      }finally{ els.vectorizeButton.disabled=false; }
    },30));
  }

  function renderPrintCheck(){
    const check=VectorCore.printCheck(state.result,state.useCase); els.printCheck.classList.remove('hidden'); els.printStatus.textContent=check.status;
    els.printWarnings.innerHTML='';
    const warnings=check.warnings.length?check.warnings:['No major production issues detected by the automated check. Your manufacturer may still have additional requirements.'];
    warnings.forEach(w=>{const li=document.createElement('li'); li.textContent=w; els.printWarnings.appendChild(li);});
  }

  function downloadBlob(blob,name){ const a=document.createElement('a'); const url=URL.createObjectURL(blob); a.href=url; a.download=name; document.body.appendChild(a); a.click(); a.remove(); setTimeout(()=>URL.revokeObjectURL(url),1500); }
  function basename(){ return (state.file?.name||'artwork').replace(/\.[^.]+$/,'').replace(/[^a-z0-9_-]+/gi,'-').replace(/^-|-$/g,'')||'artwork'; }

  function downloadSvg(){ if(state.svg) downloadBlob(new Blob([state.svg],{type:'image/svg+xml;charset=utf-8'}),`${basename()}-vector.svg`); }
  function downloadPdf(){ if(state.result) downloadBlob(VectorCore.resultToPdf(state.result),`${basename()}-vector.pdf`); }
  function downloadPng(){
    if(!state.result)return; const svgBlob=new Blob([state.svg],{type:'image/svg+xml'}),url=URL.createObjectURL(svgBlob),img=new Image();
    img.onload=()=>{ const scale=Math.min(4,4096/Math.max(state.result.width,state.result.height)); const c=document.createElement('canvas'); c.width=Math.round(state.result.width*scale); c.height=Math.round(state.result.height*scale); const ctx=c.getContext('2d'); ctx.drawImage(img,0,0,c.width,c.height); URL.revokeObjectURL(url); c.toBlob(b=>b&&downloadBlob(b,`${basename()}-transparent.png`),'image/png'); }; img.src=url;
  }

  function reset(){
    if(state.sourceUrl)URL.revokeObjectURL(state.sourceUrl); state={file:null,image:null,mode:'trace',useCase:useCases[0],result:null,svg:null,sourceUrl:null};
    els.fileInput.value=''; els.workspace.classList.add('hidden'); els.uploadError.textContent=''; els.statusText.textContent=''; initUseCases();
  }

  els.uploadButton.addEventListener('click',()=>els.fileInput.click()); els.fileInput.addEventListener('change',e=>handleFile(e.target.files[0]));
  ['dragenter','dragover'].forEach(ev=>els.uploadButton.addEventListener(ev,e=>{e.preventDefault();els.uploadButton.classList.add('drag');}));
  ['dragleave','drop'].forEach(ev=>els.uploadButton.addEventListener(ev,e=>{e.preventDefault();els.uploadButton.classList.remove('drag');}));
  els.uploadButton.addEventListener('drop',e=>handleFile(e.dataTransfer.files[0]));
  document.querySelectorAll('.mode').forEach(b=>b.addEventListener('click',()=>{state.mode=b.dataset.mode;document.querySelectorAll('.mode').forEach(x=>x.classList.toggle('active',x===b));}));
  document.querySelectorAll('.tab').forEach(b=>b.addEventListener('click',()=>setView(b.dataset.view)));
  els.vectorizeButton.addEventListener('click',vectorize); els.downloadSvg.addEventListener('click',downloadSvg); els.downloadPdf.addEventListener('click',downloadPdf); els.downloadPng.addEventListener('click',downloadPng); els.resetButton.addEventListener('click',reset);
  initUseCases();
})();
