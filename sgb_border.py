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
tile_data1 = [] # max 128 elements
tile_data2 = [] # max 128 elements 

tile_map = [] # max 1024 elements 

# Check dimensions of image 
assert(im.size == (256,256))

# Loop through image to collect blocks 
for iy in range(0, 256, 8):
    for ix in range(0, 256, 8):
        pass 
        
