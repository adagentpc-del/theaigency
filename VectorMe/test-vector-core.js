const assert = require('assert');
const VectorCore = require('./vector-core.js');

function makeImage(){
  const width=8,height=8,data=new Uint8ClampedArray(width*height*4);
  for(let y=0;y<height;y++) for(let x=0;x<width;x++){
    const i=(y*width+x)*4,inside=x>=2&&x<=5&&y>=2&&y<=5;
    data[i]=inside?0:255; data[i+1]=inside?0:255; data[i+2]=inside?0:255; data[i+3]=255;
  }
  return {width,height,data};
}
function makeRing(){
  const width=12,height=12,data=new Uint8ClampedArray(width*height*4);
  for(let y=0;y<height;y++) for(let x=0;x<width;x++){
    const i=(y*width+x)*4,outer=x>=2&&x<=9&&y>=2&&y<=9,hole=x>=5&&x<=6&&y>=5&&y<=6,black=outer&&!hole;
    data[i]=black?0:255;data[i+1]=black?0:255;data[i+2]=black?0:255;data[i+3]=255;
  }
  return {width,height,data};
}

const traced=VectorCore.vectorize(makeImage(),{colorCount:2,removeBackground:true,detail:'high',mode:'trace'});
assert(traced.shapes.length>0,'expected at least one vector shape');
const svg=VectorCore.resultToSvg(traced);
assert(svg.includes('<path'),'SVG must contain actual path geometry');
assert(!svg.includes('<image'),'SVG must not embed the raster source');
assert(svg.includes('fill-rule="evenodd"'),'SVG should preserve compound cutouts');
const check=VectorCore.printCheck(traced,'T-shirt / apparel');
assert(['READY','NEEDS ATTENTION'].includes(check.status));
const pdf=VectorCore.resultToPdf(traced);
assert(pdf.type==='application/pdf');
assert(pdf.size>100,'vector PDF should not be empty');
const rebuilt=VectorCore.vectorize(makeImage(),{colorCount:2,removeBackground:true,detail:'low',mode:'rebuild'});
assert(rebuilt.shapes.length>0);
const ring=VectorCore.vectorize(makeRing(),{colorCount:2,removeBackground:true,detail:'high',mode:'trace'});
assert(ring.shapes.some(s=>Array.isArray(s.loops)&&s.loops.length>1),'ring should produce a compound shape with a cutout loop');
const ringSvg=VectorCore.resultToSvg(ring);
assert(!ringSvg.includes('<image'));
console.log('Vector Me core tests passed');
