@echo off
rem #
rem # COPYRIGHT NOTICE
rem # Copyright 1986-2016 Xilinx, Inc. All Rights Reserved.
rem #

if defined RDI_SETUP_ENV_FUNCTION (
  call :%RDI_SETUP_ENV_FUNCTION% %*
  rem #
  rem # Unset in case of recursive calls to this batch file
  rem #
  set RDI_SETUP_ENV_FUNCTION=
  goto :EOF
)


rem #
rem # Set RDI_BASEROOT, RDI_APPROOT, RDI_BINROOT, and HDI_APPROOT.
rem #
rem # RDI_BASEROOT - is the absolute path to directory above the
rem #                the product root (RDI_APPROOT).
rem #
rem # RDI_APPROOT - is the absolute path to the directory above the
rem #               product bin directory (RDI_BINROOT).
rem #
rem # RDI_BINROOT - is the absolute path to the directory this script
rem #               was called from.
rem #
rem # HDI_APPROOT - is needed for backwards compatibility
rem #               until code is changed to refer to RDI_APPROOT.
rem #

set RDI_BINROOT=%~dp0
rem # Remove trailing '/'
set RDI_BINROOT=%RDI_BINROOT:~0,-1%
rem # Convert '\' to '/'
set RDI_BINROOT=%RDI_BINROOT:\=/%
call :DIRNAME "%RDI_BINROOT%" RDI_APPROOT

if not [%XIL_PA_NO_XILINX_OVERRIDE%] == [1] (
  set MYXILINX=
)

set RDI_PATCHROOT=
rem #Do While loop to search for nested patch areas.
setlocal enableextensions enabledelayedexpansion
set _BASELINE_SEARCH=1
:BASELINE_WHILE
    set _BASELINE_FILE=!RDI_APPROOT!/data/baseline.txt
    call :LOADPATH "!_BASELINE_FILE!" "%RDI_BINROOT%" "!RDI_APPROOT!" RDI_BASELINE

    if not [%XIL_PA_NO_XILINX_OVERRIDE%] == [1] (
        if not defined MYXILINX (
            rem # locate ISE baseline to set MYXILINX
            set _BASELINE_FILE=!RDI_APPROOT!/data/ise_baseline.txt
            call :LOADPATH "!_BASELINE_FILE!" "%RDI_BINROOT%" "!RDI_APPROOT!" _TMP_MYXILINX
            if exist "!_TMP_MYXILINX!" (
                set MYXILINX=!_TMP_MYXILINX!
                set _TMP_MYXILINX=
            )
        )
    )

    if defined RDI_BASELINE (
        if exist "!RDI_BASELINE!" (
            rem # This is a reverse ordered list
            call :FINDDIRS "!RDI_APPROOT!/patches" _RDI_PATCHDIRS
            if not "!_RDI_PATCHDIRS!" == "" (
                set RDI_PATCHROOT=!_RDI_PATCHDIRS!;!RDI_PATCHROOT!
            )
            set RDI_PATCHROOT=!RDI_APPROOT!;!RDI_PATCHROOT!
            set RDI_APPROOT=!RDI_BASELINE!
            set RDI_BASELINE=
        ) else (
            set _BASELINE_SEARCH=0
        )
    ) else (
        set _BASELINE_SEARCH=0
    )
if !_BASELINE_SEARCH! EQU 1 (
    GOTO BASELINE_WHILE
)
endlocal & set RDI_PATCHROOT=%RDI_PATCHROOT%& set RDI_APPROOT=%RDI_APPROOT%& set MYXILINX=%MYXILINX%

rem # Append (reverse ordered) RDI_PATCHROOT with valid locations specified by MYVIVADO of XILINX_PATH (preferred)
set INT_VARIABLE_NAME=XILINX_PATH
if defined XILINX_PATH (
    set MYVIVADO=%XILINX_PATH%
    set INT_VARIABLE_NAME=XILINX_PATH
) else (
    if defined MYVIVADO (
        set XILINX_PATH=%MYVIVADO%
        set INT_VARIABLE_NAME=MYVIVADO
    )
)
if defined XILINX_PATH (
    setlocal enableextensions enabledelayedexpansion
    set _RDI_EXTENDED_WARNING=
    set TEMP_PATCHROOT=%XILINX_PATH%
    set TEMP_PATCHROOT=!TEMP_PATCHROOT!;
    :TOKEN_LOOP_MORE_PATCHES
    for /F "delims=;" %%d in ("!TEMP_PATCHROOT!") do (
        set element=%%d
        if "!element:~-1!"==" " (
            echo WARNING: Trailing white space detected for !element!. Your %INT_VARIABLE_NAME% may be set incorrectly.
            set _RDI_EXTENDED_WARNING=1
        )
        if exist "!element!" (
            set _RDI_PATCHROOT=!element!;!_RDI_PATCHROOT!
        ) else (
            if not "!element!" == "" (
                echo WARNING: Ignoring invalid %INT_VARIABLE_NAME% location !element!.
                set _RDI_EXTENDED_WARNING=1
            )
        )
    )
    :CHARPOP_MORE_PATCHES
    set CHARPOP=!TEMP_PATCHROOT:~0,1!
    set TEMP_PATCHROOT=!TEMP_PATCHROOT:~1!
    if "!TEMP_PATCHROOT!" EQU "" goto END_TOKEN_LOOP_MORE_PATCHES
    if "!CHARPOP!" NEQ ";" goto CHARPOP_MORE_PATCHES
    goto TOKEN_LOOP_MORE_PATCHES
    :END_TOKEN_LOOP_MORE_PATCHES
    rem # Silly syntax requires something after a label
    if defined _RDI_EXTENDED_WARNING (
        echo Resolution: An invalid %INT_VARIABLE_NAME% location has been detected. To resolve this issue:
        echo.
        echo 1. Verify the value of %INT_VARIABLE_NAME% is accurate by viewing the value the variable via 'set %INT_VARIABLE_NAME%' for Windows or 'echo $%INT_VARIABLE_NAME%' for Linux, and update it as needed.
        echo.
        echo 2. To unset the variable using on Windows using 'set %INT_VARIABLE_NAME%=' or remove it from Advanced System Settings\Environment Variables. On Linux 'unsetenv %INT_VARIABLE_NAME%'
        echo.
    )
    set _RDI_EXTENDED_WARNING=
    endlocal & set RDI_PATCHROOT=%RDI_PATCHROOT%%_RDI_PATCHROOT%
)

call :DIRNAME "%RDI_APPROOT%" RDI_BASEROOT
call :DIRNAME "%RDI_BASEROOT%" RDI_INSTALLROOT
call :BASENAME "%RDI_APPROOT%" RDI_INSTALLVER

set HDI_APPROOT=%RDI_APPROOT%

setlocal enableextensions enabledelayedexpansion
call :FINDDIRS "%RDI_APPROOT%/patches" _RDI_PATCHDIRS
if not "!_RDI_PATCHDIRS!" == "" (
    set RDI_PATCHROOT=!_RDI_PATCHDIRS!;!RDI_PATCHROOT!
)
endlocal & set RDI_PATCHROOT=%RDI_PATCHROOT%

rem # Create "Documents and Settings/<username>/Xilinx/PlanAhead" directory
rem # for log files.
if not exist "%APPDATA%/Xilinx/PlanAhead" if "%RDI_PROG%" == "planAhead" (
  mkdir -p "%APPDATA%/Xilinx/PlanAhead" > NUL 2>&1
)
rem # Create "Documents and Settings/<username>/Xilinx/Vivado" directory
rem # for log files.
if not exist "%APPDATA%/Xilinx/Vivado" if "%RDI_PROG%" == "vivado" (
  mkdir -p "%APPDATA%/Xilinx/Vivado" > NUL 2>&1
)
set _RDI_SETENV_RUN=true

goto :EOF


rem #
rem # Mimic Unix dirname where the dirname of %path% will be stored
rem # in %dir%
rem #
:DIRNAME %path% %dir%
  set _dir=%~dp1
  set _dir=%_dir:~0,-1%
  set _dir=%_dir:\=/%
  set %2=%_dir%
  set _dir=
  goto :EOF


rem #
rem # Mimic Unix basename where the basename of %path% will be stored
rem # in %file%
rem #
:BASENAME %path% %file%
  set _file=%~nx1
  set %2=%_file%
  set _file=
  goto :EOF


rem #
rem # Locate the %path% found in %file%
rem #
:LOADPATH %file% %binroot% %approot% %path%
  set _BASELINE=%~1
  set _BINROOT=%~2
  set _APPROOT=%~3
  setlocal enableextensions enabledelayedexpansion
  set _BASELINE_ERROR=

  if exist "%_BASELINE%" (
    for /F "delims=" %%F in (%_BASELINE%) do (
      set _NOT_DEFINED=Not Defined
      if [%%F] == [!_NOT_DEFINED!] (
        set _BASELINE_ERROR=ERROR: A baseline has not been defined.
      ) else (
        set _BASELINE_LINE=%%F
        set _PREFIX=!_BASELINE_LINE:~0,2!
        if [!_PREFIX!] == [..] (
          set _BASELINE_LINE=%_APPROOT%/!_BASELINE_LINE!
        )
        if exist !_BASELINE_LINE! (
          pushd "%CD%"
          rem # Convert '/' to '\' since chdir does not work with / and ..
          set _BASELINE_LINE=!_BASELINE_LINE:/=\!
          pushd !_BASELINE_LINE!
          set _RDI_BASELINE=!CD:\=/!
          set _PREFIX=!_BINROOT:~0,2!
          if [!_PREFIX!] == [//] (
            set _BASELINE_DRIVE=!_RDI_BASELINE:~0,2!
            set _RDI_BASELINE=!_RDI_BASELINE:~2!
            for /f "tokens=2*" %%a in ('net use !_BASELINE_DRIVE!^|find "Remote name"') do set _BASELINE_UNC=%%b
            set _BASELINE_UNC=!_BASELINE_UNC:\=/!
            set _RDI_BASELINE=!_BASELINE_UNC!!_RDI_BASELINE!
          )
          popd
          popd
        ) else (
          set _BASELINE_ERROR=ERROR: The baseline '!_BASELINE_LINE!' does not exist.
        )
      )
    )
  )
  endlocal & set _RDI_BASELINE=%_RDI_BASELINE%
  if defined _RDI_BASELINE (
    set %4=%_RDI_BASELINE%
  )

  if defined _BASELINE_ERROR (
    echo %_BASELINE_ERROR%
    if exist "%_APPROOT%/data/patches" (
      echo  A baseline is the path of the full install being patched and is required
      echo  for patches to function correctly.
      echo.
      echo  To establish a baseline for this patch, run 'establish-baseline.bat'
      echo  in '%_APPROOT%/scripts/patch'
      echo  and enter the necessary install path when prompted.
      echo.
      echo  If you received this error running from a non-patch installation,
      echo  please contact customer support.
    ) else (
      echo  Vivado is unable to locate the path to PlanAhead. PlanAhead is necessary
      echo  for Vivado to run. Please contact customer support for assistance.
    )
    set RDI_EXIT=True
  )

  rem # Clear temp variables
  set _NOT_DEFINED=
  set _BASELINE=
  set _BASELINE_LINE=
  set _BASELINE_ERROR=
  set _BASELINE_DRIVE=
  set _BASELINE_UNC=
  set _PREFIX=
  set _RDI_BASELINE=
  set _BINROOT=
  set _APPROOT=

  goto :EOF

rem #
rem # Locate and version sort the dirs found in path
rem #
:FINDDIRS %path% %dirs%
  setlocal enableextensions enabledelayedexpansion
  set _PATH=%~1
  set _DIRS=

  if exist "%_PATH%" (
    set _index=0
    for /F "tokens=*" %%F in ('dir /b /on /ad "%_PATH%\*"') do (
      set /A _index+=1
      set "_dirs[!_index!]=%%F"
    )
    for /L %%i in (1 1 !_index!) do (
      for /L %%j in (1 1 !_index!) do (
        set /A next=%%j+1
        if "!next!" LEQ "!_index!" (
          call :COMPAREDIRS "%%j" "!next!" _res
          if "!_res!" EQU "1" (
            call :SWAPDIRS "%%j" "!next!"
          )
        )
      )
    )
    for /L %%i in (1 1 !_index!) do (
      if [!_DIRS!] == [] (
        if exist %_PATH%/!_dirs[%%i]!/vivado (
          set _DIRS=%_PATH%/!_dirs[%%i]!/vivado
        )
        if exist %_PATH%/!_dirs[%%i]!/vitis (
          set _DIRS=%_PATH%/!_dirs[%%i]!/vitis
        )
        if exist %_PATH%/!_dirs[%%i]!/sdk (
          set _DIRS=%_PATH%/!_dirs[%%i]!/sdk
        )
      ) else (
        if exist %_PATH%/!_dirs[%%i]!/vivado (
          set _DIRS=!_DIRS!;%_PATH%/!_dirs[%%i]!/vivado
        )
        if exist %_PATH%/!_dirs[%%i]!/vitis (
          set _DIRS=!_DIRS!;%_PATH%/!_dirs[%%i]!/vitis
        )
        if exist %_PATH%/!_dirs[%%i]!/sdk (
          set _DIRS=!_DIRS!;%_PATH%/!_dirs[%%i]!/sdk
        )
      )
    )
  )
  endlocal & set _DIRS=%_DIRS%
  set %2=%_DIRS%

  goto :EOF

:SWAPDIRS %index1% %index2%
  set _i=%~1
  set _j=%~2
  set _tmp=!_dirs[%_j%]!
  set "_dirs[%_j%]=!_dirs[%_i%]!"
  set "_dirs[%_i%]=%_tmp%"
  goto :EOF

:COMPAREDIRS %string1% %string2% %result%
  set TEMP_S1=!_dirs[%~1]!
  set TEMP_S2=!_dirs[%~2]!
  :ITERATE_S1
  set CHARSET_S1=
  :CHARPOP_S1
  set CHARPOP_S1=!TEMP_S1:~0,1!
  if "!CHARPOP_S1!" EQU "0" goto NEXT_CHARPOP_S1
  if "!CHARPOP_S1!" EQU "1" goto NEXT_CHARPOP_S1
  if "!CHARPOP_S1!" EQU "2" goto NEXT_CHARPOP_S1
  if "!CHARPOP_S1!" EQU "3" goto NEXT_CHARPOP_S1
  if "!CHARPOP_S1!" EQU "4" goto NEXT_CHARPOP_S1
  if "!CHARPOP_S1!" EQU "5" goto NEXT_CHARPOP_S1
  if "!CHARPOP_S1!" EQU "6" goto NEXT_CHARPOP_S1
  if "!CHARPOP_S1!" EQU "7" goto NEXT_CHARPOP_S1
  if "!CHARPOP_S1!" EQU "8" goto NEXT_CHARPOP_S1
  if "!CHARPOP_S1!" EQU "9" goto NEXT_CHARPOP_S1
  goto END_CHARPOP_S1
  :NEXT_CHARPOP_S1
  set CHARSET_S1=!CHARSET_S1!!CHARPOP_S1!
  set TEMP_S1=!TEMP_S1:~1!
  if "!TEMP_S1!" EQU "" goto END_CHARPOP_S1
  goto CHARPOP_S1
  :END_CHARPOP_S1
  if [!CHARSET_S1!] EQU [] (
    set CHARSET_S1=!CHARPOP_S1!
    set TEMP_S1=!TEMP_S1:~1!
  ) else (
    set /A CHARSET_S1+=1000000000
  )
  set CHARSET_S2=
  :CHARPOP_S2
  set CHARPOP_S2=!TEMP_S2:~0,1!
  if "!CHARPOP_S2!" EQU "0" goto NEXT_CHARPOP_S2
  if "!CHARPOP_S2!" EQU "1" goto NEXT_CHARPOP_S2
  if "!CHARPOP_S2!" EQU "2" goto NEXT_CHARPOP_S2
  if "!CHARPOP_S2!" EQU "3" goto NEXT_CHARPOP_S2
  if "!CHARPOP_S2!" EQU "4" goto NEXT_CHARPOP_S2
  if "!CHARPOP_S2!" EQU "5" goto NEXT_CHARPOP_S2
  if "!CHARPOP_S2!" EQU "6" goto NEXT_CHARPOP_S2
  if "!CHARPOP_S2!" EQU "7" goto NEXT_CHARPOP_S2
  if "!CHARPOP_S2!" EQU "8" goto NEXT_CHARPOP_S2
  if "!CHARPOP_S2!" EQU "9" goto NEXT_CHARPOP_S2
  goto END_CHARPOP_S2
  :NEXT_CHARPOP_S2
  set CHARSET_S2=!CHARSET_S2!!CHARPOP_S2!
  set TEMP_S2=!TEMP_S2:~1!
  if "!TEMP_S2!" EQU "" goto END_CHARPOP_S2
  goto CHARPOP_S2
  :END_CHARPOP_S2
  if [!CHARSET_S2!] EQU [] (
    set CHARSET_S2=!CHARPOP_S2!
    set TEMP_S2=!TEMP_S2:~1!
  ) else (
    set /A CHARSET_S2+=1000000000
  )
  if "!CHARSET_S1!" LSS "!CHARSET_S2!" (
    set %3=-1
    goto :EOF
  )
  if "!CHARSET_S1!" GTR "!CHARSET_S2!" (
    set %3=1
    goto :EOF
  )
  if "!TEMP_S1!" EQU "" goto :END_ITERATE_S1
  if "!TEMP_S2!" EQU "" goto :END_ITERATE_S2
  goto :ITERATE_S1
  :END_ITERATE_S1
  if "!TEMP_S2!" NEQ "" (
    set %3=-1
    goto :EOF
  )
  :END_ITERATE_S2
  if "!TEMP_S1!" NEQ "" (
    set %3=1
    goto :EOF
  )
  :END_ITERATE
  set %3=0
  goto :EOF
