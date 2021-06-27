# nVidia GP-GPU Configuration
This is a repository of scripts and documenetation that sets up an nVidia based GP-GPU server with overclocking with a minimal Debian 9.4 install. No extra bits are installed, and we maintain a clean text console on the physical console for the server. The entire footprint is small enough to rapidly boot over PXE with iSCSI or NFS filesystem.

This requires installing a dummy X interface because the tools used to control overclocking on consumer-grade nVidia graphics cards (as opposed to Quadro, Tesla, or Grid cards) needs to be attached to an X display to work.

This configuration will be useful for HashCat, crypto-currency mining, neural networks, video processing, or any other task that uses GPUs and benefits from overclocking.

This guide assumes you start with a base minimal Debian 9.4 install with only SSH server installed.

# Post-Install Configuration
There's a bug in Debian where on first boot, grub may try to boot from from the wrong device causing grub to bomb out and hang.

Additionally, the default Debian install loads the nouveau nVidia module which has a bug that causes the system to hang at random intervals making the system impossible to use. 

During the first boot after install, you need to edit the boot config at the grub menu before Debian loads. Edit the boot device to be the correct boot device (usually /dev/sda1) and blacklist the nouveau module by appending the following to the kernel line. 
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
Blacklist the nouveau driverby creating a blacklist file:
```
sudo nano /etc/modprobe.d/blacklist.conf
```
Add the following line to blacklist the nouveau module
```
blacklist nouveau
```
Install software and libraries required to install the nVidia driver:
```
sudo apt install -y sudo build-essential vim libcurl4-openssl-dev inotify-tools dkms xserver-xorg xserver-xorg-core xserver-xorg-input-evdev xserver-xorg-video-dummy x11-xserver-utils xdm libgtk-3-0 linux-headers-$(uname -r) 
```
Download the nVidia driver using wget from nVidia:
http://www.nvidia.com/download/driverResults.aspx/131853/en-us

Install the nVidia driver. Accept the license agreement, then select "Yes" when prompted to register the kernel module with DKMS. nVidia will complain about missing 32-bit libraries. Don't install them, just acknowledge them and continue. The package will then build and install the nVidia kernel module, and then prompt to run nvidia-xconfig. Select "Yes" to continue. 

# Setup Dummy X Server and XDM Session
Setup shell variables for X:
```
sudo nano /etc/X11/xdm/Xsetup
```
Paste the following and save. This sets the paths for the binaries, disables DPMS and X authentication, and changes the console back to virtual terminal #1 (text console)
```
export PATH=/bin:/usr/bin:/sbin
export HOME=/root
export DISPLAY=:0
xset -dpms
xset s off
xhost +
chvt 1
```
Setup shell variables for the current user:
```
echo 'export DISPLAY=:0' >> ~/.bashrc
```
Tell nVidia to setup dummy displays attached to all video cards. If you change your video card configuration, this will need to be run again. 
```
sudo nvidia-xconfig -a --allow-empty-initial-configuration --cool-bits=28 --use-display-device="DFP-0" --connected-monitor="DFP-0"
```
# Setup Overclocking Scripts
See /scripts/ for the scripts that controls overclocks. Install them to ```/usr/local/src/gp-gpu.sh/```
You will need to edit the settings in the script for your configuration. The settings are near the bottom

See /systemd/ for the systemd unit files that control overclocks. Install them to ```/etc/systemd/system/```

# Setup systemd Scripts
Reload the systemd manager configuration
```
sudo systemctl daemon-reload
```
Enable the overclocking service:
```
sudo systemctl enable gpu-oc
```
# Final Reboot
Reboot to make sure all changes stuck:
```
sudo reboot
```
On system boot, the overclocks in ```/usr/local/src/gp-gpu.sh/gpu-oc.sh``` will be applied. You can disable the overclocks by running
```
sudo systemctl gpu-oc stop
```
Or re-enable them
```
sudo systemctl gpu-oc start
```
# Reference
Setup dummy displays on all detected GPUs
```
sudo nvidia-xconfig -a --allow-empty-initial-configuration --cool-bits=28 --use-display-device="DFP-0" --connected-monitor="DFP-0"
```
Set persistence mode (clocks stay applied until reboot)
```
sudo nvidia-smi -pm 1
```
Set power mode on GPU0
```
sudo nvidia-settings -a [gpu:0](Install])/GPUPowerMizerMode=1
```
Enable manual fan control on GPU0
```
sudo nvidia-settings -a [gpu:0]/GPUFanControlState=1
```
Set target fan speed on GPU0 to 75%
```
sudo nvidia-settings -a [fan:0](gpu:0]/GPUFanControlState=1)/GPUTargetFanSpeed=75
```
Set power level on GPU0 to 110 watts
```
sudo nvidia-smi -i 0 -pl 110
```
Set a +750MHz clock offset on memory bus on GPU0:
```
sudo nvidia-settings -a "[gpu:0]/GPUMemoryTransferRateOffset[3]=+1500"
```

# Todo
* Figure out why xdm hangs on shutdown:
```
strace: Process 686 attached
rt_sigsuspend([], 8)                    = ? ERESTARTNOHAND (To be restarted if no handler)
--- SIGTERM {si_signo=SIGTERM, si_code=SI_USER, si_pid=1, si_uid=0} ---
--- SIGCHLD {si_signo=SIGCHLD, si_code=CLD_KILLED, si_pid=704, si_uid=0, si_status=SIGTERM, si_utime=0, si_stime=0} ---
--- SIGCONT {si_signo=SIGCONT, si_code=SI_USER, si_pid=1, si_uid=0} ---
rt_sigreturn({mask=[TERM]})             = 0
getpid()                                = 686
stat("/etc/localtime", {st_mode=S_IFREG|0644, st_size=3585, ...}) = 0
getpid()                                = 686
write(2, "Fri Feb 23 12:35:18 2018 xdm info (pid 686): ", 45) = 45
write(2, "Shutting down\n", 14)         = 14
kill(704, SIGTERM)                      = 0
kill(704, SIGCONT)                      = 0
kill(690, SIGTERM)                      = 0
kill(690, SIGCONT)                      = 0
rt_sigreturn({mask=[HUP CHLD]})         = -1 EINTR (Interrupted system call)
rt_sigprocmask(SIG_SETMASK, [], NULL, 8) = 0
wait4(-1, [{WIFSIGNALED(s) && WTERMSIG(s) == SIGTERM}], WNOHANG, NULL) = 704
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
rt_sigprocmask(SIG_BLOCK, [HUP CHLD], [], 8) = 0
rt_sigsuspend([], 8)                    = ?
+++ killed by SIGKILL +++
```

***

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program. If not, see http://www.gnu.org/licenses/.
