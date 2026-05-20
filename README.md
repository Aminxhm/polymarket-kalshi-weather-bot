# Bot de Trading para Mercados de Predicción

Un bot de trading multi-estrategia que identifica ineficiencias de precios en mercados de predicción. Combina **análisis de microestructura de BTC en 5 minutos** con **pronósticos meteorológicos de conjunto** para operar en **Kalshi** y **Polymarket**. Cuenta con un panel profesional en React.

![Python](https://img.shields.io/badge/python-3.10+-blue) ![React](https://img.shields.io/badge/react-18+-61DAFB) ![TypeScript](https://img.shields.io/badge/typescript-5.0+-blue) ![License](https://img.shields.io/badge/license-MIT-green)

![Dashboard](docs/dashboard.png)

**100% gratis de ejecutar** - Sin APIs de pago, sin suscripciones. Todas las fuentes de datos son gratuitas. La clave API de Kalshi es opcional para los mercados de Kalshi.

## Descripción General

### Estrategia 1: BTC 5 Minutos Arriba/Abajo
Escanea los mercados Arriba/Abajo de 5 minutos de BTC de Polymarket cada 60 segundos. Utiliza datos de velas de 1 minuto en tiempo real de Coinbase/Kraken/Binance para calcular el RSI, momento, desviación VWAP, cruce de SMA y sesgo del mercado como una señal compuesta ponderada. Opera cuando la ventaja > 2%.

### Estrategia 2: Temperatura del Clima (Kalshi + Polymarket)
Escanea los mercados de temperatura del clima en **Kalshi** (serie KXHIGH) y **Polymarket** cada 5 minutos. Usa pronósticos de conjunto GFS de 31 miembros de Open-Meteo para estimar la probabilidad de que se superen los umbrales de temperatura. Opera cuando la ventaja > 8%. Los mercados de Kalshi se descubren automáticamente mediante los tickers de la serie `KXHIGHNY`, `KXHIGHCHI`, `KXHIGHMIA`, `KXHIGHLAX`, `KXHIGHDEN`.

### Características Clave

- **Análisis de Microestructura de BTC** - RSI, momento (1m/5m/15m), VWAP, cruce de SMA a partir de datos de velas reales
- **Pronósticos de Clima de Conjunto** - Conjunto GFS de 31 miembros de Open-Meteo para predicciones probabilísticas de temperatura
- **Trading Multi-Plataforma** - Opera en mercados climáticos tanto en Kalshi (serie KXHIGH) como en Polymarket simultáneamente
- **Detección de Ventaja** - Identifica mercados con precios incorrectos en ambas estrategias y plataformas
- **Tamaño de Posición según Criterio de Kelly** - Tamaño de posición fraccional de Kelly (15%) con límites por operación
- **Calibración de Señales** - Rastrea las predicciones frente a los resultados con la puntuación de Brier
- **Panel Profesional** - Panel en React de 3 columnas con actualizaciones en tiempo real
- **Modo Simulación** - Trading en papel con seguimiento de capital virtual y curvas de rendimiento (capital)

## Inicio Rápido

### 1. Configuración del Backend

```bash
cd kalshi-trading-bot

# Crear entorno virtual
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Instalar dependencias
pip install -r requirements.txt

# Ejecutar el backend
uvicorn backend.api.main:app --reload --port 8000
```

El backend estará en: http://localhost:8000
Documentación de la API en: http://localhost:8000/docs

### 2. Configuración del Frontend

```bash
cd frontend

# Instalar dependencias
npm install

# Ejecutar el frontend
npm run dev
```

El frontend estará en: http://localhost:5173

## Arquitectura

```
┌──────────────────────────────────────────────────────────────────┐
│                          FRONTEND                                │
│  React + TypeScript + TanStack Query + Tailwind                  │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐            │
│  │Indicators│ │ Weather  │ │ Signals  │ │  Trades  │            │
│  │  + Chart │ │  Panel   │ │  Table   │ │  Table   │            │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘            │
└──────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────────────┐
│                          BACKEND                                 │
│  FastAPI + Python + SQLite + APScheduler                         │
│  ┌───────────┐ ┌───────────┐ ┌───────────┐ ┌───────────┐        │
│  │  BTC      │ │ Weather   │ │  Signal   │ │Settlement │        │
│  │ Signals   │ │ Signals   │ │ Scheduler │ │  Engine   │        │
│  └───────────┘ └───────────┘ └───────────┘ └───────────┘        │
└──────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────────────┐
│                        DATA SOURCES                              │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌────────┐ │
│  │Coinbase/ │ │Open-Meteo│ │  NWS     │ │Polymarket│ │ Kalshi │ │
│  │Kraken/   │ │ Ensemble │ │  API     │ │Gamma API │ │  API   │ │
│  │Binance   │ │  (GFS)   │ │          │ │          │ │(KXHIGH)│ │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘ └────────┘ │
└──────────────────────────────────────────────────────────────────┘
```

## Cómo Funciona

### Estrategia BTC 5 Minutos
1. Obtener 60 velas de un minuto de Coinbase/Kraken/Binance (cadena de respaldo)
2. Calcular 5 indicadores: RSI(14), Momento(1m/5m/15m), desviación VWAP, cruce SMA, sesgo de mercado
3. Filtro de convergencia: requerir que más de 2 de 4 indicadores concuerden
4. Compuesto ponderado -> probabilidad del modelo ARRIBA (rango 0.35-0.65)
5. Comparar con los precios de Polymarket, operar del lado con mayor ventaja

### Estrategia de Temperatura del Clima
1. Obtener mercados climáticos abiertos de Kalshi (serie KXHIGH, autenticación RSA-PSS) y Polymarket (API Gamma)
2. Obtener pronósticos de conjunto GFS de 31 miembros de Open-Meteo
3. Contar la fracción de miembros por encima/debajo del umbral de temperatura del mercado
4. Esa fracción = probabilidad del modelo (ej., 28/31 miembros por encima de 70F = 90% de probabilidad)
5. Comparar con el precio del mercado en cualquier plataforma, operar cuando la ventaja > 8%
6. Confianza = acuerdo del conjunto (qué tan unánimes son los 31 miembros)

### Cálculo de la Ventaja (Edge)
```
edge = model_probability - market_probability
```
Las señales de BTC requieren |ventaja| > 2%. Las señales meteorológicas requieren |ventaja| > 8%.

### Tamaño de Posición (Kelly Fraccional)
```
kelly = (win_prob * odds - lose_prob) / odds
position_size = kelly * 0.15 * bankroll
```
Limitado al 5% del capital y $75 (BTC) o $100 (Clima) por operación.

## Endpoints de la API

| Endpoint | Método | Descripción |
|----------|--------|-------------|
| `/api/dashboard` | GET | Todos los datos del panel en una llamada |
| `/api/btc/price` | GET | Precio actual de BTC + momento |
| `/api/btc/windows` | GET | Ventanas activas de BTC de 5 minutos |
| `/api/signals` | GET | Señales comerciales actuales de BTC |
| `/api/signals/actionable` | GET | Señales de BTC por encima del umbral |
| `/api/kalshi/status` | GET | Estado de autenticación API Kalshi + saldo |
| `/api/weather/forecasts` | GET | Pronósticos de conjunto para todas las ciudades |
| `/api/weather/markets` | GET | Mercados del clima (Kalshi + Polymarket) |
| `/api/weather/signals` | GET | Señales comerciales del clima (ambas plataformas) |
| `/api/trades` | GET | Historial de operaciones |
| `/api/stats` | GET | Estadísticas del bot |
| `/api/calibration` | GET | Datos de calibración de la señal |
| `/api/run-scan` | POST | Activar el escaneo de BTC + clima |
| `/api/simulate-trade` | POST | Simular una operación BTC |
| `/api/settle-trades` | POST | Verificar las liquidaciones |
| `/api/bot/start` | POST | Iniciar trading |
| `/api/bot/stop` | POST | Pausar trading |
| `/api/bot/reset` | POST | Reiniciar todas las operaciones |
| `/api/events` | GET | Registro de eventos |
| `/ws/events` | WS | Flujo de eventos en tiempo real |

## Configuración

Todas las configuraciones están en `backend/config.py`, se pueden anular con variables de entorno:

### Configuraciones de BTC
| Configuración | Predeterminado | Descripción |
|---------------|----------------|-------------|
| `SCAN_INTERVAL_SECONDS` | 60 | Frecuencia del escaneo BTC |
| `MIN_EDGE_THRESHOLD` | 0.02 | Ventaja mínima (2%) |
| `MAX_ENTRY_PRICE` | 0.55 | Precio máximo de entrada (55c) |
| `MAX_TRADE_SIZE` | 75.0 | $ máximo por operación BTC |
| `KELLY_FRACTION` | 0.15 | Multiplicador de Kelly fraccional |

### Configuraciones de Kalshi
| Configuración | Predeterminado | Descripción |
|---------------|----------------|-------------|
| `KALSHI_API_KEY_ID` | None | ID de clave API Kalshi |
| `KALSHI_PRIVATE_KEY_PATH` | None | Ruta al archivo PEM de clave privada RSA |
| `KALSHI_ENABLED` | True | Activar/desactivar la obtención de mercados Kalshi |

### Configuraciones del Clima
| Configuración | Predeterminado | Descripción |
|---------------|----------------|-------------|
| `WEATHER_ENABLED` | True | Activar/desactivar el trading del clima |
| `WEATHER_SCAN_INTERVAL_SECONDS` | 300 | Frecuencia del escaneo del clima (5 min) |
| `WEATHER_MIN_EDGE_THRESHOLD` | 0.08 | Ventaja mínima (8%) |
| `WEATHER_MAX_ENTRY_PRICE` | 0.70 | Precio máximo de entrada (70c) |
| `WEATHER_MAX_TRADE_SIZE` | 100.0 | $ máximo por operación del clima |
| `WEATHER_CITIES` | nyc,chicago,miami,los_angeles,denver | Ciudades para seguir |

### Gestión de Riesgos
| Configuración | Predeterminado | Descripción |
|---------------|----------------|-------------|
| `DAILY_LOSS_LIMIT` | 300.0 | Límite diario de pérdidas |
| `MAX_TOTAL_PENDING_TRADES` | 20 | Máximas posiciones abiertas |
| `INITIAL_BANKROLL` | 10000.0 | Capital inicial para simulación |

## Ciudades Compatibles (Clima)

| Ciudad | Estación | Seguimiento |
|--------|----------|-------------|
| Nueva York | KNYC | Predeterminado |
| Chicago | KORD | Predeterminado |
| Miami | KMIA | Predeterminado |
| Los Ángeles | KLAX | Predeterminado |
| Denver | KDEN | Predeterminado |

Agrega más ciudades editando `WEATHER_CITIES` en la configuración y añadiendo entradas a `CITY_CONFIG` en `backend/data/weather.py`.

## Fuentes de Datos

| Fuente | Datos | Usado Para | Autenticación |
|--------|-------|------------|---------------|
| Coinbase | Velas de 1 min BTC | Microestructura BTC | Ninguna |
| Kraken | Velas de 1 min BTC | Respaldo BTC | Ninguna |
| Binance | Velas de 1 min BTC | Respaldo BTC | Ninguna |
| Open-Meteo | Conjunto GFS (31 miembros) | Probabilidad del Clima | Ninguna |
| NWS API | Temperaturas observadas | Liquidación del clima | Ninguna |
| Polymarket | Precios de mercado + resolución | Ambas estrategias | Ninguna |
| Kalshi | Mercados del clima (KXHIGH) | Estrategia de clima | Clave RSA |

## Estructura del Proyecto

```
kalshi-trading-bot/
├── backend/
│   ├── api/
│   │   └── main.py                 # FastAPI routes + dashboard
│   ├── core/
│   │   ├── signals.py              # BTC signal generation
│   │   ├── weather_signals.py      # Weather signal generation
│   │   ├── scheduler.py            # Background jobs (BTC + weather)
│   │   └── settlement.py           # Trade settlement (routes by market_type)
│   ├── data/
│   │   ├── btc_markets.py          # Polymarket BTC market fetcher
│   │   ├── crypto.py               # BTC price + microstructure
│   │   ├── kalshi_client.py        # Kalshi API client (RSA-PSS auth)
│   │   ├── kalshi_markets.py       # Kalshi weather market fetcher (KXHIGH)
│   │   ├── weather.py              # Open-Meteo ensemble + NWS observations
│   │   ├── weather_markets.py      # Polymarket weather market fetcher
│   │   └── markets.py              # Generic market wrapper
│   ├── models/
│   │   └── database.py             # SQLAlchemy models (market_type column)
│   └── config.py                   # All settings (BTC + weather)
├── frontend/
│   ├── src/
│   │   ├── components/
│   │   │   ├── GlobeView.tsx        # 3D globe with city markers
│   │   │   ├── EdgeDistribution.tsx # Edge distribution chart
│   │   │   ├── MicrostructurePanel.tsx # RSI gauge + indicator meters
│   │   │   ├── WeatherPanel.tsx     # Weather forecasts per city
│   │   │   ├── CalibrationPanel.tsx # Prediction accuracy tracking
│   │   │   ├── StatsCards.tsx       # Performance metrics
│   │   │   ├── SignalsTable.tsx     # BTC + Weather signals combined
│   │   │   ├── TradesTable.tsx      # Trade history
│   │   │   ├── EquityChart.tsx      # P&L chart
│   │   │   └── Terminal.tsx         # Event log + controls
│   │   ├── App.tsx                  # 3-column grid dashboard
│   │   ├── api.ts                   # API client
│   │   └── types.ts                 # TypeScript interfaces
│   └── package.json
├── requirements.txt
├── run.py
└── README.md
```

## Descargo de Responsabilidad

Esta es una **herramienta de simulación** con fines educativos. No realiza operaciones reales ni utiliza dinero real. El rendimiento pasado en la simulación no garantiza resultados futuros. Los mercados de predicción implican riesgo de pérdida.

## Licencia

MIT - haz lo que quieras con él.
