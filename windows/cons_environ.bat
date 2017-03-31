@echo off
rem script for setting up common variables in Windows.
rem call this script in AUTOEXEC.bat and set the environment
rem up every time system boots.

setlocal EnableDelayedExpansion

rem programs that are not installed under %PROGRAMFILES% are thought 
rem to be placed under %BASE_DIR%
set BASE_DIR=D:\yousongzbin

rem GnuWin32
:: set_gnuwin32.bat relies on this variable.
set GNUWIN32=D:\GetGnuWin32\gnuwin32
call %GNUWIN32%\bin\set_gnuwin32.bat /l EN

rem Putty
set PATH=%PROGRAMFILES%\PuTTY;!PATH!

rem Git
rem set PATH=%BASE_DIR%\Git\bin;!PATH!

rem Subversion
set PATH=%BASE_DIR%\svn-win32-1.6.13\bin;!PATH!

rem Mercurial
set PATH=%BASE_DIR%\Mercurial;!PATH!

rem GnuPG, must come before Git
set PATH=%PROGRAMFILES%\GNU\GnuPG;!PATH!

rem php
set PATH=%BASE_DIR%\php;!PATH!

rem moinmoin
set PATH=%BASE_DIR%\moin-1.9.3;!PATH!

set PATHEXT=.PY;.PYW;!PATHEXT!
rem python 2.6
rem set PY26_HOME=%PROGRAMFILES%\Python26
rem set PY26_SCRIPTS=!PY26_HOME!\Scripts
rem set PY26_SITE_PK=!PY26_HOME!\Lib\site-packages
rem set PATH=%PY26_HOME%;%PY26_SCRIPTS%;!PATH!
rem set PATHEXT=.PY;.PYW;!PATHEXT!
rem for tools like easy_install
rem set HTTP_PROXY=http://127.0.0.1:8081
rem
rem python 2.7
set PY27_HOME=%SYSTEMDRIVE%\Python27
set PY26_SCRIPTS=!PY27_HOME!\Scripts
set PY26_SITE_PK=!PY27_HOME!\Lib\site-packages
set PATH=%PY27_HOME%;%PY26_SCRIPTS%;!PATH!

rem python 3.2
set PY32_HOME=%SYSTEMDRIVE%\Python32
set PY32_SCRIPTS=!PY32_HOME!\Scripts
set PY32_SITE_PK=!PY32_HOME!\Lib\site-packages
set PATH=%PY32_HOME%;%PY32_SCRIPTS%;!PATH!

rem PyQt4
rem set PYTHONPATH=!PY26_SITE_PK!\PyQt4\bin;!PYTHONPATH!
rem PyQt4.phonon.Phonon
rem set PYTHONPATH=!PY26_SITE_PK!\PyQt4\plugins\phonon_backend;!PYTHONPATH!

rem google_appengine
set GAE_PATH=%PROGRAMFILES%\Google\google_appengine
set PATH=%GAE_PATH%;!PATH!

rem gsutil
rem SET HOME=%BASE_DIR%\gsutil
rem SET PATH=%HOME%;%PATH%
rem SET PYTHONPATH=%HOME%\boto;%PYTHONPATH%

rem java
rem plz take care of the edition number in the path string
set JAVA_HOME=%PROGRAMFILES%\Java\jdk1.6.0_18
set JAVA_BIN=%JAVA_HOME%\bin
set CLASSPATH=.\;%JAVA_HOME%\lib\tools.jar
set PATH=%JAVA_BIN%;!PATH!

rem ant
set ANT_HOME=%BASE_DIR%\apache-ant-1.8.1
set ANT_BIN=%ANT_HOME%\bin;%ANT_HOME%\lib
set PATH=%ANT_BIN%;!PATH!

rem android sdk
set ANDROID_SDK_TOOLS=%BASE_DIR%\android-sdk-windows\tools
set PATH=%ANDROID_SDK_TOOLS%;!PATH!

rem Microsoft Visual Studio 2010 x86 tool
rem if exist "%PROGRAMFILES%\Microsoft SDKs\Windows\v7.1\Bin\SetEnv.cmd" (
rem     call "%PROGRAMFILES%\Microsoft SDKs\Windows\v7.1\Bin\SetEnv.cmd" 1>nul 2>nul
rem )

rem TexLive
set TEXDIR=%BASE_DIR%\texlive\2011
set PATH=%TEXDIR%\bin\win32\;!PATH!
set TEXMFMAIN=%TEXDIR%\texmf\
set TEXMFDIST=%TEXDIR%\texmf-dist\
set TEXMFVAR=%TEXDIR%\texmf-var\
set TEXMFCONFIG=%TEXDIR%\texmf-config\
set TEXMFLOCAL=%TEXDIR%\..\texmf-local\

rem phantomjs
set PATH=%BASE_DIR%\phantomjs-1.2.0-win32-dynamic;!PATH!

rem emacs
set PATH=%BASE_DIR%\emacs-22.3\bin;!PATH!

rem DjVuLibre
set PATH=%PROGRAMFILES%\DjVuZone\DjVuLibre;!PATH!

rem NodeJS
set PATH=%PROGRAMFILES%\nodejs;!PATH!

rem FFmpeg
set PATH=%BASE_DIR%\ffmpeg\bin;!PATH!

rem Flex SDK
set PATH=%BASE_DIR%\flex_sdk_4.6\bin;!PATH!

rem MinGW
set PATH=%BASE_DIR%\mingw\msys\1.0\bin;!PATH!
set PATH=%BASE_DIR%\mingw\bin;!PATH!
call "C:\Program Files\Microsoft Visual Studio 10.0\VC\vcvarsall.bat" x86

rem working directory
set WD=D:\wksps
cd /d %WD%
%ComSpec%

