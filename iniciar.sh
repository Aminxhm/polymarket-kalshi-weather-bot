#!/bin/bash

echo "============================================================"
echo "    Iniciando Bot de Trading BTC 5-Min (macOS / Linux)      "
echo "============================================================"

# Ensure script halts on failures
set -e

echo "[1/4] Configurando Backend (Python)..."

if [ ! -d "venv" ]; then
    python3 -m venv venv
fi
source venv/bin/activate

echo "[2/4] Instalando dependencias del Backend..."
pip install -r requirements.txt > /dev/null

echo "[3/4] Instalando dependencias del Frontend..."
cd frontend
npm install > /dev/null
cd ..

echo "[4/4] Iniciando servidores..."
# Kill any processes running on the necessary ports to avoid conflicts
lsof -t -i :8000 | xargs kill -9 2>/dev/null || true
lsof -t -i :5173 | xargs kill -9 2>/dev/null || true

echo "-> Iniciando Backend (FastAPI) en http://localhost:8000"
python run.py &
BACKEND_PID=$!

echo "-> Iniciando Frontend (Vite) en http://localhost:5173"
cd frontend
npm run dev &
FRONTEND_PID=$!
cd ..

echo "============================================================"
echo " Sistema iniciado con éxito. Presiona Ctrl+C para detener.  "
echo " Backend URL: http://localhost:8000                         "
echo " Frontend URL: http://localhost:5173                        "
echo "============================================================"

# Set up trap to clean up background processes upon script termination
trap "echo 'Deteniendo servidores...'; kill $BACKEND_PID $FRONTEND_PID 2>/dev/null" SIGINT SIGTERM

# Wait for background processes to keep script running
wait $BACKEND_PID $FRONTEND_PID
