#!/bin/bash

#To compile without GBT Player, change this line to 'include_gbt=0'
include_gbt=1

if [ -f images/sgb_border.inc ]; then
    echo "Not building SGB border since it exists..."
else
    echo "Building SGB border..."
    cd ..
    python sgb_border.py examples/images/sgb_border.png examples/images/sgb_border.inc
    cd examples
fi

cp ../gingerbread.asm .

name="example"

# delete existing ROM, if it exists
if [ -f $name.gb ]; then
    rm $name.gb
fi

echo "Compilation step 1/4: Assembling..."

if [[ $include_gbt -eq 1 ]]; then
    cp ../gbt-player/rgbds_example/gbt_player.asm .
    cp ../gbt-player/rgbds_example/gbt_player_bank1.asm .
    cp ../gbt-player/rgbds_example/hardware.inc .
    cp ../gbt-player/rgbds_example/gbt_player.inc .
    rgbasm -ogbt_player.o gbt_player.asm
    rgbasm -ogbt_player_bank1.o gbt_player_bank1.asm
    rgbasm -ofunkyforest.o music/funkyforest.asm
    
    echo "Assembled GBT-Player related stuff"
fi

rgbasm -o$name.o $name.asm

echo "Compilation step 2/4: Linking..."
if [[ $include_gbt -eq 1 ]]; then
    rgblink -o $name.gb -m $name.map -n $name.sym $name.o gbt_player.o gbt_player_bank1.o funkyforest.o  
else
    rgblink -o $name.gb -m $name.map -n $name.sym $name.o
fi

echo "Compilation step 3/4: Fixing..."
rgbfix -v -p 0x00 $name.gb

echo "Compilation step 4/4: Cleaning up..."
rm *.o
rm *.map
# del *.sym
# You probably want to leave the .sym files for debugging purposes

rm gingerbread.asm
if [[ $include_gbt -eq 1 ]]; then
    rm gbt_player.asm
    rm gbt_player_bank1.asm
    rm hardware.inc
    rm gbt_player.inc
fi
