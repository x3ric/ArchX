#!/bin/bash
if [[ ! -z $PWD/archiso_releng ]]; then
    sudo rm -rf $PWD/archiso_releng
fi
if ! pacman -Qi archiso &> /dev/null; then
    sudo pacman -Sy archiso
fi
sudo cp -rf /usr/share/archiso/configs/releng $PWD/archiso_releng
sudo cp -rf $PWD/patch/* $PWD/archiso_releng
cd $PWD/archiso_releng && sudo mkarchiso -v .
