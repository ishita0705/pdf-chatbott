@echo off
REM Start PDF Chatbot Frontend
REM This script starts the React development server

cd /d "%~dp0frontend"

REM Check if node_modules exists
if not exist "node_modules" (
    echo Installing dependencies...
    call npm install
)

REM Start Vite dev server
echo.
echo ========================================
echo Starting PDF Chatbot Frontend...
echo ========================================
echo.
echo Frontend will be available at: http://localhost:5173
echo.

call npm run dev

pause
