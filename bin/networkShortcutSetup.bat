@echo off

rem store the original image dir into a variable
set INSTALLER_ROOT_DIR=%~dp0\.. 
set ARGS=%ARGS% -DINSTALLER_ROOT_DIR=%INSTALLER_ROOT_DIR%

rem resolve UNC path
pushd %~dp0
set root=%cd%

rem xsetup.bat is in <root>\bin, get the parent directory (<root>)
set parent=%cd%\..

CALL setup-boot-loader.bat %*
set ARGS=%ARGS% -Dlogback.configurationFile="%parent%/data/xic-logback.xml"

IF NOT "%DEBUG_ARGS%" == "" (
 echo adding %DEBUG_ARGS% to %ARGS%
 set ARGS=%DEBUG_ARGS% %ARGS%
)

set ARGS=%ARGS% -DINSTALLATION_MODE=NetworkInstall
IF "%XBATCHCFG%"=="" (
  REM echo cmd: %X_JAVA_HOME%\bin\javaw.exe %ARGS% -cp %X_CLASS_PATH% -jar %parent%\lib\classes\xinstaller.jar
  REM %X_JAVA_HOME%\bin\java.exe -splash:%parent%\data\images\splash.png %ARGS% -cp %X_CLASS_PATH% -jar %parent%\lib\classes\xinstaller.jar
  %X_JAVA_HOME%\bin\java.exe %ARGS% -cp "%X_CLASS_PATH%;%parent%\lib\classes\commons-cli-1.4.jar" -splash:"%parent%\data\images\splash.png" com.xilinx.installer.api.InstallerLauncher
) ELSE (
  echo "XBATCHXFG is set, forcing batch mode"
  %X_JAVA_HOME%\bin\java.exe %ARGS% -cp "%X_CLASS_PATH%;%parent%\lib\classes\commons-cli-1.4.jar" com.xilinx.installer.cli.InstallerCLI -a %XBATCHACTION% -c %XBATCHCFG%
)
RMDIR /Q /S %TEMP_NATIVE_LIB%
popd
