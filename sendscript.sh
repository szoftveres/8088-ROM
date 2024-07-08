#!/bin/bash


if test ! -e lastseg ; then
    echo -n "4000" >> lastseg
fi

lastseg=`cat lastseg`
newseg=`expr $lastseg + 1000`
if test $newseg -gt 7000  ; then
   newseg=4000
fi
echo $newseg > lastseg

echo
echo "ES : ${newseg}"

# Get back to te main menu
echo "x" >> /dev/ttyUSB0
sleep 1


echo -n "e" >> /dev/ttyUSB0
echo -n "${newseg}" >> /dev/ttyUSB0

echo -n "r" >> /dev/ttyUSB0
sleep 1
./sendp/sendp < ./rom.bin >> /dev/ttyUSB0
# cat ./rom.bin >> /dev/ttyUSB0
sleep 1
echo -n "g" >> /dev/ttyUSB0

# minicom


