(() => {
  'use strict';
  const table=new Uint32Array(256);
  for(let n=0;n<256;n++){let c=n;for(let k=0;k<8;k++)c=(c&1)?0xedb88320^(c>>>1):c>>>1;table[n]=c>>>0;}
  function crc32(bytes){let c=0xffffffff;for(const b of bytes)c=table[(c^b)&0xff]^(c>>>8);return(c^0xffffffff)>>>0;}
  function u16(n){return[n&255,(n>>>8)&255];}
  function u32(n){return[n&255,(n>>>8)&255,(n>>>16)&255,(n>>>24)&255];}
  function encode(v){return v instanceof Uint8Array?v:new TextEncoder().encode(String(v));}
  function makeZip(files){const locals=[],centrals=[];let offset=0;for(const f of files){const name=encode(f.name),data=encode(f.data),crc=crc32(data);const local=new Uint8Array([80,75,3,4,20,0,0,0,0,0,0,0,0,0,...u32(crc),...u32(data.length),...u32(data.length),...u16(name.length),0,0,...name,...data]);locals.push(local);const central=new Uint8Array([80,75,1,2,20,0,20,0,0,0,0,0,0,0,0,0,...u32(crc),...u32(data.length),...u32(data.length),...u16(name.length),0,0,0,0,0,0,0,0,0,0,0,0,0,0,...u32(offset),...name]);centrals.push(central);offset+=local.length;}const centralSize=centrals.reduce((n,b)=>n+b.length,0),end=new Uint8Array([80,75,5,6,0,0,0,0,...u16(files.length),...u16(files.length),...u32(centralSize),...u32(offset),0,0]);return new Blob([...locals,...centrals,end],{type:'application/zip'});}
  window.VectorZip={makeZip};
})();
