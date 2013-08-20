#!/bin/bash

#This code runs ffmpeg compression on movie files

for ((loc=1; loc<=$1 ; loc++))
do
   ffmpeg -i ./temp_$loc.avi -sameq -y ./mov_$loc.avi
done
rm ./temp*
