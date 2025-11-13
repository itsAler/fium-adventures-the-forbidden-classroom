#!/usr/bin/bash

name=$(echo $1 | cut -d '.' -f 1)
echo $name

rgbasm -o $name.o $name.asm && rgblink -o $name.gb $name.o && rgbfix -v -p 0xFF $name.gb && gbt_bgb $name.gb
