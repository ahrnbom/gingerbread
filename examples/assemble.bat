@echo off

rem To compile without GBT Player, change this line to 'set "include_gbt="' 
rem and comment out USE_GBT_PLAYER in the %name%.asm if necessary
set "include_gbt="

rem To compile the Hello World demo, change this to "hello-world"
set name="example"

if exist images/sgb_border.inc (
echo Not building SGB border since it exists...
) else (
echo Building SGB border...
cd ..
python sgb_border.py examples/images/sgb_border.png examples/images/sgb_border.inc
cd examples
)

copy ..\gingerbread.asm .

REM delete existing ROM, if it exists
if exist %name%.gb del %name%.gb

echo Compilation step 1/4: Assembling...

if defined include_gbt (
copy ..\gbt-player\rgbds_example\gbt_player.asm .
copy ..\gbt-player\rgbds_example\gbt_player_bank1.asm .
copy ..\gbt-player\rgbds_example\hardware.inc .
copy ..\gbt-player\rgbds_example\gbt_player.inc .
rgbasm -ogbt_player.o gbt_player.asm
rgbasm -ogbt_player_bank1.o gbt_player_bank1.asm
rgbasm -ofunkyforest.o music\funkyforest.asm
)

rgbasm -o%name%.o %name%.asm

if errorlevel 1 goto cleanup

echo Compilation step 2/4: Linking...
if defined include_gbt (
rgblink -o %name%.gb -m %name%.map -n %name%.sym %name%.o gbt_player.o gbt_player_bank1.o funkyforest.o  
) else (
rgblink -o %name%.gb -m %name%.map -n %name%.sym %name%.o
)

if errorlevel 1 goto cleanup

echo Compilation step 3/4: Fixing...
rgbfix -v -p 0x00 %name%.gb

:cleanup
echo Compilation step 4/4: Cleaning up...
del *.o
del *.map
rem del *.sym
rem You probably want to leave the .sym files for debugging purposes

del gingerbread.asm
if defined include_gbt (
del gbt_player.asm
del gbt_player_bank1.asm
del hardware.inc
del gbt_player.inc
)