import json
import random
import re
import urllib.request

random.seed(42)

# --- Fetch US Stocks ---
try:
    url = 'https://raw.githubusercontent.com/datasets/s-and-p-500-companies/master/data/constituents.csv'
    req = urllib.request.urlopen(url)
    sp500_data = req.read().decode('utf-8').splitlines()[1:]
    us_stocks = []
    for line in sp500_data:
        parts = line.split(',')
        if len(parts) >= 2:
            us_stocks.append({'ticker': parts[0].strip(), 'name': parts[1].strip()})
    random.shuffle(us_stocks)
except Exception as e:
    print('Failed to fetch S&P 500:', e)
    us_stocks = [{'ticker': f'US{i}', 'name': f'US Company {i}'} for i in range(1000)]

# --- Fetch Indian Stocks ---
try:
    req1 = urllib.request.Request('https://archives.nseindia.com/content/indices/ind_nifty100list.csv', headers={'User-Agent': 'Mozilla/5.0'})
    req2 = urllib.request.Request('https://archives.nseindia.com/content/indices/ind_niftymidcap150list.csv', headers={'User-Agent': 'Mozilla/5.0'})
    
    in_stocks = []
    for req in [req1, req2]:
        res = urllib.request.urlopen(req)
        nse_data = res.read().decode('utf-8').splitlines()[1:]
        for line in nse_data:
            parts = line.split(',')
            if len(parts) >= 3:
                in_stocks.append({'ticker': f"{parts[2].strip()}.NS", 'name': parts[0].strip()})
except Exception as e:
    print('Failed to fetch NSE:', e)
    in_stocks = [{'ticker': f'IN{i}', 'name': f'IN Company {i}'} for i in range(250)]

# --- Global Indices ---
global_indices = [
    {"name": "S&P 500", "ticker": "^GSPC"},
    {"name": "Dow Jones", "ticker": "^DJI"},
    {"name": "Nikkei 225", "ticker": "^N225"},
    {"name": "DAX", "ticker": "^GDAXI"},
    {"name": "CAC 40", "ticker": "^FCHI"},
    {"name": "KOSPI", "ticker": "^KS11"},
    {"name": "FTSE 100", "ticker": "^FTSE"},
    {"name": "Hang Seng", "ticker": "^HSI"}
]

# --- Commodities ---
commodities = [
    {"name": "Crude Oil (WTI)", "ticker": "CL=F"}, {"name": "Brent Crude", "ticker": "BZ=F"},
    {"name": "Natural Gas", "ticker": "NG=F"}, {"name": "Heating Oil", "ticker": "HO=F"},
    {"name": "RBOB Gas", "ticker": "RB=F"}, {"name": "Gold", "ticker": "GC=F"},
    {"name": "Silver", "ticker": "SI=F"}, {"name": "Copper", "ticker": "HG=F"},
    {"name": "Platinum", "ticker": "PL=F"}, {"name": "Palladium", "ticker": "PA=F"},
    {"name": "Corn", "ticker": "ZC=F"}, {"name": "Soybeans", "ticker": "ZS=F"},
    {"name": "Wheat", "ticker": "ZW=F"}, {"name": "Rough Rice", "ticker": "ZR=F"},
    {"name": "Oats", "ticker": "ZO=F"}, {"name": "Live Cattle", "ticker": "LE=F"},
    {"name": "Feeder Cattle", "ticker": "GF=F"}, {"name": "Lean Hogs", "ticker": "HE=F"},
    {"name": "Cocoa", "ticker": "CC=F"}, {"name": "Coffee", "ticker": "KC=F"},
    {"name": "Cotton", "ticker": "CT=F"}, {"name": "Sugar", "ticker": "SB=F"},
    {"name": "Lumber", "ticker": "LBS=F"}, {"name": "Orange Juice", "ticker": "OJ=F"},
    {"name": "Uranium", "ticker": "UX=F"}
]

# --- Forex Pairs ---
forex_pairs = [
    {"name": "EUR/USD", "ticker": "EURUSD"}, {"name": "USD/JPY", "ticker": "USDJPY"},
    {"name": "GBP/USD", "ticker": "GBPUSD"}, {"name": "USD/CHF", "ticker": "USDCHF"},
    {"name": "AUD/USD", "ticker": "AUDUSD"}, {"name": "USD/CAD", "ticker": "USDCAD"},
    {"name": "NZD/USD", "ticker": "NZDUSD"}, {"name": "EUR/GBP", "ticker": "EURGBP"},
    {"name": "EUR/JPY", "ticker": "EURJPY"}, {"name": "GBP/JPY", "ticker": "GBPJPY"},
    {"name": "CHF/JPY", "ticker": "CHFJPY"}, {"name": "EUR/CHF", "ticker": "EURCHF"},
    {"name": "AUD/JPY", "ticker": "AUDJPY"}, {"name": "AUD/NZD", "ticker": "AUDNZD"},
    {"name": "USD/INR", "ticker": "USDINR"}, {"name": "EUR/INR", "ticker": "EURINR"},
    {"name": "GBP/INR", "ticker": "GBPINR"}, {"name": "JPY/INR", "ticker": "JPYINR"},
    {"name": "USD/CNY", "ticker": "USDCNY"}, {"name": "USD/ZAR", "ticker": "USDZAR"},
    {"name": "USD/TRY", "ticker": "USDTRY"}, {"name": "USD/MXN", "ticker": "USDMXN"},
    {"name": "USD/BRL", "ticker": "USDBRL"}, {"name": "USD/RUB", "ticker": "USDRUB"},
    {"name": "USD/KRW", "ticker": "USDKRW"}, {"name": "USD/SGD", "ticker": "USDSGD"},
    {"name": "USD/HKD", "ticker": "USDHKD"}, {"name": "USD/SEK", "ticker": "USDSEK"},
    {"name": "USD/NOK", "ticker": "USDNOK"}, {"name": "USD/DKK", "ticker": "USDDKK"},
    {"name": "EUR/AUD", "ticker": "EURAUD"}, {"name": "EUR/CAD", "ticker": "EURCAD"},
    {"name": "EUR/NZD", "ticker": "EURNZD"}, {"name": "GBP/CHF", "ticker": "GBPCHF"},
    {"name": "GBP/AUD", "ticker": "GBPAUD"}, {"name": "GBP/CAD", "ticker": "GBPCAD"},
    {"name": "GBP/NZD", "ticker": "GBPNZD"}, {"name": "AUD/CHF", "ticker": "AUDCHF"},
    {"name": "AUD/CAD", "ticker": "AUDCAD"}, {"name": "CAD/CHF", "ticker": "CADCHF"},
    {"name": "CAD/JPY", "ticker": "CADJPY"}, {"name": "NZD/JPY", "ticker": "NZDJPY"},
    {"name": "NZD/CHF", "ticker": "NZDCHF"}, {"name": "NZD/CAD", "ticker": "NZDCAD"},
    {"name": "SGD/JPY", "ticker": "SGDJPY"}, {"name": "HKD/JPY", "ticker": "HKDJPY"},
    {"name": "ZAR/JPY", "ticker": "ZARJPY"}, {"name": "TRY/JPY", "ticker": "TRYJPY"}
]

instruments = []

# Hardcoded base instruments
hardcoded = [
  {"id":'sensex',"name":'BSE SENSEX',"ticker":'SENSEX',"cls":'indian-index',"mu":0.127,"sig":0.185,"rf":0.065,"base":72500,"ccy":'₹'},
  {"id":'nifty50',"name":'NIFTY 50',"ticker":'NIFTY50',"cls":'indian-index',"mu":0.125,"sig":0.183,"rf":0.065,"base":22500,"ccy":'₹'},
  {"id":'reliance',"name":'Reliance Ind',"ticker":'RELIANCE',"cls":'indian-stock',"mu":0.145,"sig":0.262,"rf":0.065,"base":2950,"ccy":'₹'},
  {"id":'aapl',"name":'Apple',"ticker":'AAPL',"cls":'us-stock',"mu":0.212,"sig":0.295,"rf":0.045,"base":185,"ccy":'$'},
  {"id":'msft',"name":'Microsoft',"ticker":'MSFT',"cls":'us-stock',"mu":0.198,"sig":0.278,"rf":0.045,"base":425,"ccy":'$'},
  {"id":'xauusd',"name":'Gold (XAU/USD)',"ticker":'XAU/USD',"cls":'forex',"mu":0.082,"sig":0.145,"rf":0.045,"base":2350,"ccy":'$'},
  {"id":'xagusd',"name":'Silver (XAG/USD)',"ticker":'XAG/USD',"cls":'forex',"mu":0.075,"sig":0.228,"rf":0.045,"base":28.5,"ccy":'$'},
  {"id":'bankex',"name":'BSE BANKEX',"ticker":'BSE-BANK.BO',"cls":'indian-index',"mu":0.130,"sig":0.200,"rf":0.065,"base":63000,"ccy":'₹'},
  {"id":'niftybank',"name":'NIFTY BANK',"ticker":'^NSEBANK',"cls":'indian-index',"mu":0.125,"sig":0.190,"rf":0.065,"base":56000,"ccy":'₹'}
]
instruments.extend(hardcoded)

def add_inst(cls, source_list, count, mu_range, sig_range, rf, base_range, ccy):
    for i in range(count):
        if i < len(source_list):
            item = source_list[i]
            ticker = item['ticker']
            name = item['name']
        else:
            ticker = f"UNK{i}"
            name = f"Unknown {i}"
        
        instruments.append({
            "id": ticker.lower().replace('/','').replace('=','').replace('^',''),
            "name": name,
            "ticker": ticker,
            "cls": cls,
            "mu": round(random.uniform(*mu_range), 3),
            "sig": round(random.uniform(*sig_range), 3),
            "rf": rf,
            "base": round(random.uniform(*base_range), 2),
            "ccy": ccy
        })

# Note: counts slightly reduced to fit what we have available, total still ~1000
add_inst('indian-stock', in_stocks, min(349, len(in_stocks)), (0.08, 0.22), (0.18, 0.55), 0.065, (100, 10000), '₹')
add_inst('global-index', global_indices, len(global_indices), (0.05, 0.15), (0.12, 0.25), 0.045, (3000, 40000), '$')
add_inst('us-stock', us_stocks, min(598, len(us_stocks)), (0.08, 0.35), (0.18, 0.65), 0.045, (10, 1000), '$')
add_inst('forex', forex_pairs, len(forex_pairs), (-0.05, 0.08), (0.04, 0.15), 0.045, (0.5, 150), '$')
add_inst('commodity', commodities, len(commodities), (0.03, 0.12), (0.12, 0.45), 0.045, (50, 5000), '$')

js_content = "const INSTRUMENTS = [\n"
for inst in instruments:
    js_content += "  " + json.dumps(inst, ensure_ascii=False) + ",\n"
js_content += "];"

file_path = "/Users/rishavsinha/Downloads/Risk_MonteCarlo 2/index.html"
with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

new_content, count = re.subn(r'(?:let|const) INSTRUMENTS\s*=\s*\[.*?\];', js_content, content, flags=re.DOTALL)
print(f"Replaced {count} instances of INSTRUMENTS array.")
print(f"Total instruments injected: {len(instruments)}")

with open(file_path, "w", encoding="utf-8") as f:
    f.write(new_content)
