This repository is built as part of my journey to improve Raspberry Pi4 used as Digital Streamer using USB output.

HW Supported:
- RPi4 and RPi3
- Standard Async USB2.0 Audio
- Onboard ethernet

Software:
- [Raspbian 11 64bit](https://www.raspberrypi.com/news/raspberry-pi-os-64-bit/)
    - stripped all running services
    - custom [RT patched](https://mirrors.edge.kernel.org/pub/linux/kernel/projects/rt/) kernel
    - runtime kernel config optimizations (sysctl)
- [RoonBridge](https://roonlabs.com/downloads)
    - autostarted
    - - systemctl stop mpd ; systemctl start roonbridge
- [MPD](https://github.com/MusicPlayerDaemon/MPD)
    - systemctl stop roonbridge ; systemctl start mpd
- Static IP configuration
    - /etc/network/interfaces.d/eth0
    - /etc/resolv.conf
- babysit service
    - monitors and sets right affinity and priority for MPD and RoonBridge RAAT RealTime processes
- OpenSSH server

Contents:
- jitter and latency optimized Linux RT kernel configuration for Raspberry Pi4
- scripts setting priorities and CPU affinities to further improve jitter
- scripts for reviewing current affinity and priority for RT or all processes

What is running in OS after boot:

    pi@rpi4strm:~ $ pstree
    systemd─┬─babysit.sh
            ├─sshd
            └─start.sh───mono-sgen─┬─mono-sgen───12*[{mono-sgen}]
                                   ├─mono-sgen───8*[{mono-sgen}]
                                   ├─processreaper
                                   └─4*[{mono-sgen}]

Measured Results:

     # rpi-usb-audio-tweaks 
    During Roon payback (16@44):
    root@rpi4strm:/home/pi# jitterdebugger -a 0-3 -v
    affinity: 0-3 = 4 [0xF]
    T: 0 ( 1599) A: 0 C:    593447 Min:         2 Avg:    2.97 Max:        59
    T: 1 ( 1600) A: 1 C:    593440 Min:         1 Avg:    2.08 Max:        26
    T: 2 ( 1601) A: 2 C:    593432 Min:         1 Avg:    2.07 Max:        49
    T: 3 ( 1602) A: 3 C:    593425 Min:         1 Avg:    2.07 Max:        20

for comarison, jitterdebugger examples from other distros:

    # VitOS:
    affinity: 0-3 = 4 [0xF]
    T: 0 ( 7513) A: 0 C:     83470 Min:         7 Avg:   17.58 Max:        45
    T: 1 ( 7514) A: 1 C:     83450 Min:         5 Avg:   17.28 Max:        38
    T: 2 ( 7515) A: 2 C:     83434 Min:         5 Avg:   17.06 Max:        49
    T: 3 ( 7516) A: 3 C:     83418 Min:         6 Avg:   17.21 Max:        48
    
    # Moode:
    affinity: 0-3 = 4 [0xF]
    T: 0 ( 1879) A: 0 C:     82959 Min:         7 Avg:   11.88 Max:       103
    T: 1 ( 1880) A: 1 C:     82933 Min:         7 Avg:   11.53 Max:        67
    T: 2 ( 1881) A: 2 C:     82907 Min:         6 Avg:   11.47 Max:        54
    T: 3 ( 1882) A: 3 C:     82891 Min:         7 Avg:   11.57 Max:        57

    # Raspbian11 64bit , only few services running:
    affinity: 0-3 = 4 [0xF]
    T: 0 (  705) A: 0 C:     94692 Min:         6 Avg:   20.17 Max:        97
    T: 1 (  706) A: 1 C:     94664 Min:         6 Avg:   19.97 Max:        43
    T: 2 (  707) A: 2 C:     94636 Min:         5 Avg:   20.16 Max:        44
    T: 3 (  708) A: 3 C:     94620 Min:         6 Avg:   21.25 Max:        71

Detailed per-cpu core viee of jitter performance:
![jitterplot-output](https://github.com/maniac0r/rpi-usb-audio-tweaks/blob/main/images/jitterplot-outputs.png?raw=true)
