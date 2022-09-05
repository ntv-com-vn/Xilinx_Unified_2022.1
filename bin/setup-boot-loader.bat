@echo off
set ARCH=32
REM Reset ARGS (do not use what ever was set by installer/xic when this instance was started
set ARGS=
set XIL_PA_NO_MYVIVADO_OVERRIDE=1
set X_BATCH=0
set MYVIVADO=
IF EXIST "%PROGRAMFILES(X86)%" (set ARCH=64) ELSE (set ARCH=32)



rem XiC can start installer / updater, for such cases
rem check to see if XiC or uninstall has set attributes to use
rem Also checks to see if installer needs to be run in batch mode.
:Loop


IF [%1] == [] GOTO Continue
IF [%1] == [-XIC_JRE_LOCATION] (
 SET XIC_JRE_LOCATION=%2
) ELSE (
 IF [%1] == [-INSTALLATION_DATA_FILE] (
   SET INSTALLATION_DATA_FILE=%2
 ) ELSE (  
   IF [%1] == [-LOAD_64_NATIVE] (
      SET LOAD_64_NATIVE=%2
    ) ELSE (
     IF [%1] == [-SSO_TOKEN] (
      SET SSO_TOKEN=%2
     ) ELSE (
      IF [%1] == [-USER_NAME] (
        SET USER_NAME=%2
      ) ELSE (
       IF [%1] == [-user.dir] (
        SET user.dir=%2
       ) ELSE (
        IF [%1] == [-PATH] (
         SET PATH=%2
        ) ELSE (
         IF [%1] == [-USER_NAME] (
          SET USER_NAME=%2
         ) ELSE (
           IF [%1] == [-INSTALLER_ROOT_DIR] (
            SET INSTALLER_ROOT_DIR=%2
          ) ELSE (
           IF [%1] == [-XIC_SSO_COOCKIE_STR] (
            SET XIC_SSO_COOCKIE_STR=%2
           ) ELSE (
            IF [%1] == [-SSO_COOKIE_TOKEN] (
             SET SSO_COOKIE_TOKEN=%2
            ) ELSE (
             IF [%1] == [-h] SET X_BATCH=1
             IF [%1] == [--help] SET X_BATCH=1
             IF [%1] == [-help] SET X_BATCH=1
             IF [%1] == [-b] SET X_BATCH=1
             IF [%1] == [--batch] SET X_BATCH=1
            )
          )          
          )
         )
        )
       )
      )
     )   
    )
   )
  ) 
SHIFT
GOTO Loop
:Continue

rem @echo XIC_JRE_LOCATION: %XIC_JRE_LOCATION% > c:\temp\app-debug.txt
rem @echo -LOAD_64_NATIVE %LOAD_64_NATIVE% -SSO_TOKEN %SSO_TOKEN% -USER_NAME %USER_NAME% -PATH %PATH% >> c:\temp\app-debug.txt

rem Choose 64 bit jre only if 64 bit libs are available and
rem vice versa.
set NATIVE_LIB_PATH=%parent%\lib\win64.o;
rem set X_JAVA_HOME="%parent%\tps\win64\jre9.0.4"
set X_JAVA_HOME="%parent%\tps\win64\jre11.0.11_9"
set ARGS=%ARGS% -DLOAD_64_NATIVE="true"
set NATIVE_LIB_PATH=%NATIVE_LIB_PATH%;%SystemRoot%\system32;%SystemRoot%\system32\wbem;%SystemRoot%
set PATH=%NATIVE_LIB_PATH%
rem @echo PATH: %PATH% >> c:\temp\app-debug.txt

set ARGS=%ARGS% -Djava.library.path="%NATIVE_LIB_PATH%" -DOS_ARCH="%ARCH%"
rem echo ARGS: %ARGS% >> c:\temp\app-debug.txt

rem Set the default idata file name
IF EXIST "%parent%\data\idata.dat" (
  set ARGS=%ARGS% -DIDATA_LOCATION_FROM_USER="%parent%\data\idata.dat" -Duser.dir="%parent%"
)

rem Set the default location of dynamic language bundle
set ARGS=%ARGS% -DDYNAMIC_LANGUAGE_BUNDLE="%parent%\data"

IF "%XIC_CLASS_PATH%" == "" (
  set X_CLASS_PATH=%parent%\lib\classes\commons-codec-1.6.jar;^
%parent%\lib\classes\jaxb-api-2.3.1.jar;^
%parent%\lib\classes\jaxb-core-2.3.0.1.jar;^
%parent%\lib\classes\jaxb-impl-2.3.1.jar;^
%parent%\lib\classes\json-simple-1.1.1.jar;^
%parent%\lib\classes\httpclient-4.2.5.jar;^
%parent%\lib\classes\httpcore-4.2.4.jar;^
%parent%\lib\classes\commons-logging-1.1.1.jar;^
%parent%\lib\classes\commons-cli-1.4.jar;^
%parent%\lib\classes\xinstaller.jar;^
%parent%\lib\classes\slf4j-api-1.7.32.jar;^
%parent%\lib\classes\logback-core-1.2.8.jar;^
%parent%\lib\classes\logback-classic-1.2.8.jar;^
%parent%\lib\classes\sevenzipjbinding-AllWindows.jar;^
%parent%\lib\classes\zip4j-2.2.1.jar
) ELSE (
  set X_CLASS_PATH=%XIC_CLASS_PATH%
)
IF NOT "%XIC_JRE_LOCATION%" == "" (
  set X_JAVA_HOME="%XIC_JRE_LOCATION%"
)
set ARGS=%ARGS%  -Dsun.java2d.d3d=false
IF "%DEBUG_JNI%" == "true" (
set ARGS=%ARGS%  -XX:+CheckJNICalls
)
set ARGS=%ARGS% -XX:HeapDumpPath="%userprofile%\.Xilinx\xinstall"
rem echo "X_JAVA_HOME: %X_JAVA_HOME%" >> c:\temp\app-debug.txt 
rem dir /d /S %parent% >> c:\temp\app-debug.txt
