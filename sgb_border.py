# This Python script requires Pillow to be installed.
# This can be done by writing the following in the command line (Windows) or terminal (Linux/Mac)
# assuming that Python is correctly installed: "python -m pip install Pillow" (without quotes)
# or "python3 -m pip install Pillow" or "pip install Pillow" or "pip3 install Pillow", depending on your setup.

from PIL import Image 
from random import shuffle # everyday I'm shufflin'

def convert(im_path, outpath):
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

    colors = [] # all the colors in the image. Can be at most 64
    tile_data = [] # max 256 elements
    tile_map = [] # max 1024 elements
    palette_deps = [] # one per tile, which colors need to exist together in one palette
    palette_map = [] # one per tile, which palette each tile uses
    palettes = [] # Max 4 palettes, each containing 16 colors 

    for i in range(4):
        palettes.append([0]) # All palettes should contain transparancy 

    colors.append( (0,0,0) ) # This color should be first. It's used for transparency.
    tile_data.append( [0]*64 ) # This tile should be first. It's used for transparency.

    # Check dimensions of image 
    assert(im.size == (256,256))

    # Loop through image to collect unique colors and palette dependencies 
    for iy in range(0, 256, 8):
        for ix in range(0, 256, 8):
            palette_dep = set()
        
            for block_y in range(iy, iy+8):
                for block_x in range(ix, ix+8):
                    col = im.getpixel((block_x, block_y))
                    if not col in colors:
                        if max_insert(colors, col, 64):
                            pass
                        else:
                            raise ValueError('Too many unique colors in the image')
                    
                    col_index = colors.index(col)
                    palette_dep.add(col_index)
            palette_deps.append(palette_dep)


    # Make this non-deterministic so that, if it fails to build good palettes when it should be possible, 
    # you can just try again        
    shuffle(palette_deps) 

    for pd in palette_deps:
        # First check if any existing palette contains all or some of the colors of this tile
        best = -1
        best_i = -1
        for i,p in enumerate(palettes):
            this_one = 0
            remaining = 0
            for c in pd:
                if c in p:
                    this_one += 1
                else:
                    remaining += 1
            
            if this_one > best:
                # Check if this one has room for all the remaining colors
                if remaining + len(p) > 16:
                    # Yeah nah 
                    continue 
                
                best = this_one
                best_i = i
        
        if best > -1:
            palette_to_use = best_i
        else:
            # We need to create a new palette 
            palette_to_use = len(palettes)
            new_palette = []
            if not max_insert(palettes, new_palette, 4):
                raise RuntimeError("Algorithm failed to fit all the colors into 4 palettes. Try running again or using fewer colors.")
                
        # Add any colors to the palette that aren't already in there 
        for c in pd:
            if not c in palettes[palette_to_use]:
                if not max_insert(palettes[palette_to_use], c, 16):
                    raise RuntimeError("What is this I don't even")
        
    # Loop through image to collect blocks
    for iy in range(0, 256, 8):
        for ix in range(0, 256, 8):
            
            # Loop through 8x8 block 
            tile = []
            
            # First find all the colors in the block and see which palette to use
            block_cols = []        
            for block_y in range(iy, iy+8):
                for block_x in range(ix, ix+8):
                    col = im.getpixel((block_x, block_y))
                    col_index = colors.index(col)
                    if not col_index in block_cols:
                        block_cols.append(col_index)
            
            palette_index = -1
            for ip,p in enumerate(palettes):
                works = True
                for c in block_cols:
                    if not c in p:
                        works = False 
                
                if works:
                    palette_index = ip
            
            assert(palette_index > -1)
                    
            for block_y in range(iy, iy+8):
                for block_x in range(ix, ix+8):
                    col = im.getpixel((block_x, block_y))
                    
                    col_index = colors.index(col)
                    col_index_2 = palettes[palette_index].index(col_index)
                    tile.append(col_index_2)
                    
            if not tile in tile_data:
                if max_insert(tile_data, tile, 256):
                    pass
                else:
                    raise ValueError('Too many unique tiles in the image')
            
            tile_index = tile_data.index(tile)
            tile_map.append(tile_index)
            palette_map.append(palette_index)

    print("Unique colors used: {} / 64".format(len(colors)))
    print("Unique tiles used: {} / 256".format(len(tile_data)))

    assert(len(tile_map) == 32*32) # Otherwise the image is of incorrect size or something went wrong 

    # Pad tile data with zeros
    while len(tile_data) < 256:
        tile_data.append( [0]*64 )

    # Pad colors with zeros 
    for p in palettes:
        while len(p) < 16:
            p.append(0)
        
    s = ';This Super Game Boy border file is generated by sgb_border.py at https://github.com/ahrnbom/gingerbread' 

    def newline(s):
        return s + '\n'

    s = newline(s)
    s = newline(s) 
    s = newline(s + 'SECTION "SGB Border",ROMX')    
        
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

    for t,p in zip(tile_map, palette_map):
        bint = "{0:b}".format(t)
        
        while len(bint) < 8:
            bint = '0' + bint
        
        if p == 0:
            s2 = "%00010000"
        elif p == 1:
            s2 = "%00010100"
        elif p == 2:
            s2 = "%00011000"
        elif p == 3:
            s2 = "%00011100"
        
        s = newline(s+'DB %' + bint + ', ' + s2)

    s = newline(s)
    s = newline(s)

    def col2bits(x):
        x = float(x)/256
        x = int(round(31*x))
        x = "{0:b}".format(x)
        while len(x) < 5:
            x = "0" + x 
        return x 

    for ip, palette in enumerate(palettes):
        s = newline(s+'; Palette '+str(4+ip))

        palette_colors = [colors[i] for i in palette]
        for c in palette_colors:
            r,g,b = c
            r = col2bits(r)
            g = col2bits(g)
            b = col2bits(b)

            s = newline(s + "DB %" + g[2:] + r + ', %0' + b + g[:2])
        
        s = newline(s)

    s = newline(s)
    s = newline(s + 'SGB_VRAMTRANS_GBTILEMAP:')

    for iy in range(32):
        line = 'DB '
        start = iy*20
        
        for ix in range(20):
            x = str(min(start+ix, 255)) 
            while len(x) < 3:
                x = ' '+x
            line += x + ','
        
        for ix in range(12):
            line += '  0,'
        
        line = line[:-1]
        
        s = newline(s+line)

    with open(outpath, 'w') as f:
        f.write(s)
        
if __name__ == "__main__":
    import sys
    
    if len(sys.argv) < 3:
        print("Usage: python sgb_border.py INFILE OUTFILE")
        print("INFILE should be a path to a .png image which fulfills the requirements for an SGB border")
        print("OUTFILE should be a path where a .inc file should be created, which can be included in a Game Boy game written with RGBDS and GingerBread")
    else:
        im_path = sys.argv[1]
        outpath = sys.argv[2]
        convert(im_path, outpath)