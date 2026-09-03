const assert = require('assert');
const VectorCore = require('./vector-core.js');

function makeImage(){
  const width=8,height=8,data=new Uint8ClampedArray(width*height*4);
  for(let y=0;y<height;y++) for(let x=0;x<width;x++){
    const i=(y*width+x)*4;
    const inside=x>=2&&x<=5&&y>=2&&y<=5;
    data[i]=inside?0:255; data[i+1]=inside?0:255; data[i+2]=inside?0:255; data[i+3]=255;
  }
  return {width,height,data};
}

const image=makeImage();
const traced=VectorCore.vectorize(image,{colorCount:2,removeBackground:true,detail:'high',mode:'trace'});
assert(traced.shapes.length>0,'expected at least one vector shape');
const svg=VectorCore.resultToSvg(traced);
assert(svg.includes('<path'),'SVG must contain actual path geometry');
assert(!svg.includes('<image'),'SVG must not embed the raster source');
const check=VectorCore.printCheck(traced,'T-shirt / apparel');
assert(['READY','NEEDS ATTENTION'].includes(check.status));
const pdf=VectorCore.resultToPdf(traced);
assert(pdf.type==='application/pdf');
assert(pdf.size>100,'vector PDF should not be empty');
const rebuilt=VectorCore.vectorize(image,{colorCount:2,removeBackground:true,detail:'low',mode:'rebuild'});
assert(rebuilt.shapes.length>0);
console.log('Vector Me core tests passed');
