@echo off
set root=%~dp0

rem xsetup.bat is in <root>\bin, get the parent directory (<root>)
pushd %root%\..
set parent=%cd%

CALL %root%setup-boot-loader.bat %*
set ARGS=%ARGS% -Dlogback.configurationFile=%parent%\data\xic-logback.xml
set ARGS=%ARGS% -DLOG_FILE_NAME=%USERPROFILE%/.Xilinx\xinstall\xic.log
set ARGS=%ARGS% -DLOG_FILE=%USERPROFILE%\.Xilinx\xinstall\xic.log

IF NOT "%DEBUG_ARGS%" == "" (
 echo adding %DEBUG_ARGS% to %ARGS%
 set ARGS=%DEBUG_ARGS% %ARGS%
)

rem echo "%X_JAVA_HOME%"\bin\java.exe %ARGS% -cp %X_CLASS_PATH% com.xilinx.xic.XIC %*
rem reset installer environment variables that would affect XiC
set HAS_DYNAMIC_LANGUAGE_BUNDLE=false
set ARGS=%ARGS% -DHAS_DYNAMIC_LANGUAGE_BUNDLE=false -Xmx1024m
"%X_JAVA_HOME%"\bin\java.exe %ARGS% -cp %X_CLASS_PATH% com.xilinx.xic.XIC %*
popd
