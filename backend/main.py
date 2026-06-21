from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import numpy as np
from scipy.stats import skew, kurtosis, t, norm
from typing import List, Dict, Any, Optional
import httpx
import os
import asyncio
from datetime import datetime, timezone
from dotenv import load_dotenv
import yfinance as yf

load_dotenv()

app = FastAPI(title="BLACKSWAN NOVA Backend Engine")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class SimRequest(BaseModel):
    S0: float
    mu: float
    sigma: float
    H: int
    N: int
    inv: float
    asset_class: str = "stock"

class StressRequest(BaseModel):
    S0: float
    mu: float
    sigma: float
    shock_pct: float
    vol_shock_factor: float = 2.0

class PortfolioAsset(BaseModel):
    id: str
    weight: float
    mu: float
    sigma: float
    cls: str

class PortfolioRequest(BaseModel):
    assets: List[PortfolioAsset]
    inv: float
    N: int = 5000

def _run_simulation(req_dict: dict) -> dict:
    """CPU-bound simulation — runs in a thread pool to keep the event loop free."""
    S0 = req_dict["S0"]
    mu = req_dict["mu"]
    sigma = req_dict["sigma"]
    H = req_dict["H"]
    N = min(req_dict["N"], 10000)  # Cap at 10k to avoid OOM on free-tier
    inv = req_dict["inv"]
    asset_class = req_dict["asset_class"]

    T = H * 252
    
    # ── Pre-generate ALL random numbers in bulk ──
    Z = np.random.randn(N, T)
    
    # GARCH(1,1) Parameters
    alpha = 0.09
    beta = 0.90
    long_term_var = (sigma**2) / 252
    omega = long_term_var * (1 - alpha - beta)
    
    # Merton Jump-Diffusion Parameters
    if 'stock' in asset_class or 'index' in asset_class:
        lambda_j = 4.0 / 252
        mu_j = -0.08
        sigma_j = 0.06
        # Pre-generate all jump data in bulk
        all_jumps = np.random.poisson(lambda_j, (N, T))
        all_jump_normals = np.random.normal(mu_j, sigma_j, (N, T))
    else:
        lambda_j = 0
    
    # ── Only store full paths for render subset (200 paths) ──
    n_render = min(200, N)
    render_idx = np.sort(np.random.choice(N, n_render, replace=False))
    render_mask = np.zeros(N, dtype=bool)
    render_mask[render_idx] = True
    
    # Track: cumulative log-returns for ALL paths (single float per path)
    # Full time-series only for render paths
    cum_log_ret = np.zeros(N)
    render_paths = np.zeros((n_render, T + 1))
    render_paths[:, 0] = S0
    
    sigma_sq = np.full(N, long_term_var)
    mu_daily = mu / 252
    
    for t in range(T):
        sigma_t = np.sqrt(sigma_sq)
        diffusion = (mu_daily - 0.5 * sigma_sq) + sigma_t * Z[:, t]
        
        if lambda_j > 0:
            jump_sizes = all_jump_normals[:, t] * all_jumps[:, t]
        else:
            jump_sizes = 0
            
        log_ret = diffusion + jump_sizes
        cum_log_ret += log_ret
        
        # Update render paths only
        render_paths[:, t + 1] = render_paths[:, t] * np.exp(log_ret[render_mask])
        
        # GARCH Update
        epsilon = log_ret - mu_daily
        sigma_sq = omega + alpha * (epsilon**2) + beta * sigma_sq

    # ── Terminal values for ALL paths ──
    finals = S0 * np.exp(cum_log_ret)
    
    pnl = (finals / S0 - 1.0) * inv
    pnl_sorted = np.sort(pnl)
    
    var_idx = int(0.05 * N)
    var95 = float(-pnl_sorted[var_idx])
    cvar95 = float(-np.mean(pnl_sorted[:var_idx]))
    expected_return = float(np.mean(pnl))
    
    # Cornish-Fisher Expansion
    mean_pnl = float(np.mean(pnl))
    std_pnl = float(np.std(pnl))
    gamma1 = float(skew(pnl))
    gamma2 = float(kurtosis(pnl, fisher=True))
    
    z = -1.645
    cf_z = z + (z**2 - 1)*gamma1/6 + (z**3 - 3*z)*gamma2/24 - (2*z**3 - 5*z)*(gamma1**2)/36
    cf_var95 = float(-(mean_pnl + std_pnl * cf_z))
    
    # ── Downsample render paths in TIME dimension ──
    # Cap at 250 data points per path to keep JSON small
    max_points = 250
    if T + 1 > max_points:
        step = T // (max_points - 1)
        sample_indices = list(range(0, T + 1, step))
        if sample_indices[-1] != T:
            sample_indices.append(T)
        downsampled = render_paths[:, sample_indices].tolist()
    else:
        downsampled = render_paths.tolist()
    
    # ── Compute histogram server-side ──
    hist_bins = 60
    counts, edges = np.histogram(pnl, bins=hist_bins)
    bin_centers = ((edges[:-1] + edges[1:]) / 2).tolist()
    
    return {
        "paths": downsampled,
        "var95": var95,
        "cvar95": cvar95,
        "cf_var95": cf_var95,
        "expected_return": expected_return,
        "best_path": float(np.max(pnl)),
        "worst_path": float(np.min(pnl)),
        "mean_pnl": mean_pnl,
        "pnl_hist": {"counts": counts.tolist(), "centers": bin_centers},
        "pnl": pnl.tolist(),
    }

@app.get("/")
async def root():
    return {"message": "BLACKSWAN NOVA Backend Engine is running.", "status": "ok"}

@app.get("/health")
async def health():
    return {"status": "ok"}

@app.post("/simulate")
async def simulate(req: SimRequest):
    loop = asyncio.get_event_loop()
    result = await loop.run_in_executor(
        None, _run_simulation, req.model_dump()
    )
    return result

@app.post("/stress")
def stress_test(req: StressRequest):
    # 1. Apply shock to t=0
    S_shocked = req.S0 * (1 - req.shock_pct)
    
    # 2. Run GBM forward to find breakeven horizon
    # We will simulate 3 years max to see if it recovers
    H_max = 3
    T = H_max * 252
    N = 2000
    
    paths = np.zeros((N, T+1))
    paths[:, 0] = S_shocked
    
    # Shock volatility (GARCH will mean-revert it)
    alpha = 0.09
    beta = 0.90
    long_term_var = (req.sigma**2) / 252
    omega = long_term_var * (1 - alpha - beta)
    
    shocked_var = ((req.sigma * req.vol_shock_factor)**2) / 252
    sigma_sq = np.full(N, shocked_var)
    
    Z = np.random.randn(N, T)
    
    recovery_days = np.full(N, -1)
    
    for t in range(1, T+1):
        sigma_t = np.sqrt(sigma_sq)
        diffusion = (req.mu/252 - 0.5 * sigma_sq) + sigma_t * Z[:, t-1]
        paths[:, t] = paths[:, t-1] * np.exp(diffusion)
        
        # Check recovery
        recovered = (paths[:, t] >= req.S0) & (recovery_days == -1)
        recovery_days[recovered] = t
        
        epsilon = diffusion - (req.mu/252)
        sigma_sq = omega + alpha * (epsilon**2) + beta * sigma_sq

    # Expected days to recover
    recovered_paths = recovery_days[recovery_days != -1]
    if len(recovered_paths) > 0:
        expected_recovery_days = float(np.mean(recovered_paths))
    else:
        expected_recovery_days = -1 # Did not recover within 3 years
        
    return {
        "shocked_price": S_shocked,
        "recovery_days": expected_recovery_days,
        "recovery_months": expected_recovery_days / 21 if expected_recovery_days != -1 else -1,
        "prob_recovery_3yr": len(recovered_paths) / N
    }

@app.post("/portfolio")
def portfolio_sim(req: PortfolioRequest):
    # Similar vectorization for portfolio
    T = 252
    N = req.N
    
    # Simple correlation model
    assets = req.assets
    n_assets = len(assets)
    
    # Build correlation matrix
    C = np.eye(n_assets)
    for i in range(n_assets):
        for j in range(i+1, n_assets):
            corr = 0.75 if assets[i].cls == assets[j].cls else 0.3
            C[i,j] = C[j,i] = corr
            
    L = np.linalg.cholesky(C)
    
    total_w = sum(a.weight for a in assets)
    
    pnl = np.zeros(N)
    
    # t-Copula with degrees of freedom = 4 to capture tail dependence
    df = 4
    Z = np.random.randn(N, n_assets)
    correlated_Z = Z @ L.T
    
    W = np.random.chisquare(df, size=(N, 1))
    T_dist = correlated_Z * np.sqrt(df / W)
    U = t.cdf(T_dist, df=df)
    Z_copula = norm.ppf(U)
    
    for i, a in enumerate(assets):
        w = a.weight / total_w
        mu = a.mu
        sig = a.sigma
        
        # Terminal price under GBM using t-Copula uniform transforms
        S_T = np.exp((mu - 0.5 * sig**2) + sig * Z_copula[:, i])
        pnl += w * (S_T - 1) * req.inv
        
    pnl_sorted = np.sort(pnl)
    var_idx = int(0.05 * N)
    var95 = -pnl_sorted[var_idx]
    
    return {
        "var95": var95,
        "pnl": pnl.tolist()
    }

# ── NEWS INTELLIGENCE ─────────────────────────────────────────────────────────

AV_KEY = os.getenv("ALPHA_VANTAGE_KEY", "demo")
AV_KEY2 = os.getenv("ALPHA_VANTAGE_KEY2", "demo")  # India-focused AV key
ND_KEY = os.getenv("NEWSDATA_KEY", "demo")

# In-memory cache to respect rate limits
_news_cache = {"data": None, "ts": 0}
CACHE_TTL = 300  # 5 minutes

def _parse_av_sentiment(score: float) -> str:
    if score >= 0.15:
        return "Bullish"
    elif score <= -0.15:
        return "Bearish"
    return "Neutral"

def _time_ago(dt_str: str) -> str:
    try:
        dt = datetime.strptime(dt_str[:15], "%Y%m%dT%H%M%S").replace(tzinfo=timezone.utc)
        delta = datetime.now(timezone.utc) - dt
        mins = int(delta.total_seconds() / 60)
        if mins < 60:
            return f"{mins}m ago"
        hrs = mins // 60
        if hrs < 24:
            return f"{hrs}h ago"
        return f"{hrs // 24}d ago"
    except:
        return ""

def _time_ago_iso(dt_str: str) -> str:
    try:
        dt = datetime.fromisoformat(dt_str.replace("Z", "+00:00"))
        delta = datetime.now(timezone.utc) - dt
        mins = int(delta.total_seconds() / 60)
        if mins < 60:
            return f"{mins}m ago"
        hrs = mins // 60
        if hrs < 24:
            return f"{hrs}h ago"
        return f"{hrs // 24}d ago"
    except:
        return ""

async def _fetch_alpha_vantage(topic: str = "") -> list:
    params = {
        "function": "NEWS_SENTIMENT",
        "apikey": AV_KEY,
        "sort": "LATEST",
        "limit": 50,
    }
    if topic:
        params["tickers"] = topic
    
    try:
        async with httpx.AsyncClient(timeout=15) as client:
            r = await client.get("https://www.alphavantage.co/query", params=params)
            data = r.json()
        
        if "feed" not in data:
            return []
        
        articles = []
        for item in data["feed"]:
            score = float(item.get("overall_sentiment_score", 0))
            tickers = [t["ticker"] for t in item.get("ticker_sentiment", [])[:5]]
            
            # Determine category from topics
            topics = [t.get("topic", "") for t in item.get("topics", [])]
            category = "Markets"
            for tp in topics:
                if "earning" in tp.lower():
                    category = "Earnings"
                    break
                elif "economy" in tp.lower() or "fiscal" in tp.lower() or "monetary" in tp.lower():
                    category = "Economy"
                    break
                elif "energy" in tp.lower() or "metal" in tp.lower() or "mineral" in tp.lower():
                    category = "Commodities"
                    break
                elif "forex" in tp.lower() or "fx" in tp.lower():
                    category = "Forex"
                    break
            
            articles.append({
                "title": item.get("title", ""),
                "summary": item.get("summary", "")[:200],
                "url": item.get("url", ""),
                "source": item.get("source", "Unknown"),
                "published": item.get("time_published", ""),
                "time_ago": _time_ago(item.get("time_published", "")),
                "sentiment_score": round(score, 3),
                "sentiment_label": _parse_av_sentiment(score),
                "tickers": tickers,
                "category": category,
                "region": "global",
                "banner_image": item.get("banner_image", ""),
            })
        return articles
    except Exception as e:
        print(f"Alpha Vantage error: {e}")
        return []
async def _fetch_india_news(topic: str = "") -> list:
    """Fetch Indian news using yfinance for top NSE tickers."""
    # India-specific sentiment keywords
    BEARISH_WORDS = [
        "crash", "fall", "drop", "loss", "decline", "bear", "risk", "fear",
        "sell", "plunge", "slump", "weak", "pressure", "downgrade", "deficit",
        "inflation", "hike rates", "slowdown", "recession", "rupee falls",
        "npa", "default", "fraud", "scam", "penalty", "probe", "fii outflow"
    ]
    BULLISH_WORDS = [
        "surge", "rally", "gain", "rise", "bull", "growth", "boost", "profit",
        "soar", "record", "high", "upgrade", "buy", "fii inflow", "gdp growth",
        "rbi cut", "rate cut", "ipo", "listing gains", "dividend", "buyback",
        "expansion", "deal", "acquisition", "order win", "outperform"
    ]

    def _score_sentiment(title: str, description: str) -> float:
        text = (title + " " + description).lower()
        score = 0.0
        for w in BEARISH_WORDS:
            if w in text:
                score -= 0.12
        for w in BULLISH_WORDS:
            if w in text:
                score += 0.12
        return round(max(-0.6, min(0.6, score)), 3)

    # Core NSE tickers to poll for news
    TICKERS = ["RELIANCE.NS", "TCS.NS", "HDFCBANK.NS", "INFY.NS", "ICICIBANK.NS", "SBIN.NS"]

    try:
        # Run yfinance blocking calls in executor
        loop = asyncio.get_event_loop()
        articles = []
        seen_titles = set()

        def fetch_ticker_news(symbol):
            try:
                return yf.Ticker(symbol).news
            except Exception:
                return []

        tasks = [loop.run_in_executor(None, fetch_ticker_news, t) for t in TICKERS]
        results = await asyncio.gather(*tasks)

        for symbol, news_list in zip(TICKERS, results):
            for item in news_list:
                content = item.get("content", {})
                if not content:
                    continue
                
                title = content.get("title") or ""
                title_key = title[:60].lower().strip()
                if title_key in seen_titles or not title_key:
                    continue
                seen_titles.add(title_key)

                description = content.get("summary") or content.get("description") or ""
                score = _score_sentiment(title, description)
                pub = content.get("pubDate", "")

                articles.append({
                    "title": title,
                    "summary": description[:220],
                    "url": (content.get("clickThroughUrl") or {}).get("url") or (content.get("canonicalUrl") or {}).get("url", ""),
                    "source": content.get("provider", {}).get("displayName", "India News"),
                    "published": pub,
                    "time_ago": _time_ago_iso(pub),
                    "sentiment_score": score,
                    "sentiment_label": _parse_av_sentiment(score),
                    "tickers": [symbol.split(".")[0]],
                    "category": "Markets",
                    "region": "india",
                    "banner_image": (content.get("thumbnail") or {}).get("resolutions", [{}])[0].get("url", ""),
                })

        # Sort combined results by published date
        articles.sort(key=lambda x: x["published"], reverse=True)
        return articles

    except Exception as e:
        print(f"yfinance India news error: {e}")
        return []

@app.get("/news")
async def get_news(region: str = "all", topic: str = "", limit: int = 30):
    global _news_cache
    now = datetime.now(timezone.utc).timestamp()
    
    # Check cache
    cache_key = f"{region}:{topic}"
    if _news_cache["data"] is not None and (now - _news_cache["ts"]) < CACHE_TTL and _news_cache.get("key") == cache_key:
        return {"articles": _news_cache["data"][:limit], "cached": True}
    
    # Fetch from sources in parallel
    tasks = []
    if region in ("all", "global"):
        tasks.append(_fetch_alpha_vantage(topic))
    if region in ("all", "india"):
        tasks.append(_fetch_india_news(topic))
    
    results = await asyncio.gather(*tasks)
    all_articles = []
    for r in results:
        all_articles.extend(r)
    
    # Deduplicate by title similarity (simple)
    seen_titles = set()
    unique = []
    for a in all_articles:
        key = a["title"][:50].lower()
        if key not in seen_titles:
            seen_titles.add(key)
            unique.append(a)
    
    # Sort by published time (newest first)
    unique.sort(key=lambda x: x["published"], reverse=True)
    
    # Cache
    _news_cache = {"data": unique, "ts": now, "key": cache_key}
    
    return {"articles": unique[:limit], "cached": False}

@app.get("/news/sentiment-summary")
async def news_sentiment_summary():
    # Use cached data if available
    news = await get_news(region="all", limit=50)
    articles = news["articles"]
    
    if not articles:
        return {
            "bullish_pct": 0, "bearish_pct": 0, "neutral_pct": 100,
            "avg_score": 0, "article_count": 0, "top_tickers": []
        }
    
    n = len(articles)
    bullish = sum(1 for a in articles if a["sentiment_label"] == "Bullish")
    bearish = sum(1 for a in articles if a["sentiment_label"] == "Bearish")
    neutral = n - bullish - bearish
    avg_score = sum(a["sentiment_score"] for a in articles) / n
    
    # Top tickers
    ticker_data = {}
    for a in articles:
        for t in a["tickers"]:
            if t not in ticker_data:
                ticker_data[t] = {"scores": [], "count": 0}
            ticker_data[t]["scores"].append(a["sentiment_score"])
            ticker_data[t]["count"] += 1
    
    top_tickers = sorted(ticker_data.items(), key=lambda x: x[1]["count"], reverse=True)[:8]
    top_tickers = [
        {"ticker": t, "sentiment": round(sum(d["scores"])/len(d["scores"]), 3), "count": d["count"]}
        for t, d in top_tickers
    ]
    
    return {
        "bullish_pct": round(bullish / n * 100, 1),
        "bearish_pct": round(bearish / n * 100, 1),
        "neutral_pct": round(neutral / n * 100, 1),
        "avg_score": round(avg_score, 3),
        "article_count": n,
        "top_tickers": top_tickers
    }
