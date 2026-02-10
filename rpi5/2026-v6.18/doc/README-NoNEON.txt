To disable NEON/SIMD instructions,  besides NoNEON kerel it is also required:

1. add line   Environment=GLIBC_TUNABLES=glibc.cpu.hwcaps=-simd,-asimd   into roonbridge systemd service

2. add        GLIBC_TUNABLES=glibc.cpu.hwcaps=-simd,-asimd               at the end of cmdline.txt

reboot

