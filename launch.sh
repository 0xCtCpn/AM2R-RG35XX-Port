#!/bin/sh
# MiaUI pak launcher - install to /userdata/Ports/AM2R.pak/launch.sh
# MiaUI ROMs is EXT4 only (no FAT32), SD preserved read-only OS in /opt.
progdir=$(dirname "$0")
cd $progdir
HOME=$progdir
# Never ship a bundled libasound.so* (see the Dockerfile CMD comment); if a
# stale copy is present (bad manual install), move it aside so it can never
# shadow the system lib via LD_LIBRARY_PATH.
if [ -e ./libasound.so ] || [ -e ./libasound.so.2 ] || [ -e ./libasound.so.2.0.0 ]; then
  mkdir -p ./libasound-disabled
  mv -f ./libasound.so ./libasound.so.2 ./libasound.so.2.0.0 ./libasound-disabled/ 2>/dev/null
fi
# butterscotch is glibc, so SDL1's libasound dependency must resolve to the
# SYSTEM /usr/lib/libasound.so.2 (alsa-lib 1.2.10 + /etc/asound.conf - the
# only stack that works with MiaUI's card). $PWD stays on LD_LIBRARY_PATH
# only for libSDL-1.2.so.0 to be found.
export LD_LIBRARY_PATH="$PWD:$LD_LIBRARY_PATH"
unset ALSA_CONFIG_PATH
unset ALSA_CONFIG_DIR
export SDL_VIDEODRIVER=fbcon
export SDL_FBDEV=/dev/fb0
export SDL_NOMOUSE=1
export SDL_AUDIODRIVER=alsa
# 'overclock.elf' only raises scaling_max_freq; governor stays 'userspace'
# pinned at CPU_SPEED_MENU (504 MHz), so gameplay initially ran at menu clock.
# Raise the ceiling to CPU_SPEED_PERF (1488000) and pin all cores there with
# the performance governor. AM2R is heavier than Undertale (more instances
# per room) - full clock is not optional here.
overclock.elf $CPU_SPEED_PERF 2>/dev/null
for i in 0 1 2 3; do
  echo performance > /sys/devices/system/cpu/cpu$i/cpufreq/scaling_governor 2>/dev/null
done
restore_cpu() {
  for i in 0 1 2 3; do
    echo userspace > /sys/devices/system/cpu/cpu$i/cpufreq/scaling_governor 2>/dev/null
    echo 504000 > /sys/devices/system/cpu/cpu$i/cpufreq/scaling_setspeed 2>/dev/null
  done
}
trap restore_cpu EXIT
sleep 1
{
  echo "=== AM2R MiaUI launch (SW, SDL1.2 fbcon) ==="
  cat /proc/fb
  ls -lh /dev/fb* /dev/dri/* 2>&1
  ls /dev/input/event* 2>&1
  ls -R /dev/snd 2>&1 | head -20
  cat /proc/meminfo 2>&1 | head -5
  ls -lh ./butterscotch ./lib*.so* ./data.win 2>&1
} > ./debug.log 2>&1
if [ ! -f "./data.win" ]; then
  echo "missing data.win - copy your AM2R 1.1 (Windows) files here (AM2R.exe, data.win)" >> ./debug.log
  sleep 3
  exit 1
fi
# --lazy-rooms/--lazy-textures/--lazy-audio/--load-type load-per-chunk are
# ESSENTIAL: AM2R 1.1's data.win is several times Undertale's and the device
# has 256 MB RAM. Full-clock performance governor pinned above.
./butterscotch --renderer software --lazy-rooms --lazy-textures --lazy-audio --load-type load-per-chunk ./data.win >> ./debug.log 2>&1
RET=$?
echo "exit code $RET" >> ./debug.log
exit $RET
