import sys, zlib, struct
def decode(p):
    d=open(p,'rb').read(); assert d[:8]==b'\x89PNG\r\n\x1a\n', p
    i=8; idat=b''; w=h=bd=ct=None; plte=None; trns=None
    while i<len(d):
        ln=struct.unpack('>I',d[i:i+4])[0]; typ=d[i+4:i+8]; body=d[i+8:i+8+ln]; i+=12+ln
        if typ==b'IHDR':
            w,h,bd,ct,comp,filt,ilace=struct.unpack('>IIBBBBB',body)
            assert ilace==0,'interlaced'; assert bd==8,'bitdepth %d'%bd
        elif typ==b'PLTE': plte=body
        elif typ==b'tRNS': trns=body
        elif typ==b'IDAT': idat+=body
        elif typ==b'IEND': break
    raw=zlib.decompress(idat)
    ch={0:1,2:3,3:1,4:2,6:4}[ct]; stride=w*ch
    out=bytearray(); prev=bytearray(stride); pos=0
    for y in range(h):
        f=raw[pos]; pos+=1; line=bytearray(raw[pos:pos+stride]); pos+=stride
        for x in range(stride):
            a=line[x-ch] if x>=ch else 0; b=prev[x]; c=prev[x-ch] if x>=ch else 0
            if f==1: line[x]=(line[x]+a)&255
            elif f==2: line[x]=(line[x]+b)&255
            elif f==3: line[x]=(line[x]+((a+b)>>1))&255
            elif f==4:
                pp=a+b-c; pa=abs(pp-a); pb=abs(pp-b); pc=abs(pp-c)
                pr=a if (pa<=pb and pa<=pc) else (b if pb<=pc else c)
                line[x]=(line[x]+pr)&255
        out+=line; prev=line
    # normalise to RGBA
    rgba=bytearray()
    for k in range(w*h):
        px=out[k*ch:(k+1)*ch]
        if ct==0: r=g=b=px[0]; a=255
        elif ct==2: r,g,b=px; a=255
        elif ct==3: idx=px[0]; r,g,b=plte[idx*3:idx*3+3]; a=trns[idx] if trns and idx<len(trns) else 255
        elif ct==4: r=g=b=px[0]; a=px[1]
        else: r,g,b,a=px
        rgba+=bytes((r,g,b,a))
    return w,h,ct,bytes(rgba)
a=decode(sys.argv[1]); b=decode(sys.argv[2])
print("A: %s  %dx%d colortype=%d"%(sys.argv[1],a[0],a[1],a[2]))
print("B: %s  %dx%d colortype=%d"%(sys.argv[2],b[0],b[1],b[2]))
if a[:2]!=b[:2]: print("DIMENSION MISMATCH"); sys.exit(1)
pa,pb=a[3],b[3]
if pa==pb: print("PIXELS IDENTICAL (%d bytes RGBA)"%len(pa)); sys.exit(0)
n=sum(1 for k in range(0,len(pa),4) if pa[k:k+4]!=pb[k:k+4])
mx=max(abs(pa[k]-pb[k]) for k in range(len(pa)))
print("PIXELS DIFFER: %d of %d pixels (%.4f%%), max channel delta=%d"%(n,len(pa)//4,100.0*n/(len(pa)//4),mx))
shown=0
for k in range(0,len(pa),4):
    if pa[k:k+4]!=pb[k:k+4]:
        y=(k//4)//a[0]; x=(k//4)%a[0]
        print("  (%d,%d) golden=%s linux=%s"%(x,y,tuple(pa[k:k+4]),tuple(pb[k:k+4]))); shown+=1
        if shown>=12: break
