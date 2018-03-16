# AutoMine
Web based Ethereum miner built on top of Debian. The web-based part is still in-work, but all the command line stuff works now. This will configure a machine with base Debian 9.4 installed to a mining system with no GUI and with only the minimal software required.

This guide assumes you start with a base minimal Debian 9.4 install with only SSH server.

# Post-Install Configuration
On first boot, grub may try to boot from from the wrong device and load the nouveau nVidia driver. 

The nouveau nVidia driver causes the machine to hang on boot and prevents the nVidia driver from being loaded so it needs to be blacklisted. Edit the kernel line and append this from the grub boot menu to fix this:
```
modprobe.blacklist=nouveau
```
Once the machine is booted, update grub to fix the wrong boot device issue.
```
sudo update-grub
sudo grub-install
```
Alternatively, you can see if there are any kernel updates and apply them; this will reload and reinstall grub with correct settings and set the correct boot device.
```
sudo apt update
sudo apt upgrade
```

# Install nVidia Binary Driver and Kernel Module
Blacklist the nouveau driver:
```
sudo nano /etc/modprobe.d/blacklist.conf
```
```
blacklist nouveau
```

Install software and libraries required to install the nVidia driver:
```
sudo apt install -y sudo build-essential vim libcurl4-openssl-dev inotify-tools dkms xserver-xorg xserver-xorg-core xserver-xorg-input-evdev xserver-xorg-video-dummy x11-xserver-utils xdm libgtk-3-0 linux-headers-$(uname -r) 
```
Download the nVidia driver:
http://www.nvidia.com/download/driverResults.aspx/131853/en-us

Install the nVidia driver. Accept the license agreement, then select "Yes" when prompted to register the kernel module with DKMS. nVidia will complain about missing 32-bit libraries. Don't install them, just acknowledge them and continue. The package will then build and install the nVidia kernel module, and then prompt to run nvidia-xconfig. Select "Yes" to continue. 

# Setup Dummy X Server and XDM Session
Setup shell variables for X:
```
sudo nano /etc/X11/xdm/Xsetup
```

Paste the following and save
```
export PATH=/bin:/usr/bin:/sbin
export HOME=/root
export DISPLAY=:0
xset -dpms
xset s off
xhost +
chvt 1
```

Setup shell variables for the user:
```
echo 'export DISPLAY=:0' >> ~/.bashrc
```

Tell nVidia to setup dummy displays attached to all video cards:
```
sudo nvidia-xconfig -a --allow-empty-initial-configuration --cool-bits=28 --use-display-device="DFP-0" --connected-monitor="DFP-0"
```

# Setup Overclocking Scripts For Mining
Create the script that performs the overclocks on the video cards:
 sudo vim /usr/local/src/gpu-oc.bin/gpu-oc.sh

Paste script and save the file:
 #!/usr/bin/env bash
 
 #First check and see if the script is running as root
 if [$EUID -ne 0 ]([)]; then
         echo "This script must be run as root"
         exit 1
 fi
 
 #Make sure XDM has started
 xSocket=/tmp/.X11-unix/X0
 
 while [! -S "$xSocket" ]()
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
         /usr/bin/nvidia-settings -a [         #Set manual fan control on the GPU
         /usr/bin/nvidia-settings -a [gpu:$i](gpu:$i]/GPUPowerMizerMode=1)/GPUFanControlState=1
         #Set target fan speed on the GPU
         /usr/bin/nvidia-settings -a [         #Set power level on the GPU
         /usr/bin/nvidia-smi -i $i -pl 110
         #Set GPU overclock on the GPU
         /usr/bin/nvidia-settings -a "[gpu:$i](fan:$i]/GPUTargetFanSpeed=55)/GPUMemoryTransferRateOffset[ done

Create the script that unsets the overclocks on the video cards:
 sudo vim /usr/local/src/gpu-oc.bin/gpu-nooc.sh

Paste script and save the file:
 #!/usr/bin/env bash
 
 #First check and see if the script is running as root
 if [[ $EUID -ne 0 ](3]=+1500")]; then
         echo "This script must be run as root"
         exit 1
 fi
 
 #Make sure XDM has started
 xSocket=/tmp/.X11-unix/X0
 
 while [! -S "$xSocket" ]()
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
         /usr/bin/nvidia-settings -a [         #Set automatic fan control on the GPU
         /usr/bin/nvidia-settings -a [gpu:$i](gpu:$i]/GPUPowerMizerMode=1)/GPUFanControlState=0
         #Set power level on the GPU back tp stock
         /usr/bin/nvidia-smi -i $i -pl 151
         #Set GPU overclock on the GPU back to stpck
         /usr/bin/nvidia-settings -a "[ done

Create the systemd unit file that controls overclcoks:
 sudo vim /etc/systemd/system/gpu-oc.service

Paste and save the unit file
 [Unit](gpu:$i]/GPUMemoryTransferRateOffset[3]=0")
 Description=GPU Overclocking Script
 Documentation=https://wiki.andrewpeng.net/index.php/Gp-gpu
 After=xdm.service
 
 [ Type=oneshot
 Environment="DISPLAY=:0"
 ExecStart=/usr/local/src/gpu-oc.bin/gpu-oc.sh
 ExecStop=/usr/local/src/gpu-oc.bin/gpu-nooc.sh
 User=root
 Group=root
 RemainAfterExit=yes
 
 [Install](Service])
 WantedBy=claymore.service

# Setup Claymore Miner and Startup Script
Download the latest Claymore miner from this page into ''/usr/local/src/claymore.bin''
 https://bitcointalk.org/index.php?topic=1433925.0

Setup ''/usr/local/src/claymore.bin/config.txt'' with miner settings and save the file:
 -mode 1
 -epool us1.ethermine.org:4444
 -ewal 0xAE81983ca15296B5F11f64Ae572De521f8DB8080.gpgpu01
 -epsw x
 -dbg -1
 --mport 0
 -tt 0

Change the owner of the claymore binary directory to the user ''daemon''
 sudo chown -r daemon. /usr/local/src/claymore.bin

Enable execution of the claymore binary
 sudo chmod 0755 /usr/local/src/claymore/ethdcrminer64

Setup the claymore systemd unit file
 sudo vim /etc/systemed/system/claymore.service

Paste and save the claymore systemd unit file
 [ Description=Claymore GPU Ethereum miner
 Documentation=https://bitcointalk.org/index.php?topic=1433925.0
 After=network.target xdm.service
 
 [Service](Unit])
 User=daemon
 Group=daemon
 Type=simple
 Environment=DISPLAY=:0
 ExecStart=/usr/local/src/claymore.bin/ethdcrminer64
 Restart=always
 
 [ WantedBy=multi-user.target

# Setup systemd Scripts
Reload the systemd manager configuration
 sudo systemctl daemon-reload

Enable the overclocking service:
 sudo systemctl enable gpu-oc

Enable the claymore service:
 sudo systemctl enable claymore

# Final Reboot
Reboot to make sure all changes stuck:
 sudo reboot

Ensure overclocks and Ethereum miner are running:
 sudo tail -f /var/log/daemon.log

# References
Setup dummy displays on all detected GPUs
 sudo nvidia-xconfig -a --allow-empty-initial-configuration --cool-bits=28 --use-display-device="DFP-0" --connected-monitor="DFP-0"

Set persistence mode (clocks stay applied until reboot)
 sudo nvidia-smi -pm 1

Set power mode on GPU:
 sudo nvidia-settings -a [gpu:0](Install])/GPUPowerMizerMode=1

Enable manual fan control on cards
 sudo nvidia-settings -a [
Set target fan speed on cards to 75%
 sudo nvidia-settings -a [fan:0](gpu:0]/GPUFanControlState=1)/GPUTargetFanSpeed=75

Set power level on cards to 110 watts
 sudo nvidia-smi -i 0 -pl 110

Set a +750MHz clock offset on memory bus on cards:
 sudo nvidia-settings -a "[
# Todo
* Figure out why GPU overclocking service keeps trying to run before X is ready
* Figure out why xdm hangs on shutdown:
 strace: Process 686 attached
 rt_sigsuspend([](gpu:0]/GPUMemoryTransferRateOffset[3]=+1500"), 8)                    = ? ERESTARTNOHAND (To be restarted if no handler)
 --- SIGTERM {si_signo=SIGTERM, si_code=SI_USER, si_pid=1, si_uid=0} ---
 --- SIGCHLD {si_signo=SIGCHLD, si_code=CLD_KILLED, si_pid=704, si_uid=0, si_status=SIGTERM, si_utime=0, si_stime=0} ---
 --- SIGCONT {si_signo=SIGCONT, si_code=SI_USER, si_pid=1, si_uid=0} ---
 rt_sigreturn({mask=[            = 0
 getpid()                                = 686
 stat("/etc/localtime", {st_mode=S_IFREG|0644, st_size=3585, ...}) = 0
 getpid()                                = 686
 write(2, "Fri Feb 23 12:35:18 2018 xdm info (pid 686): ", 45) = 45
 write(2, "Shutting down\n", 14)         = 14
 kill(704, SIGTERM)                      = 0
 kill(704, SIGCONT)                      = 0
 kill(690, SIGTERM)                      = 0
 kill(690, SIGCONT)                      = 0
 rt_sigreturn({mask=[HUP CHLD](TERM]}))})         = -1 EINTR (Interrupted system call)
 rt_sigprocmask(SIG_SETMASK, [NULL, 8) = 0
 wait4(-1, [{WIFSIGNALED(s) && WTERMSIG(s) == SIGTERM}](],), WNOHANG, NULL) = 704
 stat("/etc/X11/xdm/xdm-config", {st_mode=S_IFREG|0644, st_size=1113, ...}) = 0
 stat("/etc/X11/xdm/Xservers", {st_mode=S_IFREG|0644, st_size=1687, ...}) = 0
 stat("/etc/X11/xdm/Xaccess", {st_mode=S_IFREG|0644, st_size=3401, ...}) = 0
 stat("/etc/localtime", {st_mode=S_IFREG|0644, st_size=3585, ...}) = 0
 getpid()                                = 686
 write(2, "Fri Feb 23 12:35:18 2018 xdm info (pid 686): ", 45) = 45
 write(2, "display :0 is being disabled\n", 29) = 29
 kill(690, SIGTERM)                      = 0
 kill(690, SIGCONT)                      = 0
 wait4(-1, 0x7ffc222db8c4, WNOHANG, NULL) = 0
 rt_sigprocmask(SIG_BLOCK, [CHLD](HUP), [8) = 0
 rt_sigsuspend([](],), 8)                    = ?
 +++ killed by SIGKILL +++
