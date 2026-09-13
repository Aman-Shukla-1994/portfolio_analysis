#!/bin/bash

# ============================================================
# STOCK TRANCHE CALCULATOR
# Usage: ./stock.sh SYMBOL
# Example: ./stock.sh BSE
#          ./stock.sh RPPINFRA
# ============================================================

set -u

if [ $# -eq 0 ]; then
    echo "Usage: ./stock.sh SYMBOL[,SYMBOL2,...]"
    exit 1
fi

if [ $# -gt 1 ] || [[ "$1" == *,* ]]; then
    for raw_arg in "$@"; do
        IFS=',' read -r -a PARTS <<< "$raw_arg"
        for part in "${PARTS[@]}"; do
            symbol=$(echo "$part" | xargs)
            if [ -n "$symbol" ]; then
                bash "$0" "$symbol"
            fi
        done
    done
    exit 0
fi

SYMBOL=$(echo "$1" | tr '[:lower:]' '[:upper:]')

print_symbol_banner() {
    local label="$1"
    local border
    border=$(printf '%*s' "$(( ${#label} + 12 ))" '' | tr ' ' '=')

    echo
    printf '\033[1;32m%s\033[0m\n' "$border"
    printf '\033[1;33m  %s  \033[0m\n' "$label"
    printf '\033[1;32m%s\033[0m\n\n' "$border"
}

print_symbol_banner "$SYMBOL"

# ============================================================
# WATCHLIST TRACKING ENGINE (ALL 22 INDICES MAPPED)
# ============================================================

# 1. CORE MARKET BENCHMARKS & VOLATILITY
if [ "$SYMBOL" = "NIFTY" ] || [ "$SYMBOL" = "NIFTY50" ]; then
    YAHOO="%5ENSEI"
    SYMBOL="NIFTY_50"
    NSE_INDEX="NIFTY 50"
elif [ "$SYMBOL" = "SENSEX" ]; then
    YAHOO="%5EBSESN"
    SYMBOL="SENSEX"
    NSE_INDEX=""
elif [ "$SYMBOL" = "NEXT50" ] || [ "$SYMBOL" = "NIFTYNEXT50" ]; then
    YAHOO="%5ENSMIDCP"
    SYMBOL="NIFTY_NEXT_50"
    NSE_INDEX="NIFTY NEXT 50"
elif [ "$SYMBOL" = "VIX" ] || [ "$SYMBOL" = "INDIAVIX" ]; then
    YAHOO="%5EINDIAVIX"
    SYMBOL="INDIA_VIX"
    NSE_INDEX="INDIA VIX"

# 2. SECTORAL BANKING & FINANCE
elif [ "$SYMBOL" = "BANKNIFTY" ] || [ "$SYMBOL" = "NIFTYBANK" ] || [ "$SYMBOL" = "BANK" ]; then
    YAHOO="%5ENSEBANK"
    SYMBOL="NIFTY_BANK"
    NSE_INDEX="NIFTY BANK"
elif [ "$SYMBOL" = "PSUBANK" ] || [ "$SYMBOL" = "NIFTYPSUBANK" ]; then
    YAHOO="%5ECNXPSUBANK"
    SYMBOL="NIFTY_PSU_BANK"
    NSE_INDEX="NIFTY PSU BANK"

# 3. CORE INDUSTRIAL & SECTORAL INDICES
elif [ "$SYMBOL" = "IT" ] || [ "$SYMBOL" = "NIFTYIT" ]; then
    YAHOO="%5ECNXIT"
    SYMBOL="NIFTY_IT"
    NSE_INDEX="NIFTY IT"
elif [ "$SYMBOL" = "AUTO" ] || [ "$SYMBOL" = "NIFTYAUTO" ]; then
    YAHOO="%5ECNXAUTO"
    SYMBOL="NIFTY_AUTO"
    NSE_INDEX="NIFTY AUTO"
elif [ "$SYMBOL" = "FMCG" ] || [ "$SYMBOL" = "NIFTYFMCG" ]; then
    YAHOO="%5ECNXFMCG"
    SYMBOL="NIFTY_FMCG"
    NSE_INDEX="NIFTY FMCG"
elif [ "$SYMBOL" = "PHARMA" ] || [ "$SYMBOL" = "NIFTYPHARMA" ]; then
    YAHOO="%5ECNXPHARMA"
    SYMBOL="NIFTY_PHARMA"
    NSE_INDEX="NIFTY PHARMA"
elif [ "$SYMBOL" = "NIFTYMETAL" ]; then
    YAHOO="%5ECNXMETAL"
    SYMBOL="NIFTY_METAL"
    NSE_INDEX="NIFTY METAL"
elif [ "$SYMBOL" = "REALTY" ] || [ "$SYMBOL" = "NIFTYREALTY" ]; then
    YAHOO="%5ECNXREALTY"
    SYMBOL="NIFTY_REALTY"
    NSE_INDEX="NIFTY REALTY"
elif [ "$SYMBOL" = "NIFTYENERGY" ]; then
    YAHOO="%5ECNXENERGY"
    SYMBOL="NIFTY_ENERGY"
    NSE_INDEX="NIFTY ENERGY"
elif [ "$SYMBOL" = "INFRA" ] || [ "$SYMBOL" = "NIFTYINFRA" ] || [ "$SYMBOL" = "NIFTYINFRASTRUCTURE" ] || [ "$SYMBOL" = "INFRASTRUCTURE" ]; then
    YAHOO="%5ECNXINFRA"
    SYMBOL="NIFTY_INFRASTRUCTURE"
    NSE_INDEX="NIFTY INFRASTRUCTURE"
elif [ "$SYMBOL" = "MEDIA" ] || [ "$SYMBOL" = "NIFTYMEDIA" ]; then
    YAHOO="%5ECNXMEDIA"
    SYMBOL="NIFTY_MEDIA"
    NSE_INDEX="NIFTY MEDIA"
elif [ "$SYMBOL" = "COMMODITIES" ] || [ "$SYMBOL" = "NIFTYCOMMODITIES" ]; then
    YAHOO="%5ECNXCMDT"
    SYMBOL="NIFTY_COMMODITIES"
    NSE_INDEX="NIFTY COMMODITIES"
elif [ "$SYMBOL" = "CONSUMPTION" ] || [ "$SYMBOL" = "NIFTYCONSUMPTION" ] || [ "$SYMBOL" = "NIFTYINDIACONSUMPTION" ] || [ "$SYMBOL" = "INDIACONSUMPTION" ]; then
    YAHOO="%5ECNXCONSUM"
    SYMBOL="NIFTY_INDIA_CONSUMPTION"
    NSE_INDEX="NIFTY INDIA CONSUMPTION"

# 4. BROAD MARKET MID & SMALL CAPS
elif [ "$SYMBOL" = "MIDCAP150" ] || [ "$SYMBOL" = "NIFTY_MIDCAP_150" ] || [ "$SYMBOL" = "NIFTYMIDCAP150" ] || [ "$SYMBOL" = "MIDCAP" ]; then
    YAHOO="NIFTYMIDCAP150.NS"
    SYMBOL="NIFTY_MIDCAP_150"
    NSE_INDEX="NIFTY MIDCAP 150"
#elif [ "$SYMBOL" = "SMLCAP100" ] || [ "$SYMBOL" = "NIFTY_SMLCAP_100" ]; then
#    YAHOO="%5ECNXSC"
#    SYMBOL="NIFTY_SMALLCAP_100"
elif [ "$SYMBOL" = "SMLCAP250" ] || [ "$SYMBOL" = "NIFTY_SMLCAP_250" ] || [ "$SYMBOL" = "NIFTYSMALLCAP250" ] || [ "$SYMBOL" = "SMALLCAP250" ] || [ "$SYMBOL" = "SMLCAP" ]; then
    YAHOO="NIFTYSMLCAP250.NS"
    SYMBOL="NIFTY_SMALLCAP_250"
    NSE_INDEX="NIFTY SMALLCAP 250"

# 5. USER MANUAL FALLBACK OVERRIDES
elif [[ "$SYMBOL" == *.* ]] || [[ "$SYMBOL" == ^* ]]; then
    NSE_INDEX=""
    YAHOO=$(python3 - "$SYMBOL" <<'PY'
import sys, urllib.parse
print(urllib.parse.quote(sys.argv[1], safe=''))
PY
)
else
    YAHOO="${SYMBOL}.NS"
    NSE_INDEX=""
fi

TMP_LONG=$(mktemp)
TMP_RECENT=$(mktemp)
TMP_NSE=$(mktemp)

cleanup() {
    rm -f "$TMP_LONG" "$TMP_RECENT" "$TMP_NSE"
}
trap cleanup EXIT


# ============================================================
# YAHOO DOWNLOAD FUNCTION
# ============================================================

download_yahoo() {
    local url="$1"
    local output="$2"

    curl -L -sS \
        --connect-timeout 15 \
        --max-time 60 \
        -A "Mozilla/5.0" \
        "$url" \
        -o "$output"
}


# ============================================================
# LONG HISTORY
# ============================================================

LONG_URL="https://query1.finance.yahoo.com/v8/finance/chart/${YAHOO}?range=10y&interval=1d&events=history&includeAdjustedClose=true"

if ! download_yahoo "$LONG_URL" "$TMP_LONG"; then
    echo
    echo "ERROR: Unable to download historical data."
    echo
    echo "Yahoo request failed for: $YAHOO"
    exit 1
fi

if [ ! -s "$TMP_LONG" ]; then
    echo
    echo "ERROR: Yahoo returned empty historical data."
    exit 1
fi


# ============================================================
# RECENT HISTORY
# ============================================================

RECENT_URL="https://query1.finance.yahoo.com/v8/finance/chart/${YAHOO}?range=10d&interval=1d&events=history&includeAdjustedClose=true"

if ! download_yahoo "$RECENT_URL" "$TMP_RECENT"; then
    echo
    echo "WARNING: Recent-data refresh failed."
    echo "Continuing with long historical data..."
    echo
    echo '{}' > "$TMP_RECENT"
fi

NSE_URL="https://www.nseindia.com/api/allIndices"
if ! curl -L -sS \
    --connect-timeout 15 \
    --max-time 60 \
    -A "Mozilla/5.0" \
    "$NSE_URL" \
    -o "$TMP_NSE"; then
    echo
    echo "WARNING: NSE allIndices fetch failed. Sector PE/PB will be unavailable."
    echo
    echo '{}' > "$TMP_NSE"
fi

# ============================================================
# PYTHON CALCULATIONS
# ============================================================

python3 - "$TMP_LONG" "$TMP_RECENT" "$TMP_NSE" "$SYMBOL" "$NSE_INDEX" "$YAHOO" <<'PY'

import sys
import json
import datetime
import calendar

long_file = sys.argv[1]
recent_file = sys.argv[2]
nse_file = sys.argv[3]
SYMBOL = sys.argv[4]
NSE_INDEX = sys.argv[5]
YAHOO = sys.argv[6]

# India timezone without requiring tzdata
IST = datetime.timezone(datetime.timedelta(hours=5, minutes=30))

today = datetime.datetime.now(IST).date()


# ============================================================
# LOAD YAHOO DATA
# ============================================================

def load_yahoo(filename):

    try:
        with open(filename, "r") as f:
            obj = json.load(f)
    except Exception:
        return {}, {}, {}, {}

    result = obj.get("chart", {}).get("result")

    if not result:
        return {}, {}, {}, {}

    result = result[0]
    meta = result.get("meta", {})

    timestamps = result.get("timestamp", [])

    quote = (
        result
        .get("indicators", {})
        .get("quote", [{}])[0]
    )

    closes = quote.get("close", [])
    highs = quote.get("high", [])
    lows = quote.get("low", [])

    out_close = {}
    out_high = {}
    out_low = {}

    for ts, close, high, low in zip(timestamps, closes, highs, lows):

        if close is None:
            continue

        try:
            date = datetime.datetime.fromtimestamp(
                ts,
                IST
            ).date()

            out_close[date] = float(close)
            if high is not None:
                out_high[date] = float(high)
            if low is not None:
                out_low[date] = float(low)

        except Exception:
            continue

    return out_close, out_high, out_low, meta


# ============================================================
# HELPERS
# ============================================================

def return_pct(current, previous):

    if previous is None or previous == 0:
        return None

    return (current / previous - 1) * 100


def fmt_pct(value):

    if value is None:
        return "N/A"

    return f"{value:+.2f}%"


def nearest_on_or_before(data, target):

    dates = [
        d for d in data
        if d <= target
    ]

    if not dates:
        return None, None

    d = max(dates)

    return d, data[d]


def trading_return(data, reference_date, reference_close, sessions):

    dates = sorted(
        d for d in data
        if d <= reference_date
    )

    if len(dates) <= sessions:
        return None

    old_date = dates[-(sessions + 1)]

    return return_pct(
        reference_close,
        data[old_date]
    )


# ============================================================
# LOAD + MERGE
# ============================================================

long_close, long_high, long_low, meta_long = load_yahoo(long_file)
recent_close, recent_high, recent_low, meta_recent = load_yahoo(recent_file)

try:
    with open(nse_file, "r") as f:
        nse_data = json.load(f).get("data", [])
except Exception:
    nse_data = []

nse_index = next(
    (item for item in nse_data if item.get("index") == NSE_INDEX),
    None
)

data = dict(long_close)
data.update(recent_close)

high_data = dict(long_high)
high_data.update(recent_high)

low_data = dict(long_low)
low_data.update(recent_low)

completed = sorted(
    d for d in data
    if d <= today
)

if not completed:

    print()
    print("ERROR: No completed trading-day data found.")
    sys.exit(1)


# ============================================================
# REFERENCE PRICE
# ============================================================

ref_date = completed[-1]
ref_close = data[ref_date]

age = (today - ref_date).days

if age > 7:

    print()
    print("ERROR: Historical data appears stale.")
    print(f"Latest available date: {ref_date}")
    print(f"Today: {today}")
    sys.exit(1)


# ============================================================
# 52 WEEK HIGH / LOW (INTRADAY)
# ============================================================

# Anchor the lookback to the latest market session used for all other metrics.
# Using today can omit valid sessions when the feed is delayed or markets are closed.
week52_start = ref_date - datetime.timedelta(days=365)

week52_lows = {
    d: c
    for d, c in low_data.items()
    if week52_start <= d <= ref_date
}

week52_highs = {
    d: c
    for d, c in high_data.items()
    if week52_start <= d <= ref_date
}

if not week52_lows or not week52_highs:

    print()
    print("ERROR: Insufficient 52-week data.")
    sys.exit(1)


low_date = min(
    week52_lows,
    key=week52_lows.get
)

high_date = max(
    week52_highs,
    key=week52_highs.get
)

low_52 = week52_lows[low_date]
high_52 = week52_highs[high_date]

if nse_index:
    official_low = nse_index.get("yearLow")
    official_high = nse_index.get("yearHigh")
    if official_low is not None and official_high is not None:
        low_52 = float(official_low)
        high_52 = float(official_high)
        low_date = "NSE official"
        high_date = "NSE official"


# ============================================================
# SHORT TERM
# ============================================================

ret_5d = trading_return(
    data,
    ref_date,
    ref_close,
    5
)

ret_10d = trading_return(
    data,
    ref_date,
    ref_close,
    10
)


# ============================================================
# CALENDAR RETURN
# ============================================================

def calendar_return(months=0, extra_days=0):

    month = ref_date.month - months
    year = ref_date.year

    while month <= 0:

        month += 12
        year -= 1

    day = min(
        ref_date.day,
        calendar.monthrange(year, month)[1]
    )

    target = datetime.date(
        year,
        month,
        day
    )

    target -= datetime.timedelta(
        days=extra_days
    )

    old_date, old_close = nearest_on_or_before(
        data,
        target
    )

    return return_pct(
        ref_close,
        old_close
    )


ret_1m = calendar_return(months=1)
ret_2m = calendar_return(months=2)
ret_3m = calendar_return(months=3)

# 4.5 months = 4 calendar months + 15 days
ret_45m = calendar_return(
    months=4,
    extra_days=15
)

ret_6m = calendar_return(months=6)
ret_9m = calendar_return(months=9)


# ============================================================
# YTD
# ============================================================

year_start = datetime.date(
    today.year,
    1,
    1
)

ytd_dates = sorted(
    d for d in data
    if year_start <= d <= ref_date
)

if ytd_dates:

    ytd_start_date = ytd_dates[0]
    ytd_start_close = data[ytd_start_date]

    ytd_return = return_pct(
        ref_close,
        ytd_start_close
    )

else:

    ytd_start_date = None
    ytd_start_close = None
    ytd_return = None


# ============================================================
# YEARLY RETURNS
# ============================================================

def yearly_return(years):

    months = round(years * 12)
    target_month_index = ref_date.year * 12 + ref_date.month - 1 - months
    year, month_index = divmod(target_month_index, 12)
    month = month_index + 1

    day = min(
        ref_date.day,
        calendar.monthrange(
            year,
            month
        )[1]
    )

    target = datetime.date(
        year,
        month,
        day
    )

    old_date, old_close = nearest_on_or_before(
        data,
        target
    )

    return return_pct(
        ref_close,
        old_close
    )


ret_1y = yearly_return(1)
ret_3y = yearly_return(3)
ret_5y = yearly_return(5)
ret_10y = yearly_return(10)
ret_15y = yearly_return(15)

if nse_index:
    official_1m = nse_index.get("perChange30d")
    official_1y = nse_index.get("perChange365d")
    if official_1m is not None:
        ret_1m = float(official_1m)
    if official_1y is not None:
        ret_1y = float(official_1y)


# ============================================================
# TREND CLASSIFICATION
# ============================================================

def short_trend(values):

    valid = [
        x for x in values
        if x is not None
    ]

    negatives = sum(
        x < 0 for x in valid
    )

    positives = sum(
        x > 0 for x in valid
    )

    if negatives >= 2 and positives == 0:
        return "BEARISH MOMENTUM"

    if positives >= 2 and negatives == 0:
        return "BULLISH MOMENTUM"

    return "MIXED"


def medium_long_trend(values):

    valid = [
        x for x in values
        if x is not None
    ]

    negatives = sum(
        x < 0 for x in valid
    )

    positives = sum(
        x > 0 for x in valid
    )

    if negatives >= 4 and positives == 0:
        return "STRONG BEARISH"

    if negatives >= 3 and positives <= 1:
        return "BEARISH"

    if positives >= 4 and negatives == 0:
        return "STRONG BULLISH"

    if positives >= 3 and negatives <= 1:
        return "BULLISH"

    return "MIXED"


short_trend = short_trend([
    ret_5d,
    ret_10d
])

medium_trend = medium_long_trend([
    ret_1m,
    ret_3m,
    ret_45m,
    ret_6m,
    ret_9m
])

long_trend = medium_long_trend([
    ret_1y,
    ret_3y,
    ret_5y,
    ret_10y,
    ret_15y
])

# ============================================================
# OVERALL ACTION
# ============================================================

bearish_count = sum([
    short_trend == "BEARISH MOMENTUM",
    medium_trend in ["STRONG BEARISH", "BEARISH"],
    long_trend in ["STRONG BEARISH", "BEARISH"]
])

bullish_count = sum([
    short_trend == "BULLISH MOMENTUM",
    medium_trend in ["STRONG BULLISH", "BULLISH"],
    long_trend in ["STRONG BULLISH", "BULLISH"]
])

if bearish_count >= 2 and bullish_count == 0:

    if (
        short_trend == "BEARISH MOMENTUM"
        and medium_trend == "STRONG BEARISH"
    ):
        action = "WAIT - STRONG DOWNTREND"
    else:
        action = "WAIT - DOWNTREND"

elif bullish_count >= 2 and bearish_count == 0:

    action = "ACCUMULATE - UPTREND"

elif bullish_count > bearish_count:

    action = "CAUTIOUS ACCUMULATION"

elif bearish_count > bullish_count:

    action = "CAUTION - BEARISH BIAS"

else:

    action = "MIXED - WAIT"

# ============================================================
# TRANCHE LEVELS
# ============================================================

T0 = low_52
T4 = high_52

step = (T4 - T0) / 4

T1 = T0 + step
T2 = T0 + step * 2
T3 = T0 + step * 3

def tranche_position(price):

    if price <= T0:
        return "L"

    if price < T1:
        return "L-T1"

    if price < T3:
        return "M-T2"

    if price < T4:
        return "T2-H"

    return "H"

current_tranche = tranche_position(
    ref_close
)

# Support / resistance zones built on the same 52-week tranche model.
strong_support = T1
support_zone_low = T0
support_zone_high = T1

strong_resistance = T3
resistance_zone_low = T3
resistance_zone_high = T4

buy_zone_low = support_zone_low
buy_zone_high = strong_support
sell_zone_low = strong_resistance
sell_zone_high = resistance_zone_high

from_low = return_pct(
    ref_close,
    low_52
)

from_high = return_pct(
    ref_close,
    high_52
)

# ============================================================
# FETCH FUNDAMENTALS
# ============================================================

def compute_peg_from_summary(pe_value, profit_rows):
    try:
        pe = float(pe_value)
    except (TypeError, ValueError):
        return None

    if pe <= 0:
        return None

    profits = []
    for row in profit_rows or []:
        try:
            profit = float(row.get("profit"))
        except (TypeError, ValueError):
            continue
        if profit is not None:
            profits.append(profit)

    if len(profits) < 2:
        return None

    first_profit = profits[0]
    last_profit = profits[-1]
    if first_profit <= 0 or last_profit <= 0:
        return None

    periods = len(profits) - 1
    if periods <= 0:
        return None

    cagr = (last_profit / first_profit) ** (1.0 / periods) - 1.0
    if cagr <= 0:
        return None

    return pe / (cagr * 100.0)


fund_data = {
    "sector": "N/A",
    "marketCap": "N/A",
    "marketCapType": "N/A",
    "peRatio": "N/A",
    "pegRatio": "N/A",
    "pbRatio": "N/A",
    "divYield": "N/A"
}

INDEX_SECTOR_MAP = {
    "NIFTY 50": "Large Cap",
    "NIFTY NEXT 50": "Large Cap",
    "NIFTY BANK": "Financial Services",
    "NIFTY PSU BANK": "Financial Services",
    "NIFTY IT": "Information Technology",
    "NIFTY AUTO": "Automobile",
    "NIFTY FMCG": "Consumer Defensive",
    "NIFTY PHARMA": "Healthcare",
    "NIFTY METAL": "Basic Materials",
    "NIFTY REALTY": "Real Estate",
    "NIFTY ENERGY": "Energy",
    "NIFTY INFRA": "Industrials",
    "NIFTY MEDIA": "Communication Services",
    "NIFTY COMMODITIES": "Commodities",
    "NIFTY CONSUMPTION": "Consumer Cyclical",
    "NIFTY INDIA CONSUMPTION": "Consumer Cyclical",
    "NIFTY INFRA": "Industrials",
    "NIFTY INFRASTRUCTURE": "Industrials",
    "NIFTY MIDCAP 150": "Mid Cap",
    "NIFTY SMALLCAP 250": "Small Cap",
    "INDIA VIX": "Volatility"
}

import urllib.request
import urllib.error

# ── 1. TickerTape: stock-level PE, PB, DivYield, ROE (primary) ──
try:
    ticker = YAHOO.replace('.NS', '').replace('.BO', '')
    tt_search_url = f"https://api.tickertape.in/search?text={ticker}"
    req_tt1 = urllib.request.Request(tt_search_url, headers={'User-Agent': 'Mozilla/5.0'})
    resp_tt1 = urllib.request.urlopen(req_tt1, timeout=5)
    tt_search_data = json.loads(resp_tt1.read().decode('utf-8'))
    stocks = tt_search_data.get("data", {}).get("stocks", [])
    sid = None
    for s in stocks:
        if s.get("ticker") == ticker:
            sid = s.get("sid")
            break
    if not sid and stocks:
        sid = stocks[0].get("sid")

    if sid:
        tt_info_url = f"https://api.tickertape.in/stocks/info/{sid}"
        req_tt2 = urllib.request.Request(tt_info_url, headers={'User-Agent': 'Mozilla/5.0'})
        resp_tt2 = urllib.request.urlopen(req_tt2, timeout=5)
        tt_info = json.loads(resp_tt2.read().decode('utf-8'))
        ratios  = tt_info.get("data", {}).get("ratios", {})
        tt_info_data = tt_info.get("data", {}).get("info", {})

        tt_sector = tt_info.get("data", {}).get("gic", {}).get("sector", "")
        if tt_sector:
            fund_data["sector"] = tt_sector

        mc_val = ratios.get("marketCap")       # in Crores
        if mc_val:
            fund_data["marketCap"] = f"{mc_val:,.0f} Cr"
            if mc_val > 80000:
                fund_data["marketCapType"] = "Large Cap"
            elif mc_val > 25000:
                fund_data["marketCapType"] = "Mid Cap"
            else:
                fund_data["marketCapType"] = "Small Cap"

        pe_val = ratios.get("pe")
        if pe_val:
            fund_data["peRatio"] = f"{pe_val:.2f}"

        summary_url = f"https://api.tickertape.in/stocks/summary/{sid}"
        req_summary = urllib.request.Request(summary_url, headers={'User-Agent': 'Mozilla/5.0'})
        resp_summary = urllib.request.urlopen(req_summary, timeout=5)
        summary_data = json.loads(resp_summary.read().decode('utf-8'))
        profit_rows = summary_data.get("data", {}).get("financialSummary", {}).get("fiscalYearToData", [])
        calc_peg = compute_peg_from_summary(fund_data["peRatio"], profit_rows)
        if calc_peg is not None:
            fund_data["pegRatio"] = f"{calc_peg:.2f}"

        peg_val = ratios.get("peg")
        if peg_val is None:
            peg_val = ratios.get("pegRatio")
        if peg_val is None:
            peg_val = ratios.get("trailingPegRatio")
        if peg_val is None:
            peg_val = ratios.get("ttmPeg")
        if peg_val not in (None, "") and fund_data["pegRatio"] == "N/A":
            try:
                fund_data["pegRatio"] = f"{float(peg_val):.2f}"
            except (TypeError, ValueError):
                pass

        pb_val = ratios.get("pb")
        if pb_val:
            fund_data["pbRatio"] = f"{pb_val:.2f}"

        dy_val = ratios.get("divYield")
        if dy_val is not None:
            fund_data["divYield"] = f"{dy_val:.2f}%"

        roe_val = ratios.get("roe")
        if roe_val is not None:
            fund_data["roe"] = f"{roe_val:.2f}%"

except Exception:
    # ── Fallback: Yahoo Finance ──
    try:
        req1 = urllib.request.Request('https://fc.yahoo.com/', headers={'User-Agent': 'Mozilla/5.0'})
        cookie = ''
        try:
            urllib.request.urlopen(req1, timeout=5)
        except urllib.error.HTTPError as e:
            cookie = e.headers.get('Set-Cookie')

        if cookie:
            req2 = urllib.request.Request('https://query1.finance.yahoo.com/v1/test/getcrumb', headers={'User-Agent': 'Mozilla/5.0', 'Cookie': cookie})
            crumb = urllib.request.urlopen(req2, timeout=5).read().decode('utf-8')

            qs_url = f"https://query1.finance.yahoo.com/v10/finance/quoteSummary/{YAHOO}?modules=summaryProfile,summaryDetail,financialData,defaultKeyStatistics&crumb={crumb}"
            req3 = urllib.request.Request(qs_url, headers={'User-Agent': 'Mozilla/5.0', 'Cookie': cookie})
            resp3 = urllib.request.urlopen(req3, timeout=10)
            qs_data = json.loads(resp3.read().decode('utf-8'))

            result = qs_data.get("quoteSummary", {}).get("result", [])
            if result:
                res = result[0]
                fund_data["sector"] = res.get("summaryProfile", {}).get("sector", "N/A")

                mc = res.get("summaryDetail", {}).get("marketCap", {})
                mc_val = mc.get("raw")
                if mc_val:
                    fund_data["marketCap"] = f"{mc_val / 10000000:,.0f} Cr"
                    if mc_val > 800000000000:
                        fund_data["marketCapType"] = "Large Cap"
                    elif mc_val > 250000000000:
                        fund_data["marketCapType"] = "Mid Cap"
                    else:
                        fund_data["marketCapType"] = "Small Cap"

                pe = res.get("summaryDetail", {}).get("trailingPE", {})
                fund_data["peRatio"] = pe.get("fmt", "N/A")

                peg = res.get("defaultKeyStatistics", {}).get("pegRatio", {})
                peg_value = peg.get("fmt") or peg.get("raw")
                if peg_value not in (None, ""):
                    try:
                        fund_data["pegRatio"] = f"{float(peg_value):.2f}"
                    except (TypeError, ValueError):
                        pass

                pb = res.get("defaultKeyStatistics", {}).get("priceToBook", {})
                fund_data["pbRatio"] = pb.get("fmt", "N/A")

                dy = res.get("summaryDetail", {}).get("dividendYield", {})
                fund_data["divYield"] = dy.get("fmt", "N/A")

                roe = res.get("financialData", {}).get("returnOnEquity", {})
                fund_data["roe"] = roe.get("fmt", "N/A")
    except Exception:
        pass

# ── 2. NSE allIndices: official PE, PB, Div Yield, and index sector labels ──
SECTOR_INDEX_MAP = {
    "Technology":             "NIFTY IT",
    "Information Technology": "NIFTY IT",
    "Financial Services":     "NIFTY FINANCIAL SERVICES",
    "Healthcare":             "NIFTY HEALTHCARE INDEX",
    "Pharmaceutical":         "NIFTY PHARMA",
    "Basic Materials":        "NIFTY METAL",
    "Consumer Cyclical":      "NIFTY CONSUMER DURABLES",
    "Consumer Defensive":     "NIFTY FMCG",
    "Consumer Staples":       "NIFTY FMCG",
    "Industrials":            "NIFTY INFRASTRUCTURE",
    "Energy":                 "NIFTY ENERGY",
    "Utilities":              "NIFTY ENERGY",
    "Communication Services": "NIFTY MEDIA",
    "Real Estate":            "NIFTY REALTY",
    "Automobile":             "NIFTY AUTO",
}

if nse_index:
    index_name = nse_index.get("index")
    if index_name:
        fund_data["sector"] = INDEX_SECTOR_MAP.get(index_name, fund_data["sector"])
        if fund_data["marketCapType"] == "N/A":
            fund_data["marketCapType"] = "Index"

    nse_pe = nse_index.get("pe")
    nse_pb = nse_index.get("pb")
    nse_dy = nse_index.get("dy")
    if nse_pe not in (None, "", "N/A"):
        try:
            fund_data["peRatio"] = f"{float(nse_pe):.2f}"
        except ValueError:
            pass
    if nse_pb not in (None, "", "N/A"):
        try:
            fund_data["pbRatio"] = f"{float(nse_pb):.2f}"
        except ValueError:
            pass
    if nse_dy not in (None, "", "N/A"):
        try:
            fund_data["divYield"] = f"{float(nse_dy):.2f}%"
        except ValueError:
            pass

# Sector-level PE/PB/dividend fields removed intentionally. The dashboard and output now
# use only the direct stock-level values from Tickertape or Yahoo fallback.

# ============================================================
# OUTPUT
# ============================================================

print("=================================================")
if nse_index:
    print("      INDEX DETAILS & FUNDAMENTALS")
else:
    print("        STOCK DETAILS & FUNDAMENTALS")
print("=================================================")
print(f"LTP             : Rs. {ref_close:.2f}")
print(f"LTP date        : {ref_date}")
print(f"Mode            : {'INDEX' if nse_index else 'STOCK'}")
print(f"Sector          : {fund_data['sector']}")
print(f"MarketType      : {fund_data['marketCapType']}")
print(f"PE              : {fund_data['peRatio']}")
print(f"PEG             : {fund_data['pegRatio']}")
print(f"PB              : {fund_data['pbRatio']}")
print(f"DivYield        : {fund_data['divYield']}")
print()
print("=================================================")
print("             ABSOLUTE RETURNS")
print("=================================================")
print(f"1W Return       : {fmt_pct(ret_5d)}")
print(f"1M Return       : {fmt_pct(ret_1m)}")
print(f"3M Return       : {fmt_pct(ret_3m)}")
print(f"6M Return       : {fmt_pct(ret_6m)}")
print(f"YTD Return      : {fmt_pct(ytd_return)}")
print(f"1Y Return       : {fmt_pct(ret_1y)}")
print(f"3Y Return       : {fmt_pct(ret_3y)}")
print(f"5Y Return       : {fmt_pct(ret_5y)}")
print()
print("=================================================")
print("             52 WEEK RANGE")
print("=================================================")
print(f"52WH            : Rs. {high_52:.2f}")
print(f"52WH %-chg      : {fmt_pct(from_high)}")
print(f"52WH Date       : {high_date}")
print(f"52WL            : Rs. {low_52:.2f}")
print(f"52WL %-chg      : {fmt_pct(from_low)}")
print(f"52WL Date       : {low_date}")

PY
