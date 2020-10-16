# GingerBread
A library with some standard functions for making your own Game Boy games in Assembly, written from scratch. It was made alongside the book *Game Boy Assembly Programming for the Modern Game Developer* which [can be downloaded here](https://github.com/ahrnbom/gbapfomgd).

## Functionality
The GingerBread library attempts to contain a lot of basic functionality needed for most Game Boy games. It takes care of things like 

1. Defining various constants that are easier to remember than random memory addresses
1. Defining several low-level function that most games would need, like 
    * Reading key input 
    * Displaying graphics 
    * Writing text and numbers 
    * Playing sound effects
    * Super Game Boy and Game Boy Color functionality 
    * Managing save data 
1. Taking care of the boot process
1. Defining the ROM header 

The idea is to reduce the amount of boilerplate code needed to get started with Game Boy game development in Assembly. The book contains lots of examples and also servs as documentation for this library. 

The library does not directly support playing background music. Instead, it is designed to be used alongside [GBT-Player](https://github.com/AntonioND/gbt-player) which is included as a git submodule. The library can also be used without GBT-Player.

## Requirements
[RGBDS](https://github.com/rednex/rgbds) is necessary to compile GingerBread and its example(s). 

## To do
1. Make a stand-alone documentation document, specifying the constants and functions defined by GingerBread. Most of it is in the book, but having it available stand-alone is probably useful to many.

### Legal stuff 
The library is released under the The Unlicense. It basically means you are allowed to use it for whatever purpose. 

This library is written with no association or cooperation with Nintendo. The Game Boy is a trademark of Nintendo. 
