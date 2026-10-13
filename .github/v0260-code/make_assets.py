"""Offline assets: six cached image-backed tiles plus thirty theme-specific shards."""
from PIL import Image, ImageDraw
from pathlib import Path
import random, sys, base64
root=Path(sys.argv[1]); source=Path(sys.argv[2])
atlas=Image.open(source).convert("RGB"); size=atlas.width//3
assert size>30 and atlas.width==size*3 and atlas.height==size*2
tiles=root/"assets/images/material_tiles";tiles.mkdir(parents=True,exist_ok=True)
frags=root/"assets/images/material_shards";frags.mkdir(parents=True,exist_ok=True)
for idx,name in enumerate(("glass","crystal","marble","stone","wood","leaf")):
    tile=atlas.crop((idx%3*size,idx//3*size,(idx%3+1)*size,(idx//3+1)*size))
    tile=tile.resize((256,256),Image.Resampling.LANCZOS)
    tile.save(tiles/(name+".webp"),"WEBP",quality=84,method=6)
    rng=random.Random(3260+idx)
    for n in range(5):
        k=44;ox=rng.randint(24,180);oy=rng.randint(20,178)
        crop=tile.crop((ox,oy,ox+k,oy+k)).convert("RGBA")
        mask=Image.new("L",(k,k),0); draw=ImageDraw.Draw(mask)
        if name in ("glass","crystal"):
            poly=[(rng.randint(8,18),2),(k-5,rng.randint(5,17)),(k-9,k-7),(9,k-5)]
        elif name=="wood":
            poly=[(16,1),(30,0),(k-11,k-1),(k-25,k-4)]
        elif name=="leaf":
            poly=[(k//2,2),(k-4,k//2),(k//2,k-2),(5,k//2)]
        else:
            poly=[(6,4),(k-5,6),(k-2,19),(k-10,k-3),(10,k-7),(2,20)]
        draw.polygon(poly,fill=255);crop.putalpha(mask)
        crop=crop.rotate(rng.randint(-60,60),resample=Image.Resampling.BICUBIC,expand=True)
        crop.thumbnail((52,52),Image.Resampling.LANCZOS)
        crop.save(frags/(name+"_"+str(n)+".webp"),"WEBP",quality=82,method=6)
assert len(list(tiles.glob("*.webp")))==6 and len(list(frags.glob("*.webp")))==30
print("Six bitmap blocks and thirty image fragments generated")
