import os
import csv
from supabase import create_client, Client

# --- SUPABASE CREDENTIALS ---
# Replace these with your actual Supabase Project URL and Anon Key
url: str = "https://pnjfbhgztzjkuhowbayu.supabase.co"
key: str = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBuamZiaGd6dHpqa3Vob3diYXl1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY5NTk2NjUsImV4cCI6MjA5MjUzNTY2NX0.ZgDU6wkgBu5oQu8CYvCzpxIGXQMc6qG3v39RKFeNsQg"

try:
    supabase: Client = create_client(url, key)
except Exception as e:
    print(f"Error initializing Supabase client. Make sure 'supabase' is installed (pip install supabase). Error: {e}")
    exit(1)

csv_path = 'QUANTRISK_Instruments_Financials.csv'

if not os.path.exists(csv_path):
    print(f"Error: Could not find {csv_path}. Please run this script from the project folder.")
    exit(1)

print("Reading CSV data...")
instruments = []

# Map CSV columns to Supabase table columns
# Make sure your Supabase table 'instruments' has these exact columns
with open(csv_path, 'r', encoding='utf-8') as f:
    reader = csv.DictReader(f)
    for row in reader:
        try:
            instruments.append({
                "id": row['ID'],
                "name": row['Name'],
                "ticker": row['Ticker'],
                "cls": row['Asset Class'],
                "mu": float(row['Annual Drift (mu)']),
                "sig": float(row['Annual Volatility (sig)']),
                "rf": float(row['Risk-Free Rate (rf)']),
                "base": float(row['Base Price']),
                "ccy": row['Currency']
            })
        except ValueError as e:
            print(f"Error parsing row {row['Ticker']}: {e}")

total = len(instruments)
print(f"Found {total} instruments to insert.")

if url == "YOUR_SUPABASE_URL":
    print("\n[!] IMPORTANT: You must edit this file and enter your Supabase URL and Key before running.")
    exit(1)

# Supabase allows bulk inserts. We'll chunk it just to be safe.
chunk_size = 100
print(f"Inserting into Supabase in chunks of {chunk_size}...")

success_count = 0

for i in range(0, total, chunk_size):
    chunk = instruments[i:i + chunk_size]
    try:
        response = supabase.table('instruments').upsert(chunk).execute()
        success_count += len(chunk)
        print(f"Inserted {success_count}/{total}...")
    except Exception as e:
        print(f"Error inserting chunk starting at index {i}: {e}")

print(f"\nDone! Successfully seeded {success_count} instruments into your Supabase database.")
print("You can now refresh index.html in your browser to see the live data fetch in action.")
