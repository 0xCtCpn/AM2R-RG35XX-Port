@echo off
REM Build AM2R (Butterscotch, WAD14) for MiaUI RG35XX - requires Docker Desktop
REM Toolchain: glibc armhf cross (MiaUI SYSTEM is glibc 2.37, INTERP
REM /lib/ld-linux-armhf.so.3 - NO musl /tmp loader staging like Garlic).
docker build --load -t am2r-miaui .
if errorlevel 1 (
  echo Build failed - check docker log above
  exit /b 1
)
if not exist out mkdir out
docker run --rm -v "%cd%/out:/out" am2r-miaui
echo.
echo === Built ===
dir out
echo.
echo Install (MiaUI EXT4, no FAT32):
echo 1. Copy out\butterscotch + libSDL-1.2* + gamecontrollerdb.txt to ROMs/Ports/AM2R.pak/
echo    Copy launch.sh there as launch.sh
echo 2. Copy your AM2R 1.1 (Windows) files (AM2R.exe, data.win) into the same folder
echo 3. Reboot, PORTS -^> AM2R
echo 4. Debug: read ROMs/Ports/AM2R.pak/debug.log
