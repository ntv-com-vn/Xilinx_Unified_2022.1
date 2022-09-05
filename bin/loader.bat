@echo off
rem #
rem # COPYRIGHT NOTICE
rem # Copyright 1986-2016 Xilinx, Inc. All Rights Reserved.
rem #
set RDI_EXIT=

setlocal enableextensions enabledelayedexpansion

rem # RDI_ARGS_FUNCTION must be cleared here, otherwise child
rem # planAhead processes will inherit the parent's args.
set RDI_ARGS_FUNCTION=

if [%XIL_NO_OVERRIDE%] == [1] (
  set XIL_PA_NO_XILINX_OVERRIDE=1
  set XIL_PA_NO_XILINX_SDK_OVERRIDE=1
  set XIL_PA_NO_XILINX_PATH_OVERRIDE=1
)

if not defined _RDI_SETENV_RUN (
  call "%~dp0/setupEnv.bat"
)
if defined _RDI_SETENV_RUN (
  set _RDI_SETENV_RUN=
)

if defined RDI_EXIT (
  goto :EOF
)

if [%PROCESSOR_ARCHITECTURE%] == [x86] (
  if not defined PROCESSOR_ARCHITEW6432 (
    echo "Unsupported architecture." > NUL 2>&1
    exit /b 1
  )
) else (
  if not defined PROCESSOR_ARCHITECTURE (
    echo "Unsupported architecture." > NUL 2>&1
    exit /b 1
  )
)

set RDI_OPT_EXT=.o

rem #
rem # If True check for the existence of RDI_PROG prior to calling into
rem # rdiArgs.bat
rem #
set RDI_CHECK_PROG=True

if defined XILINX (
  if exist %SYSTEMROOT%\system32\findstr.exe (
    echo "%XILINX%" | %SYSTEMROOT%\system32\findstr.exe /C:";" > NUL 2>&1
    if [!ERRORLEVEL!] == [0] (
      if not [%XIL_SUPPRESS_OVERRIDE_WARNINGS%] == [1] (
        echo WARNING: %%XILINX%% contains multiple entries. Setting
        echo          %%XIL_PA_NO_XILINX_OVERRIDE%% to 1.
        echo.
      )
      set XIL_PA_NO_XILINX_OVERRIDE=1
    )
  )
)

if defined XILINX_SDK (
  if exist %SYSTEMROOT%\system32\findstr.exe (
    echo "%XILINX_SDK%" | %SYSTEMROOT%\system32\findstr.exe /C:";" > NUL 2>&1
    if [!ERRORLEVEL!] == [0] (
      if not [%XIL_SUPPRESS_OVERRIDE_WARNINGS%] == [1] (
        echo WARNING: %%XILINX_SDK%% contains multiple entries. Setting
        echo          %%XIL_PA_NO_XILINX_SDK_OVERRIDE%% to 1.
        echo.
      )
      set XIL_PA_NO_XILINX_SDK_OVERRIDE=1
    )
  )
)

if not [%XIL_SUPPRESS_OVERRIDE_WARNINGS%] == [1] (
  if [%XIL_PA_NO_XILINX_OVERRIDE%] == [1] (
    echo WARNING: %%XIL_PA_NO_XILINX_OVERRIDE%% is set to 1.
    echo          When %%XIL_PA_NO_XILINX_OVERRIDE%% is enabled
    echo          %%XILINX%%, %%MYXILINX%%, and %%PATH%% must be manually set.
  )

  if [%XIL_PA_NO_XILINX_SDK_OVERRIDE%] == [1] (
    echo WARNING: %%XIL_PA_NO_XILINX_SDK_OVERRIDE%% is set to 1.
    echo          When %%XIL_PA_NO_XILINX_SDK_OVERRIDE%% is enabled
    echo          %%XILINX_SDK%%, and %%PATH%% must be manually set.
  )
)

rem #
rem # Handle options. If this is a release build rdiArgs.bat will
rem # be mostly empty.
rem #
call "%RDI_BINROOT%/rdiArgs.bat" %*

rem #
rem # Enforce java execution if RDI_JAVALAUNCH is defined
rem #
if defined RDI_JAVALAUNCH (
  set RDI_CHECK_PROG=False
  set RDI_ARGS_FUNCTION=RDI_EXEC_JAVA
)

rem #
rem # Enforce vbs execution if RDI_VBSLAUNCH is defined
rem # RDI_VBSLAUNCH is the VBS launcher
rem #
if defined RDI_VBSLAUNCH (
  set RDI_CHECK_PROG=False
  set RDI_ARGS_FUNCTION=RDI_EXEC_VBS
)

set XVREDIST=%RDI_APPROOT%\tps\%RDI_PLATFORM%\xvcredist.exe
if not [%XIL_PA_NO_REDIST_CHECK%] == [1] (
  if exist "%XVREDIST%" (
    "%XVREDIST%" -check
    if [!ERRORLEVEL!] == [1] (
      echo.
      echo ERROR: This host does not have the appropriate Microsoft Visual C++
      echo        redistributable packages installed.
      echo.
      if not [%RDI_BATCH_MODE%] == [True] (
        echo        Launching installer: "%XVREDIST%"
	"%XVREDIST%"
        if not [!ERRORLEVEL!] == [0] (
	  pause
          set RDI_EXIT=True
          goto :EOF
        )
      ) else (
        echo        To install the required packages run:
        echo        "%XVREDIST%"
        set RDI_EXIT=True
        goto :EOF
      )
    )
  )
)

rem #
rem # Populate PATH with XILINX libraries and executables
rem #
if not [%XIL_PA_NO_XILINX_OVERRIDE%] == [1] (
  if defined XILINX (
    call :IS_VALID_TOOL "%XILINX%" nt64 valid
    if [!valid!] == [True] (
      set RDI_ISE_PLATFORM=nt64
      set _RDI_SET_XILINX_PATH=1
    ) else (
      call :IS_VALID_TOOL "%XILINX%" nt valid
      if [!valid!] == [True] (
        echo ERROR: %%XILINX%% does not contain 64bit executables.
        if not [%RDI_BATCH_MODE%] == [True] (
          pause
        )
        set RDI_EXIT=True
        goto :EOF
      )
    )
    if defined _RDI_SET_XILINX_PATH (
      set _RDI_SET_XILINX_PATH=
      if defined _RDI_DONT_SET_XILINX_AS_PATH (
        if defined MYXILINX (
          set RDI_PREPEND_PATH=%MYXILINX%/bin/!RDI_ISE_PLATFORM!;%MYXILINX%/lib/!RDI_ISE_PLATFORM!
        )
      ) else (
        if defined MYXILINX (
          set RDI_PREPEND_PATH=%MYXILINX%/bin/!RDI_ISE_PLATFORM!;%MYXILINX%/lib/!RDI_ISE_PLATFORM!;%XILINX%/bin/!RDI_ISE_PLATFORM!;%XILINX%/lib/!RDI_ISE_PLATFORM!
        ) else (
          set RDI_PREPEND_PATH=%XILINX%/bin/!RDI_ISE_PLATFORM!;%XILINX%/lib/!RDI_ISE_PLATFORM!
        )
      )
      set _RDI_DONT_SET_XILINX_AS_PATH=
    )
  )
)
rem #
rem # Populate PATH with XILINX_SDK executables
rem #
if not [%XIL_PA_NO_XILINX_SDK_OVERRIDE%] == [1] (
  if defined XILINX_SDK (
    set _valid=True
    for %%d in (lib/nt64, bin/nt64) do (
      if not exist "%XILINX_SDK%/%%d" (
        set _valid=False
      )
    )
    if [!_valid!] == [True] (
      set RDI_SDK_PLATFORM=nt64
    )
    if defined RDI_SDK_PLATFORM (
      if defined RDI_PREPEND_PATH (
        set RDI_PREPEND_PATH=%XILINX_SDK%/bin/!RDI_SDK_PLATFORM!;!RDI_PREPEND_PATH!
      ) else (
        set RDI_PREPEND_PATH=%XILINX_SDK%/bin/!RDI_SDK_PLATFORM!
      )
    )
    if defined RDI_PREPEND_PATH (
      set RDI_PREPEND_PATH=%XILINX_SDK%/bin;!RDI_PREPEND_PATH!
    ) else (
      set RDI_PREPEND_PATH=%XILINX_SDK%/bin
    )
  )
)

if defined XILINX_COMMON_TOOLS (
  if defined RDI_ISE_PLATFORM (
    call :IS_VALID_TOOL "%XILINX_COMMON_TOOLS%" %RDI_ISE_PLATFORM% valid
    if [!valid!] == [True] (
      if defined RDI_PREPEND_PATH (
        set RDI_PREPEND_PATH=!RDI_PREPEND_PATH!;%XILINX_COMMON_TOOLS%/bin/!RDI_ISE_PLATFORM!;%XILINX_COMMON_TOOLS%/lib/!RDI_ISE_PLATFORM!
      ) else (
        set RDI_PREPEND_PATH=%XILINX_COMMON_TOOLS%/bin/!RDI_ISE_PLATFORM!;%XILINX_COMMON_TOOLS%/lib/!RDI_ISE_PLATFORM!
      )
    ) else (
      echo.
      rem CR-961204: commented out warning (seems to be a bogus one?) - cshyamsu
      rem echo WARNING: Unable to find common Xilinx tools. Automatic updates and
      rem echo          license management will be disabled.
      rem echo.
    )
  )
)

set XILINX_DSP=%XILINX%
set XILINX_PLANAHEAD=%RDI_APPROOT%

if not exist "%RDI_JAVAROOT%" if not defined RDI_NO_JRE (
  echo WARNING: %RDI_JAVAROOT% does not exist.
)

if defined RDI_NO_JRE (
  set RDI_NO_JRE=
)

if not defined RDI_PROG (
  if [%RDI_CHECK_PROG%] == [True] (
    echo ERROR: No executable to launch. The -exec option *must* be used
    echo        when invoking the loader.
    echo        Example:
    echo          %~0 -exec EXECUTABLE
    echo          Where: EXECUTABLE is the name of binary in bin/unwrapped/PLAT.{o,d}
    set RDI_EXIT=True
    goto :EOF
  )
)

rem #
rem # Add .exe to %RDI_PROG% if its missing
rem #
if not [%RDI_PROG:~-4%] == [.exe] (
  if not [%RDI_PROG:~-4%] == [.bat] (
    set RDI_PROG=%RDI_PROG%.exe
  )
)

set RDI_PROGNAME=%RDI_PROG%
set RDI_PROG=%RDI_APPROOT%/bin/unwrapped/%RDI_PLATFORM%%RDI_OPT_EXT%/%RDI_PROGNAME%
set PRODVERSION_EXE=%RDI_APPROOT%/bin/unwrapped/%RDI_PLATFORM%%RDI_OPT_EXT%/prodversion.exe
rem #Locate RDI_PROG in patch areas.
set TEMP_PATCHROOT=!RDI_PATCHROOT!
:TOKEN_LOOP_PROG
for /F "delims=;" %%d in ("!TEMP_PATCHROOT!") do (
    if exist "%%d/bin/unwrapped/%RDI_PLATFORM%%RDI_OPT_EXT%/%RDI_PROGNAME%" (
        set RDI_PROG=%%d/bin/unwrapped/%RDI_PLATFORM%%RDI_OPT_EXT%/%RDI_PROGNAME%
    )
    if exist "%%d/bin/unwrapped/%RDI_PLATFORM%%RDI_OPT_EXT%/prodversion.exe" (
        set PRODVERSION_EXE=%%d/bin/unwrapped/%RDI_PLATFORM%%RDI_OPT_EXT%/prodversion.exe
    )
)
:CHARPOP_PROG
set CHARPOP=!TEMP_PATCHROOT:~0,1!
set TEMP_PATCHROOT=!TEMP_PATCHROOT:~1!
if "!TEMP_PATCHROOT!" EQU "" goto END_TOKEN_LOOP_PROG
if "!CHARPOP!" NEQ ";" goto CHARPOP_PROG
goto TOKEN_LOOP_PROG
:END_TOKEN_LOOP_PROG
rem # Silly syntax requires something after a label

rem #Add patch lib areas before %RDI_APPROOT%/lib
set RDI_LIBDIR=%RDI_APPROOT%/lib/%RDI_PLATFORM%%RDI_OPT_EXT%
set TEMP_PATCHROOT=!RDI_PATCHROOT!
:TOKEN_LOOP_LIBDIR
for /F "delims=;" %%d in ("!TEMP_PATCHROOT!") do (
    if exist "%%d/lib/%RDI_PLATFORM%%RDI_OPT_EXT%" (
        set RDI_LIBDIR=%%d/lib/%RDI_PLATFORM%%RDI_OPT_EXT%;!RDI_LIBDIR!
    )
)
:CHARPOP_LIBDIR
set CHARPOP=!TEMP_PATCHROOT:~0,1!
set TEMP_PATCHROOT=!TEMP_PATCHROOT:~1!
if "!TEMP_PATCHROOT!" EQU "" goto END_TOKEN_LOOP_LIBDIR
if "!CHARPOP!" NEQ ";" goto CHARPOP_LIBDIR
goto TOKEN_LOOP_LIBDIR
:END_TOKEN_LOOP_LIBDIR
rem # Silly syntax requires something after a label

rem #Add patch bin areas before %RDI_APPROOT%/bin
set RDI_BINDIR=%RDI_APPROOT%/bin
set TEMP_PATCHROOT=!RDI_PATCHROOT!
:TOKEN_LOOP_BINDIR
for /F "delims=;" %%d in ("!TEMP_PATCHROOT!") do (
    if exist "%%d/bin" (
        set RDI_BINDIR=%%d/bin;!RDI_BINDIR!
    )
)
:CHARPOP_BINDIR
set CHARPOP=!TEMP_PATCHROOT:~0,1!
set TEMP_PATCHROOT=!TEMP_PATCHROOT:~1!
if "!TEMP_PATCHROOT!" EQU "" goto END_TOKEN_LOOP_BINDIR
if "!CHARPOP!" NEQ ";" goto CHARPOP_BINDIR
goto TOKEN_LOOP_BINDIR
:END_TOKEN_LOOP_BINDIR
rem # Silly syntax requires something after a label

rem # Set TCL_LIBRARY so that planAhead can find init.tcl at startup
set TCL_LIBRARY=%RDI_APPROOT%/tps/tcl/tcl8.5

rem # Set ISL path
set ISL_IOSTREAMS_RSA=%RDI_APPROOT%/tps/isl

rem # Control what shared objects planAhead.java loads.  This variable
rem # allows to conditional loading depending for rmake builds vs hmake
rem # builds.
set RDI_BUILD=yes

rem # Set the MINGW path from the Vivado install.

set RDI_MINGW_LIB=%RDI_APPROOT%\tps\mingw\6.2.0\win64.o\nt\bin;%RDI_APPROOT%\tps\mingw\6.2.0\win64.o\nt\libexec\gcc\x86_64-w64-mingw32\6.2.0

rem # Set the library load path. One Windows this is %PATH%
rem # Add planAhead binary location to path.
if defined RDI_PREPEND_PATH (
  if not defined PATH (
    if exist "%RDI_JAVAROOT%" (
      set PATH=%RDI_LIBDIR%;%RDI_JAVAROOT%/bin/server;%RDI_JAVAROOT%/bin;%RDI_PREPEND_PATH%;%RDI_MINGW_LIB%
    ) else (
      set PATH=%RDI_LIBDIR%;%RDI_PREPEND_PATH%;%RDI_MINGW_LIB%
    )
  ) else (
    if exist "%RDI_JAVAROOT%" (
      set PATH=%RDI_LIBDIR%;%RDI_JAVAROOT%/bin/server;%RDI_JAVAROOT%/bin;%RDI_PREPEND_PATH%;!PATH!;%RDI_MINGW_LIB%
    ) else (
      set PATH=%RDI_LIBDIR%;%RDI_PREPEND_PATH%;!PATH!;%RDI_MINGW_LIB%
    )
  )
) else (
  if not defined PATH (
    if exist "%RDI_JAVAROOT%" (
      set PATH=%RDI_LIBDIR%;%RDI_JAVAROOT%/bin/server;%RDI_JAVAROOT%/bin;%RDI_MINGW_LIB%
    ) else (
      set PATH=%RDI_LIBDIR%;%RDI_MINGW_LIB%
    )
  ) else (
    if exist "%RDI_JAVAROOT%" (
      set PATH=%RDI_LIBDIR%;%RDI_JAVAROOT%/bin/server;%RDI_JAVAROOT%/bin;!PATH!;%RDI_MINGW_LIB%
    ) else (
      set PATH=%RDI_LIBDIR%;!PATH!;%RDI_MINGW_LIB%
    )
  )
)
if defined RDI_JAVAFXROOT (
  if exist "%RDI_JAVAFXROOT%" (
    set PATH=%RDI_JAVAFXROOT%/lib;%RDI_JAVAFXROOT%/bin;!PATH!
  )
)
if defined RDI_JAVACEFROOT (
  if exist "%RDI_JAVACEFROOT%" (
    set PATH=%RDI_JAVACEFROOT%/bin/lib/win64;!PATH!
  )
)

rem #Add %RDI_APPROOT%/bin after any existing PATH
if not defined PATH (
  set PATH=%RDI_BINDIR%
) else (
  set PATH=%RDI_BINDIR%;!PATH!
)
rem # CR-1006623 Vivado bootloader enhancements to support gnu path
IF EXIST %XILINX_VIVADO%\gnu\microblaze\lin\bin\ (
  set PATH=%XILINX_VIVADO%\gnu\microblaze\lin\bin;!PATH!
)

IF EXIST %XILINX_VIVADO%\gnu\microblaze\nt\bin\ (
  set PATH=%XILINX_VIVADO%\gnu\microblaze\nt\bin;!PATH!
)

IF EXIST %XILINX_VIVADO%\gnuwin\bin\ (
  set PATH=%XILINX_VIVADO%\gnuwin\bin;!PATH!
)

rem # CR 1021764 add python path setup to loaders.
if [%_RDI_NEEDS_PYTHON%] == [True] (
  set RDI_PYTHON3_VERSION=3.8.3
  set RDI_PYTHON3=%RDI_APPROOT%\tps\%RDI_PLATFORM%\python-!RDI_PYTHON3_VERSION!
  set RDI_PYTHONHOME=!RDI_PYTHON3!
  set RDI_PYTHONPATH=!RDI_PYTHONHOME!;!RDI_PYTHONHOME!\bin;!RDI_PYTHONHOME!\lib;!RDI_PYTHONHOME!\lib\site-packages
  set RDI_PYTHON_LD_LIBPATH=!RDI_PYTHONHOME!\lib

  if exist "!RDI_PYTHON3!" (
    set PYTHON=!RDI_PYTHON3!
    set PYTHONHOME=!RDI_PYTHONHOME!
    set PYTHONPATH=!RDI_PYTHONPATH!;!PYTHONPATH!

    if not defined PATH (
      set PATH=!RDI_PYTHONPATH!;!RDI_PYTHON_LD_LIBPATH!
    ) else (
      set PATH=!PATH!;!RDI_PYTHONPATH!;!RDI_PYTHON_LD_LIBPATH!
    )
  )
)
set _RDI_NEEDS_PYTHON=

rem # set RT_LIBPATH - planAhead needs it set before shared libraries are initialized
set RT_LIBPATH=%RDI_APPROOT%/scripts/rt/data
set TEMP_PATCHROOT=!RDI_PATCHROOT!
:TOKEN_LOOP_RT_LIBPATH
for /F "delims=;" %%d in ("!TEMP_PATCHROOT!") do (
  if exist "%%d/scripts/rt/data" (
    set RT_LIBPATH=%%d/scripts/rt/data
    goto END_TOKEN_LOOP_RT_LIBPATH
  )
)
:CHARPOP_RT_LIBPATH
set CHARPOP=!TEMP_PATCHROOT:~0,1!
set TEMP_PATCHROOT=!TEMP_PATCHROOT:~1!
if "!TEMP_PATCHROOT!" EQU "" goto END_TOKEN_LOOP_RT_LIBPATH
if "!CHARPOP!" NEQ ";" goto CHARPOP_RT_LIBPATH
goto TOKEN_LOOP_RT_LIBPATH
:END_TOKEN_LOOP_RT_LIBPATH
rem # Silly syntax requires something after a label

set RT_TCL_PATH=%RDI_APPROOT%/scripts/rt/base_tcl/tcl
set TEMP_PATCHROOT=!RDI_PATCHROOT!
:TOKEN_LOOP_RT_TCL_PATH
for /F "delims=;" %%d in ("!TEMP_PATCHROOT!") do (
  if exist "%%d/scripts/rt/base_tcl/tcl" (
    set RT_TCL_PATH=%%d/scripts/rt/base_tcl/tcl
    goto END_TOKEN_LOOP_RT_TCL_PATH
  )
)
:CHARPOP_RT_TCL_PATH
set CHARPOP=!TEMP_PATCHROOT:~0,1!
set TEMP_PATCHROOT=!TEMP_PATCHROOT:~1!
if "!TEMP_PATCHROOT!" EQU "" goto END_TOKEN_LOOP_RT_TCL_PATH
if "!CHARPOP!" NEQ ";" goto CHARPOP_RT_TCL_PATH
goto TOKEN_LOOP_RT_TCL_PATH
:END_TOKEN_LOOP_RT_TCL_PATH
rem # Silly syntax requires something after a label

set SYNTH_COMMON=%RT_LIBPATH%

rem #
rem # When RDI_EXIT is defined short circuit and exit.
rem # The batch command 'exit' should be avoided as it will cause the
rem # cmd.exe which invoked this script to exit.
rem #

set TMP_XILINX_PATH=clear
set TMP_XILINX_PATH=
rem # set RDI_APPROOT to be a multipath at this point
set TEMP_PATCHROOT=!RDI_PATCHROOT!
:TOKEN_LOOP_APPROOT
for /F "delims=;" %%d in ("!TEMP_PATCHROOT!") do (
  if exist "%%d" (
    set RDI_APPROOT=%%d;!RDI_APPROOT!
    if defined TMP_XILINX_PATH (
      set TMP_XILINX_PATH=%%d;!TMP_XILINX_PATH!
    ) else (
      set TMP_XILINX_PATH=%%d
    )
  )
)
:CHARPOP_APPROOT
set CHARPOP=!TEMP_PATCHROOT:~0,1!
set TEMP_PATCHROOT=!TEMP_PATCHROOT:~1!
if "!TEMP_PATCHROOT!" EQU "" goto END_TOKEN_LOOP_APPROOT
if "!CHARPOP!" NEQ ";" goto CHARPOP_APPROOT
goto TOKEN_LOOP_APPROOT
:END_TOKEN_LOOP_APPROOT
rem # Silly syntax requires something after a label

rem # Dedupe the PATH
set _NEWPATH=
set PATH=%PATH:"=%
for %%A in ("%PATH:;=";"%") do (
  set _FOUND=0
  set _OLDENTRY=%%A
  set _OLDENTRY=!_OLDENTRY:"=!
  set _OLDENTRY=!_OLDENTRY:\=/!
  if !_OLDENTRY:~-1!==/ set _OLDENTRY=!_OLDENTRY:~0,-1!
  for %%B in ("!_NEWPATH:;=";"!") do (
    set _NEWENTRY=%%B
    set _NEWENTRY=!_NEWENTRY:"=!
    set _NEWENTRY=!_NEWENTRY:\=/!
    if !_NEWENTRY:~-1!==/ set _NEWENTRY=!_NEWENTRY:~0,-1!
    if /I [!_OLDENTRY!] == [!_NEWENTRY!] (
      set _FOUND=1
    )
  )
  if [!_FOUND!] == [0] (
    set _OLDENTRY=%%A
    set _OLDENTRY=!_OLDENTRY:"=!
    if not defined _NEWPATH (
      set _NEWPATH=!_OLDENTRY!
    ) else (
      set _NEWPATH=!_NEWPATH!;!_OLDENTRY!
    )
  )
)
set PATH=!_NEWPATH!
set _FOUND=
set _NEWPATH=
set _OLDENTRY=
set _NEWENTRY=

if not defined RDI_EXIT (
  if [%RDI_VERBOSE%] == [True] (
    echo      **** ENVIRONMENT DEBUG INFO ****
    echo               XILINX: "%XILINX%"
    if defined XILINX_HLS (
      echo           XILINX_HLS: "%XILINX_HLS%"
    )
    if defined XILINX_VIVADO (
      echo        XILINX_VIVADO: "%XILINX_VIVADO%"
    )
    echo           XILINX_SDK: "%XILINX_SDK%"
    echo          XILINX_PATH: "!TMP_XILINX_PATH!"
    echo          RDI_BINROOT: "%RDI_BINROOT%"
    echo          RDI_APPROOT: "%RDI_APPROOT%"
    echo          HDI_APPROOT: "%HDI_APPROOT%"
    echo         RDI_BASEROOT: "%RDI_BASEROOT%"
    echo          RDI_DATADIR: "%RDI_DATADIR%"
    echo           RDI_LIBDIR: "%RDI_LIBDIR%"
    echo           RDI_BINDIR: "%RDI_BINDIR%"
    echo XILINXD_LICENSE_FILE: "%XILINXD_LICENSE_FILE%"
    if exist "%RDI_JAVAROOT%" (
      echo         RDI_JAVAROOT: "%RDI_JAVAROOT%"
    )
    echo                 PATH: "!PATH!"
  )
  if [%RDI_CHECK_PROG%] == [True] (
    if not exist "%RDI_PROG%" (
      echo ERROR: Could not find 64-bit executable.
      echo ERROR: %RDI_PROG% does not exist
      exit /b 1
    )
  )
  set _RDI_NEEDS_VERSION=
  call "%RDI_BINROOT%/rdiArgs.bat" %RDI_ARGS%
)
endlocal
set RDI_ARGS_FUNCTION=
set prodversionout=
exit /b %ERRORLEVEL%
goto :EOF


rem #
rem # Check if %dir% contains valid executables for %plat%
rem #
rem #  dir   - Directory to test
rem #  plat  - nt or nt64
rem #  valid - Will be set to True if the following directories exist:
rem #                   %dir%/bin/%plat%
rem #                   %dir%/lib/%plat%
rem #
rem # WARNING: The variables _dir, _plat, and _valid cannot be used elsewhere
rem #          in loader.bat
:IS_VALID_TOOL %dir% %plat% valid
  set _dir=%~1
  set _plat=%2
  set _valid=True
  for %%d in (lib/%_plat%, bin/%_plat%) do (
    if not exist "%_dir%/%%d" (
      set _valid=False
    )
  )
 set %3=%_valid%
goto :EOF


