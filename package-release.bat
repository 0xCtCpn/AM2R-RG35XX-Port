@echo off
REM Package clean AM2R MiaUI release zip - game-free (no data.win/AM2R files).
REM Ships NO libasound and NO share\alsa (Undertale v1.0.0 lesson: a bundled
REM alsa-lib 1.2.12 shadows the SYSTEM libasound 1.2.10 via LD_LIBRARY_PATH
REM and kills audio; butterscotch is glibc and must use the system lib).
REM Output: out\AM2R_MiaUI-release-v1.0.zip with AM2R.pak\ layout.
setlocal
set D=%~dp0
set OUT=%~dp0out
set PAK=%OUT%\AM2R.pak
if not exist "%D%out\butterscotch" (
  echo Missing out\butterscotch - run build.bat first
  exit /b 1
)
mkdir "%PAK%" 2>nul
del /Q "%PAK%\*" 2>nul
rmdir /S /Q "%PAK%\share" 2>nul
copy /Y "%D%launch.sh" "%PAK%\launch.sh" >nul
copy /Y "%D%out\butterscotch" "%PAK%\butterscotch" >nul
copy /Y "%D%out\libSDL-1.2.so.0" "%PAK%\" >nul
copy /Y "%D%out\libSDL-1.2.so.0.11.4" "%PAK%\" >nul
copy /Y "%D%out\gamecontrollerdb.txt" "%PAK%\" >nul
copy /Y "%D%LICENSE" "%PAK%\LICENSE" >nul
copy /Y "%D%NOTICE.MiaUI" "%PAK%\NOTICE.MiaUI" >nul
copy /Y "%D%README.md" "%PAK%\README.md" >nul
echo === Staged pak (must NOT contain libasound or game data) ===
dir "%PAK%"
where powershell >nul 2>&1
REM NOTE: -Include only filters with -Path wildcards (dir\*), NOT -LiteralPath.
REM A match exits 1 so errorlevel below actually fails the packaging.
powershell -NoProfile -Command "$bad = @(Get-ChildItem -Path '%PAK%\*' -Recurse -Include 'libasound*','data.win','AM2R.exe','*.ini','*.unx','*.sav','*.ogg','*.wav','*.mp3'); if ($bad.Count -gt 0) { $bad | ForEach-Object { Write-Host ('LEAK: ' + $_.FullName) }; exit 1 }; if (Test-Path -LiteralPath '%PAK%\share') { Write-Host 'LEAK: bundled share\alsa in pak'; exit 1 }; Compress-Archive -Path '%PAK%' -DestinationPath '%OUT%\AM2R_MiaUI-release-v1.0.zip' -Force; Get-ChildItem '%OUT%\AM2R_MiaUI-release-v1.0.zip'"
if errorlevel 1 (
  echo Package failed
  exit /b 1
)
echo.
echo Done: out\AM2R_MiaUI-release-v1.0.zip (game-free, no bundled libasound)
echo Install: extract so the pak ends up at /userdata/Ports/AM2R.pak/ + your AM2R 1.1 files
endlocal
