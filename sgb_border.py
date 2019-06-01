# This Python script requires Pillow to be installed.
# This can be done by writing the following in the command line (Windows) or terminal (Linux/Mac)
# assuming that Python is correctly installed: "python -m pip install Pillow" (without quotes)

from PIL import Image 

im_path = 'examples/images/sgb_border.png'
im = Image.open(im_path)
im = im.convert('RGB')

outpath = 'examples/images/sgb_border.inc'

# Inserts element e into list l assuming list never goes beyond a length if m, and if so, returns False.
def max_insert(l, e, m):
    if len(l) < m:
        l.append(e)
        return True 
    else:
        return False

colors = [] # all the colors in the image. Can be at most 16
tile_data = [] # max 256 elements   
tile_map = [] # max 1024 elements 

colors.append( (0,0,0) ) # This color should be first. It's used for transparency.
tile_data.append( [0]*64 ) # This tile should be first. It's used for transparency.

# Check dimensions of image 
assert(im.size == (256,256))

# Loop through image to collect blocks
for iy in range(0, 256, 8):
    for ix in range(0, 256, 8):
        
        # Loop through 8x8 block 
        tile = []
        
        for block_y in range(iy, iy+8):
            for block_x in range(ix, ix+8):
                col = im.getpixel((block_x, block_y))
                
                if not col in colors:
                    if max_insert(colors, col, 16):
                        pass 
                    else:
                        raise ValueError('Too many unique colors in the image')
                
                col_index = colors.index(col)
                tile.append(col_index)
                
        if not tile in tile_data:
            if max_insert(tile_data, tile, 256):
                pass
            else:
                raise ValueError('Too many unique tiles in the image')
        
        tile_index = tile_data.index(tile)
        tile_map.append(tile_index)

print("Unique colors used: {} / 16".format(len(colors)))
print("Unique tiles used: {} / 256".format(len(tile_data)))

assert(len(tile_map) == 32*32) # Otherwise the image is of incorrect size or something went wrong 

# Pad tile data with zeros
while len(tile_data) < 256:
    tile_data.append( [0]*64 )

# Pad colors with zeros 
while len(colors) < 16:
    colors.append( (0,0,0) )

s = 'SECTION "SGB Border",ROMX'

def newline(s):
    return s + '\n'

def strformat(p):
    
    s = "DB"
    for i in range(0,256,8):
        pp = p[i:i+8]
        if pp:
            s += " " + str(int("".join(pp), 2)) + ','
    
    s = s[:-1]
    return s

# Converts a tile to the really strange SNES bitplane format     
def convert_to_bitplanes(tile):
    p01 = []
    p23 = []

    for ir in range(8):
        start = 8*ir
        
        row = [tile[x] for x in range(start, start+8)]
        bincols = []
        
        for col in row:
            bincol = "{0:b}".format(col)
            
            while len(bincol) < 4:
                bincol = '0' + bincol 
            
            if len(bincol) >= 5:
                print(col, bincol)
            
            bincols.append(bincol)
        
        p0 = [x[3] for x in bincols]
        p1 = [x[2] for x in bincols]
        p2 = [x[1] for x in bincols]
        p3 = [x[0] for x in bincols]
        
        p01.extend(p0)
        p01.extend(p1)
        p23.extend(p2)
        p23.extend(p3)
            
    return p01, p23 
    
s = newline(s)
s = newline(s+'SGB_VRAM_TILEDATA1:')

for i_tile in range(128):
    tile = tile_data[i_tile]
    p01, p23 = convert_to_bitplanes(tile)
    s = newline(s+strformat(p01))
    s = newline(s+strformat(p23))
    
s = newline(s)
s = newline(s+'SGB_VRAM_TILEDATA2:')

for i_tile in range(128,256):
    tile = tile_data[i_tile]
    p01, p23 = convert_to_bitplanes(tile)
    s = newline(s+strformat(p01))
    s = newline(s+strformat(p23))

s = newline(s)
s = newline(s+'SGB_VRAM_TILEMAP:')

for t in tile_map:
    bint = "{0:b}".format(t)
    
    while len(bint) < 8:
        bint = '0' + bint
    
    s = newline(s+'DB %' + bint + ', %00010000')

s = newline(s)
s = newline(s+'; Palette 4')

for c in colors:
    print(c)

with open(outpath, 'w') as f:
    f.write(s)
    
