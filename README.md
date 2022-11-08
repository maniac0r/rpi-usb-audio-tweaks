     # rpi-usb-audio-tweaks 
    During Roon payback (16@44):
    root@rpi4strm:/home/pi# jitterdebugger -a 0-3 -v
    affinity: 0-3 = 4 [0xF]
    T: 0 ( 1599) A: 0 C:    593447 Min:         2 Avg:    2.97 Max:        59
    T: 1 ( 1600) A: 1 C:    593440 Min:         1 Avg:    2.08 Max:        26
    T: 2 ( 1601) A: 2 C:    593432 Min:         1 Avg:    2.07 Max:        49
    T: 3 ( 1602) A: 3 C:    593425 Min:         1 Avg:    2.07 Max:        20
    ^C
    

for comarison, jitterdebugger examples from other distros:

    VitOS:
    affinity: 0-3 = 4 [0xF]
    T: 0 ( 7513) A: 0 C:     83470 Min:         7 Avg:   17.58 Max:        45
    T: 1 ( 7514) A: 1 C:     83450 Min:         5 Avg:   17.28 Max:        38
    T: 2 ( 7515) A: 2 C:     83434 Min:         5 Avg:   17.06 Max:        49
    T: 3 ( 7516) A: 3 C:     83418 Min:         6 Avg:   17.21 Max:        48
    
    Moode:
    affinity: 0-3 = 4 [0xF]
    T: 0 ( 1879) A: 0 C:     82959 Min:         7 Avg:   11.88 Max:       103
    T: 1 ( 1880) A: 1 C:     82933 Min:         7 Avg:   11.53 Max:        67
    T: 2 ( 1881) A: 2 C:     82907 Min:         6 Avg:   11.47 Max:        54
    T: 3 ( 1882) A: 3 C:     82891 Min:         7 Avg:   11.57 Max:        57
    
