#!/usr/bin/env bash

#First check and see if the script is running as root
if  $EUID -ne 0 ; then
        echo "This script must be run as root"
        exit 1
fi

#Make sure XDM has started
xSocket=/tmp/.X11-unix/X0

while [ ! -S "$xSocket" ]
do
        sleep 5
        inotifywait -qqt 1 -e create -e moved_to "$(dirname $xSocket)"
done

#Set variables for X display and number of cards detected int he system
DISPLAY=:0
numCards="$(expr $(lspci | grep NVIDIA | grep VGA | wc -l) - 1)"

#Set Persistencec mode on the cards so they stay applied until reboot
/usr/bin/nvidia-smi -pm 1

#Loop through the cards and set settings
for ((i=0; i<=$numCards; ++i))
do
        #Set power mode on the GPU
        /usr/bin/nvidia-settings -a [gpu:$i]/GPUPowerMizerMode=1
        #Set automatic fan control on the GPU
        /usr/bin/nvidia-settings -a [gpu:$i]/GPUFanControlState=0
        #Set power level on the GPU back tp stock
        /usr/bin/nvidia-smi -i $i -pl 151
        #Set GPU overclock on the GPU back to stpck
        /usr/bin/nvidia-settings -a "[gpu:$i]/GPUMemoryTransferRateOffset[3]=0"
done
