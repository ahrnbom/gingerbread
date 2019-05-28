# This Python script requires Pillow to be installed.
# This can be done by writing the following in the command line (Windows) or terminal (Linux/Mac)
# assuming that Python is correctly installed: "python -m pip install Pillow" (without quotes)

from PIL import Image 

im_path = 'examples/images/sgb_border.png'
im = Image.open(im_path)
im = im.convert('RGB')

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
                    if max_insert(colors, col, 17):
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

print("Unique colors used: {}".format(len(colors)))
print("Unique tiles used: {}".format(len(tile_data)))

assert(len(tile_map) == 32*32) # Otherwise the image is of incorrect size or something went wrong 

