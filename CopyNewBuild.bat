@echo off
rem запоминаем текущую дату:
set curdate=%date:~4,2%-%date:~7,2%-%date:~10,4%
echo Today is %curdate%. It's right?
set mainpath=%CD%
md "%CD%\Steam Update"
cd /d "%CD%\Steam Update"

:ch1
Set /p choice="Create new steam Unity Build?(y/n): "
if not defined choice goto ch1
if "%choice%"=="y" goto build
if "%choice%"=="n" goto ch2
goto ch1

:build
xcopy "%mainpath%\Unity Build" "%mainpath%\Steam Update" /s /d:%curdate%
goto ch2

:ch2
Set /p choice="Create archive for steam?(y/n): "
if not defined choice goto ch2
if "%choice%"=="y" goto arch
if "%choice%"=="n" goto end
goto ch2

:arch
tar.exe -a -c -f "%mainpath%\steam.zip" *.*
goto end	

:end
echo App is done!
pause