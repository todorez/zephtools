@echo off
SETLOCAL ENABLEDELAYEDEXPANSION
set FLASH_ROOT_DIR=%~dp0
set FLASH_ROOT=%FLASH_ROOT_DIR:~0,-1%
set OPENOCD=%FLASH_ROOT%\openocd\bin\openocd.exe

set ROM=0
set SS=0
set GDBSERVER=0
set BOARD=
set JTAG=

if [%1]==[] goto USAGE

:ARG_PARSE_LOOP
set CURRENT_ARG=%1
set CURRENT_ARG_FIRST_CHAR=%CURRENT_ARG:~0,1%
IF "!CURRENT_ARG_FIRST_CHAR!"=="-" (
    IF "%1"=="-b" (
        set BOARD=%2
        SHIFT
    )
    IF "%1"=="-r" (
        set ROM=1
    )
	IF "%1"=="-c" (
        set SS=1
    )
	IF "%1"=="-d" (
        set GDBSERVER=1
    )
    SHIFT
    goto ARG_PARSE_LOOP
)

IF "%BOARD%"=="" goto USAGE

IF "%BOARD%"=="arduino_101" (
    set SOC=quark_se
    set JTAG=flyswatter2
) ELSE IF "%BOARD%"=="ctb" (
    set SOC=quark_se
    set JTAG=ftdi
) ELSE (
    echo UNSUPPORTED BOARD, PLEASE ADD IT TO THE SCRIPT
    goto EOF
)

IF "%SOC%"=="quark_se" (
    IF "%SS%" == "1" (
        set LOAD_ADDR=0x40000000
    ) ELSE (
        set LOAD_ADDR=0x40030000
    )
    IF "%ROM%" == "1" (
        set LOAD_ADDR=0xffffe000
    )
)

set IMAGE=%1
echo IMAGE = %IMAGE%
REM Need to escape the path string's backslashes
set IMAGE=%IMAGE:\=\\%

echo Flashing using %JTAG%

IF "%GDBSERVER%"=="1" (
	@echo on
	%OPENOCD% -s outdir\ -s %FLASH_ROOT%\openocd\scripts -f %FLASH_ROOT%\openocd\scripts\interface\ftdi\%JTAG%.cfg -f %FLASH_ROOT%\openocd\scripts\%SOC%.cfg -f %FLASH_ROOT%\openocd\scripts\debug.cfg
	@echo off

) ELSE (
	IF "%IMAGE%"=="" goto USAGE
	REM Now set up the boards
	@echo on
	%OPENOCD% -s outdir\ -s %FLASH_ROOT%\openocd\scripts -f %FLASH_ROOT%\openocd\scripts\interface\ftdi\%JTAG%.cfg -f %FLASH_ROOT%\openocd\scripts\%SOC%.cfg -c "load_image   %IMAGE% %LOAD_ADDR%" -c "verify_image   %IMAGE% %LOAD_ADDR%" -f %FLASH_ROOT%\openocd\scripts\%SOC%-release.cfg
	@echo off
)

goto EOF

:USAGE
echo zephflash -b board [-r] image_name
echo.
echo -b is a board.  arduino_101 is supported.
echo -c flash to ARC core
echo -d debug
echo -r Flash ROM bootloader  ... optional flag
echo.
goto EOF

:EOF
