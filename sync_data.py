import csv
import yfinance as yf

csv_path = 'QUANTRISK_Instruments_Financials.csv'

# Map internal IDs to Yahoo Finance tickers for major instruments
yf_mapping = {
    'sensex': '^BSESN',
    'nifty50': '^NSEI',
    'reliance': 'RELIANCE.NS',
    'aapl': 'AAPL',
    'msft': 'MSFT',
    'xauusd': 'GC=F',
    'xagusd': 'SI=F',
    'bankex': 'BSE-BANK.BO',
    'niftybank': '^NSEBANK'
}

print("Fetching latest prices from Yahoo Finance...")
latest_prices = {}
for inst_id, yf_ticker in yf_mapping.items():
    try:
        ticker_obj = yf.Ticker(yf_ticker)
        price = ticker_obj.fast_info.last_price
        latest_prices[inst_id] = round(price, 2)
        print(f"Fetched {yf_ticker}: {latest_prices[inst_id]}")
    except Exception as e:
        print(f"Failed to fetch {yf_ticker}: {e}")

# Read CSV and filter out the fake Indian Indices
print("Reading CSV and filtering out INDX0-9...")
rows = []
fieldnames = []
with open(csv_path, 'r', encoding='utf-8') as f:
    reader = csv.DictReader(f)
    fieldnames = reader.fieldnames
    for row in reader:
        # Filter out random Indian Indices
        if row['ID'].startswith('indx') and row['Asset Class'] == 'indian-index':
            continue
        
        # Update base price if we have it
        if row['ID'] in latest_prices:
            row['Base Price'] = f"{latest_prices[row['ID']]:.2f}"
            
        rows.append(row)

# Ensure new banking indices are in the CSV
existing_ids = {r['ID'] for r in rows}

if 'bankex' not in existing_ids:
    base_px = latest_prices.get('bankex', 63000.0)
    rows.insert(2, {
        'ID': 'bankex', 'Name': 'BSE BANKEX', 'Ticker': 'BSE-BANK.BO', 
        'Asset Class': 'indian-index', 'Annual Drift (mu)': '0.130', 
        'Annual Volatility (sig)': '0.200', 'Risk-Free Rate (rf)': '0.065', 
        'Base Price': f"{base_px:.2f}", 'Currency': '₹'
    })
    print("Appended BSE BANKEX to CSV data.")

if 'niftybank' not in existing_ids:
    base_px = latest_prices.get('niftybank', 56000.0)
    rows.insert(3, {
        'ID': 'niftybank', 'Name': 'NIFTY BANK', 'Ticker': '^NSEBANK', 
        'Asset Class': 'indian-index', 'Annual Drift (mu)': '0.125', 
        'Annual Volatility (sig)': '0.190', 'Risk-Free Rate (rf)': '0.065', 
        'Base Price': f"{base_px:.2f}", 'Currency': '₹'
    })
    print("Appended NIFTY BANK to CSV data.")

print(f"Writing {len(rows)} records back to {csv_path}...")
with open(csv_path, 'w', encoding='utf-8', newline='') as f:
    writer = csv.DictWriter(f, fieldnames=fieldnames)
    writer.writeheader()
    writer.writerows(rows)

print("Data synchronization complete.")
