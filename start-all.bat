@echo off
REM Start PDF Chatbot - Both Backend and Frontend
REM This script starts both services in separate windows

echo.
echo ==========================================
echo PDF Chatbot - Starting All Services
echo ==========================================
echo.

REM Start backend in new window
echo Starting Backend...
start "PDF Chatbot - Backend" cmd /k "%~dp0start-backend.bat"

REM Wait a bit for backend to start
timeout /t 3 /nobreak

REM Start frontend in new window
echo Starting Frontend...
start "PDF Chatbot - Frontend" cmd /k "%~dp0start-frontend.bat"

echo.
echo ==========================================
echo Services Started!
echo ==========================================
echo.
echo Backend:  http://localhost:8000
echo Frontend: http://localhost:3000  (or 3001 if 3000 is busy)
echo API Docs: http://localhost:8000/docs
echo.
echo Opening browser in 8 seconds...
timeout /t 8 /nobreak

REM Open browser (Vite may use 3001)
start "" http://localhost:3000
start "" http://localhost:3001

echo.
echo Tip: Keep both windows open to run the services
echo Close either window to stop that service
echo.
pause
