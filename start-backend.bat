@echo off
REM Start PDF Chatbot Backend
REM This script activates the venv and starts the backend server

cd /d "%~dp0backend"

REM Activate virtual environment
call .\venv\Scripts\activate.bat

REM Start FastAPI server
echo.
echo ========================================
echo Starting PDF Chatbot Backend...
echo ========================================
echo.
echo API will be available at: http://localhost:8000
echo API Docs at: http://localhost:8000/docs
echo.

python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

pause
