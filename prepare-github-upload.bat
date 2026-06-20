@echo off
REM Refresh pdf-chatbot-for-upload with CURRENT code (safe for GitHub)
REM Excludes: venv, node_modules, .env, secrets, local data

set SRC=%~dp0
set DST=%~dp0..\pdf-chatbot-for-upload

echo.
echo ==========================================
echo  Preparing GitHub upload folder
echo ==========================================
echo.
echo Source: %SRC%
echo Output: %DST%
echo.

if not exist "%DST%" mkdir "%DST%"

REM /MIR = mirror (dest matches source, removes old extra files)
REM /XD = exclude directories
REM /XF = exclude files

robocopy "%SRC%" "%DST%" /MIR /XD venv node_modules __pycache__ .git .pytest_cache htmlcov .vscode .idea dist build ^
  data backend\data backend\uploads backend\venv frontend\node_modules frontend\dist ^
  /XF .env .env.backup .env.local deploy-info.json ^
  /NFL /NDL /NJH /NJS /nc /ns /np

if %ERRORLEVEL% LEQ 7 (
    echo.
    echo SUCCESS - Upload folder ready:
    echo   %DST%
    echo.
    echo Upload EVERYTHING inside that folder to GitHub:
    echo   https://github.com/ishita0705/pdf-chatbot
    echo.
    echo DO NOT upload if you see these inside backend:
    echo   - .env  ^(secrets^)
    echo   - venv\
    echo.
    explorer "%DST%"
) else (
    echo Robocopy failed with code %ERRORLEVEL%
)

pause
