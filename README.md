<p align="center">
  <img src="blackswan.png" alt="BLACKSWAN NOVA" width="200" />
</p>

<h1 align="center">BLACKSWAN NOVA</h1>
<p align="center">
  <em>Where uncertainty is <strong>engineered</strong> into insight.</em>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Python-3.12+-3776AB?logo=python&logoColor=white" />
  <img src="https://img.shields.io/badge/FastAPI-0.100+-009688?logo=fastapi&logoColor=white" />
  <img src="https://img.shields.io/badge/Flutter-3.7+-02569B?logo=flutter&logoColor=white" />
  <img src="https://img.shields.io/badge/JavaScript-ES2022-F7DF1E?logo=javascript&logoColor=black" />
  <img src="https://img.shields.io/badge/Chart.js-4.x-FF6384?logo=chartdotjs&logoColor=white" />
  <img src="https://img.shields.io/badge/NumPy-SciPy-013243?logo=numpy&logoColor=white" />
</p>

---

## Overview

**BLACKSWAN NOVA** is a full-stack Monte Carlo risk simulation engine built for quantitative financial analysis. It models stochastic price dynamics across **960+ financial instruments** — spanning the S&P 500, NSE Indian Equities, Global Indices, Forex, and Commodities — using advanced stochastic models and delivers results through a premium dark-themed analytics dashboard.

The engine combines **Geometric Brownian Motion (GBM)**, **GARCH(1,1) volatility clustering**, **Merton Jump-Diffusion** for tail risk, and **Cornish-Fisher VaR expansion** to provide institutional-grade risk metrics that go beyond standard parametric methods.

---

## Features

### Simulation Engine
- **Monte Carlo Simulation** — Up to 10,000 paths with configurable investment horizons (1–10 years)
- **GARCH(1,1) Volatility** — Time-varying volatility with mean reversion (`α=0.09, β=0.90`)
- **Merton Jump-Diffusion** — Fat-tail modeling with Poisson-distributed jumps (`λ=4/252, μ_j=-0.08`)
- **Cornish-Fisher VaR** — Skewness & kurtosis-adjusted Value at Risk beyond Gaussian assumptions

### Risk Analytics
- **Value at Risk (VaR 95%)** — Parametric, Historical, and Cornish-Fisher methods
- **Conditional VaR (CVaR / Expected Shortfall)** — Tail-risk beyond VaR
- **Sharpe Ratio** — Risk-adjusted return analysis
- **P&L Distribution** — Server-side histogram with 60-bin resolution

### Portfolio & Stress Testing
- **Multi-Asset Portfolio Simulation** — Cholesky-decomposed correlated Brownian motion
- **t-Copula Dependency** — Tail-dependent correlation with `df=4` for realistic crash modeling
- **Historical Stress Tests** — 2008 GFC, 2020 COVID, and custom scenario overlays
- **Breakeven Horizon Analysis** — GARCH-powered recovery time estimation post-shock

### News Intelligence
- **Real-Time Feed** — Alpha Vantage + yFinance aggregation for global and Indian markets
- **Sentiment Scoring** — NLP-based Bullish/Bearish/Neutral classification
- **Top Ticker Tracking** — Sentiment-weighted ticker heatmap
- **Category Filters** — Markets, Earnings, Economy, Commodities, Forex

### Instrument Coverage (960+)
| Asset Class | Count | Examples |
|------------|-------|---------|
| US Stocks | ~500 | AAPL, MSFT, NVDA, TSLA |
| Indian Equities (NSE) | ~250 | RELIANCE, TCS, HDFC, INFY |
| Global Indices | ~30 | S&P 500, NIFTY 50, DAX, Nikkei |
| Forex Pairs | ~40 | EUR/USD, USD/INR, GBP/JPY |
| Commodities | ~50 | Gold, Crude Oil, Natural Gas |

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                   BLACKSWAN NOVA                        │
├──────────────┬──────────────────┬───────────────────────┤
│   Frontend   │    Backend       │    Mobile             │
│   (SPA)      │    (FastAPI)     │    (Flutter)          │
├──────────────┼──────────────────┼───────────────────────┤
│ index.html   │ /simulate        │ Dashboard Screen      │
│ intro.html   │ /stress          │ Simulation Screen     │
│ Chart.js     │ /portfolio       │ News Feed Screen      │
│ 960+ instr.  │ /news            │ fl_chart + shimmer    │
│ client-side  │ /news/sentiment  │ HTTP → FastAPI        │
│ GBM engine   │ NumPy + SciPy   │ Dark theme UI         │
└──────────────┴──────────────────┴───────────────────────┘
```

---

## Mathematical Models

### Geometric Brownian Motion (GBM)
```
S(t) = S(0) · exp[(μ − σ²/2)·t + σ · W(t)]
```
Where `W(t)` is a Wiener process, `μ` is drift, and `σ` is volatility.

### GARCH(1,1) Volatility
```
σ²(t) = ω + α · ε²(t−1) + β · σ²(t−1)
```
Captures volatility clustering observed in real financial markets.

### Merton Jump-Diffusion
```
dS/S = (μ − λ·μ_j)dt + σ·dW + J·dN(λ)
```
Adds Poisson-distributed jumps to model sudden market crashes (Black Swan events).

### Cornish-Fisher VaR Expansion
```
z_cf = z + (z²−1)·γ₁/6 + (z³−3z)·γ₂/24 − (2z³−5z)·γ₁²/36
VaR = −(μ + σ · z_cf)
```
Adjusts for non-Gaussian skewness and kurtosis in the P&L distribution.

---

## Quick Start

### Prerequisites
- Python 3.12+
- Node.js (optional, for development tooling)
- Flutter 3.7+ (for mobile companion app)

### 1. Clone & Setup
```bash
git clone https://github.com/RSinha05/Blackswan-Nova.git
cd Blackswan-Nova

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install backend dependencies
pip install -r backend/requirements.txt
```

### 2. Configure Environment
```bash
cp backend/.env.example backend/.env
# Edit backend/.env with your API keys
```

### 3. Launch the Engine
```bash
# Option A: One-click launch (macOS)
chmod +x START_ENGINE.command
./START_ENGINE.command

# Option B: Manual launch
cd backend && uvicorn main:app --port 8000 &
open intro.html
```

### 4. Flutter Mobile Companion (Optional)
```bash
cd blackswan_nova_app
flutter pub get
flutter run
```

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| **Frontend** | Vanilla HTML/CSS/JS, Chart.js 4.x, Supabase JS SDK |
| **Backend** | Python 3.12, FastAPI, NumPy, SciPy, httpx, yfinance |
| **Mobile** | Flutter 3.7, Dart, fl_chart, google_fonts, shimmer |
| **Data** | Supabase (PostgreSQL), Yahoo Finance, Alpha Vantage |
| **Design** | Inter + JetBrains Mono typography, Dark theme (#0d0f12) |

---

## Project Structure

```
├── index.html                  # Main SPA dashboard (3200+ lines)
├── intro.html                  # Cinematic landing page with GBM animation
├── blackswan.png               # Logo asset
├── START_ENGINE.command         # One-click launch script (macOS)
├── backend/
│   ├── main.py                 # FastAPI server — simulation, stress, portfolio, news
│   ├── requirements.txt        # Python dependencies
│   └── .env.example            # Environment template
├── blackswan_nova_app/         # Flutter mobile companion
│   ├── lib/
│   │   ├── main.dart
│   │   ├── screens/            # Dashboard, Simulation, News screens
│   │   └── services/           # API service layer
│   └── pubspec.yaml
├── generate_instruments.py     # Instrument data generator (S&P 500, NSE, Forex)
├── master_sync.py              # Supabase data synchronization
├── seed_supabase.py            # Database seeding script
└── BLACKSWAN_NOVA_Engine_Documentation.md
```

---

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/simulate` | Run Monte Carlo simulation with GARCH + Jump-Diffusion |
| `POST` | `/stress` | Stress test with volatility shock and recovery analysis |
| `POST` | `/portfolio` | Multi-asset portfolio simulation with t-Copula |
| `GET` | `/news` | Real-time financial news feed with sentiment |
| `GET` | `/news/sentiment-summary` | Aggregated market sentiment metrics |

---

## Design

The interface follows a **financial terminal aesthetic** inspired by Bloomberg Terminal and Refinitiv Eikon:
- **Primary Background**: Deep Black-Blue (`#0d0f12`)
- **Typography**: Inter (UI) + JetBrains Mono (Data/Numbers)
- **Accents**: Electric Green (`#1D9E75`) for paths, Amber (`#EF9F27`) for warnings, Red (`#D85A30`) for drawdowns
- **Animations**: CSS micro-animations, GBM path rendering on canvas

---

## License

MIT License — see [LICENSE](LICENSE) for details.

---

<p align="center">
  <sub>Built by <a href="https://github.com/RSinha05">Rishav Sinha</a> · BLACKSWAN NOVA © 2026</sub>
</p>
