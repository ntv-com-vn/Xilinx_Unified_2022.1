@ECHO OFF
@ECHO Running XiC in tray mode (non-elevated)
runas /trustlevel:0x20000 "%1%\xic.exe -t"