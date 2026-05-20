@echo off
echo ============================================================
echo     Iniciando Bot de Trading BTC 5-Min (Windows)
echo ============================================================

echo [1/4] Configurando Backend (Python)...
if not exist venv\Scripts\activate.bat (
    python -m virtualenv venv
)

call venv\Scripts\activate.bat

echo [2/4] Instalando dependencias del Backend...
pip install -r requirements.txt > nul

echo [3/4] Instalando dependencias del Frontend...
cd frontend
call npm install > nul
cd ..

echo [4/4] Iniciando servidores...
echo -^> Iniciando Backend (FastAPI) en http://localhost:8000
start "BTC Bot Backend" cmd /c "venv\Scripts\activate.bat && python run.py"

echo -^> Iniciando Frontend (Vite) en http://localhost:5173
cd frontend
start "BTC Bot Frontend" cmd /c "npm run dev"
cd ..

echo ============================================================
echo  Sistema iniciado con éxito.
echo  Cierra las ventanas que se han abierto para detener los servidores.
echo  Backend URL: http://localhost:8000
echo  Frontend URL: http://localhost:5173
echo ============================================================
