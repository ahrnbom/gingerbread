@echo off

if exist images/sgb_border.inc (
echo Not building SGB border since it exists...
) else (
echo Building SGB border...
cd ..
python sgb_border.py examples/images/sgb_border.png examples/images/sgb_border.inc
cd examples
)

copy ..\gingerbread.asm .

set name="example"

REM delete existing ROM, if it exists
if exist %name%.gb del %name%.gb

echo Compilation step 1/4: Assembling...
rgbasm -o%name%.o %name%.asm
if errorlevel 1 goto cleanup
echo Compilation step 2/4: Linking...
rgblink -o %name%.gb -m %name%.map -n %name%.sym %name%.o
if errorlevel 1 goto cleanup
echo Compilation step 3/4: Fixing...
rgbfix -v %name%.gb

:cleanup
echo Compilation step 4/4: Cleaning up...
del *.o
del *.map
rem del *.sym
rem You probably want to leave the .sym files for debugging purposes
del gingerbread.asm