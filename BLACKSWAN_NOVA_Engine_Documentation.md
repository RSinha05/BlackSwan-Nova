# BLACKSWAN NOVA Financial Simulation Engine
**Architecture & Code Documentation**

## 1. File Structure Overview
All core functionality is bundled into a self-contained, dependency-light structure optimized for high performance, operating completely locally.
- **`index.html`**: The main interface, UI components (CSS), Simulation mathematical models (JavaScript), Chart.js rendering, and the core dataset of 960+ financial instruments.
- **`generate_instruments.py`**: A Python script designed to procedurally scrape and generate realistic financial inputs (drift $\mu$, volatility $\sigma$) from authentic lists of the S&P 500, NSE Equity markets, and Forex/Commodity pairs.
- **`QUANTRISK_Instruments_Financials.csv`**: A snapshot CSV containing the exact generated parameters (drift, volatility, risk-free rate, and base prices) currently fed into the engine's Monte Carlo loops.

## 2. Core Code Architecture (`index.html`)

### 2.1 Asset Database (`const INSTRUMENTS`)
The engine holds 962 assets in memory via an array of JSON objects. This approach enables instant client-side filtering and sorting without backend latency.
```javascript
{
  "id": "aapl",
  "name": "Apple",
  "ticker": "AAPL",
  "cls": "us-stock",
  "mu": 0.212,        // Annual Drift
  "sig": 0.295,       // Annual Volatility
  "rf": 0.045,        // Risk-Free Rate
  "base": 185.00,     // Current Price
  "ccy": "$"
}
```

### 2.2 Monte Carlo Simulation Engine (`runSimulation()`)
The stochastic model relies on **Geometric Brownian Motion (GBM)** to project future asset price paths over a selected time horizon.
```javascript
// GBM Formula: S(t) = S(0) * exp((μ - σ²/2)*t + σ * W(t))
const dailyMu = (mu - 0.5 * sig * sig) / 252;
const dailySig = sig / Math.sqrt(252);

for(let t=0; t<T; t++) {
  S *= Math.exp(dailyMu + dailySig * normRand()); // normRand generates N(0,1)
}
```
- **Inputs**: Drift ($\mu$), Volatility ($\sigma$), Horizon ($T$), Paths ($N$).
- **Outputs**: Value at Risk (VaR), Conditional VaR (CVaR / Expected Shortfall), Sharpe Ratio.

### 2.3 Portfolio Stress Testing (`applyStress()`)
Historical stress tests overlay historical crisis drawdowns (e.g., the 2008 GFC, 2020 COVID crash) onto the current portfolio value.
- Applies absolute index percentage drops to a user-defined portfolio amount to quantify exact worst-case scenario liquidations.

### 2.4 Pagination & Performance Routing
With the expansion to 962 instruments, DOM manipulation limits native performance. The engine features:
- **`renderRiskTable()` & `renderInstruments()`**: Both utilize a `slice(start, start + PAGE_SIZE)` logic to restrict active DOM rows to 50 items.
- **Dynamic Controls**: `changeRiskPage(delta)` handles Prev/Next UI updates asynchronously to keep the UI fluid.

## 3. Financial Mechanics
- **Value at Risk (Parametric & Historical)**: Calculates the maximum expected loss at a $95\%$ confidence interval.
- **Sharpe Ratio**: Evaluates risk-adjusted returns using $\frac{\mu - rf}{\sigma}$.
- **Cholesky Decomposition**: Future iterations map to use correlated Brownian motion for multi-asset portfolio simulations (foundations structured in `runPortfolioSim`).

## 4. Design Aesthetics
The frontend uses a high-end financial analyst design:
- **Primary Theme**: Deep Black-Blue (`#0B0F14`)
- **Typography**: Inter (UI Structure) & JetBrains Mono (Data/Numbers).
- **Accents**: Electric Blue (Paths), Soft Green (Gains), Muted Red (Drawdowns/Loss).
