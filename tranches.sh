#!/bin/bash

# ============================================================
# STOCK TRANCHE CALCULATOR
# Usage: ./tranches.sh SYMBOL
# Example: ./tranches.sh BSE
#          ./tranches.sh RPPINFRA
# ============================================================

set -u

if [ $# -ne 1 ]; then
    echo "Usage: ./tranches.sh SYMBOL"
    exit 1
fi

SYMBOL=$(echo "$1" | tr '[:lower:]' '[:upper:]')

# ============================================================
# WATCHLIST TRACKING ENGINE (ALL 18 INDICES MAPPED)
# ============================================================

# 1. CORE MARKET BENCHMARKS & VOLATILITY
if [ "$SYMBOL" = "NIFTY" ] || [ "$SYMBOL" = "NIFTY50" ]; then
    YAHOO="%5ENSEI"
    SYMBOL="NIFTY_50"
elif [ "$SYMBOL" = "SENSEX" ]; then
    YAHOO="%5EBSESN"
    SYMBOL="SENSEX"
elif [ "$SYMBOL" = "NEXT50" ] || [ "$SYMBOL" = "NIFTYNEXT50" ]; then
    YAHOO="%5ENSMIDCP"
    SYMBOL="NIFTY_NEXT_50"
elif [ "$SYMBOL" = "VIX" ] || [ "$SYMBOL" = "INDIAVIX" ]; then
    YAHOO="%5EINDIAVIX"
    SYMBOL="INDIA_VIX"

# 2. SECTORAL BANKING & FINANCE
elif [ "$SYMBOL" = "BANKNIFTY" ] || [ "$SYMBOL" = "NIFTYBANK" ] || [ "$SYMBOL" = "BANK" ]; then
    YAHOO="%5ENSEBANK"
    SYMBOL="NIFTY_BANK"
elif [ "$SYMBOL" = "PSUBANK" ] || [ "$SYMBOL" = "NIFTYPSUBANK" ]; then
    YAHOO="%5ECNXPSUBANK"
    SYMBOL="NIFTY_PSU_BANK"

# 3. CORE INDUSTRIAL & SECTORAL INDICES
elif [ "$SYMBOL" = "IT" ] || [ "$SYMBOL" = "NIFTYIT" ]; then
    YAHOO="%5ECNXIT"
    SYMBOL="NIFTY_IT"
elif [ "$SYMBOL" = "AUTO" ] || [ "$SYMBOL" = "NIFTYAUTO" ]; then
    YAHOO="%5ECNXAUTO"
    SYMBOL="NIFTY_AUTO"
elif [ "$SYMBOL" = "FMCG" ] || [ "$SYMBOL" = "NIFTYFMCG" ]; then
    YAHOO="%5ECNXFMCG"
    SYMBOL="NIFTY_FMCG"
elif [ "$SYMBOL" = "PHARMA" ] || [ "$SYMBOL" = "NIFTYPHARMA" ]; then
    YAHOO="%5ECNXPHARMA"
    SYMBOL="NIFTY_PHARMA"
elif [ "$SYMBOL" = "METAL" ] || [ "$SYMBOL" = "NIFTYMETAL" ]; then
    YAHOO="%5ECNXMETAL"
    SYMBOL="NIFTY_METAL"
elif [ "$SYMBOL" = "REALTY" ] || [ "$SYMBOL" = "NIFTYREALTY" ]; then
    YAHOO="%5ECNXREALTY"
    SYMBOL="NIFTY_REALTY"
elif [ "$SYMBOL" = "ENERGY" ] || [ "$SYMBOL" = "NIFTYENERGY" ]; then
    YAHOO="%5ECNXENERGY"
    SYMBOL="NIFTY_ENERGY"
elif [ "$SYMBOL" = "INFRA" ] || [ "$SYMBOL" = "NIFTYINFRA" ]; then
    YAHOO="%5ECNXINFRA"
    SYMBOL="NIFTY_INFRA"
elif [ "$SYMBOL" = "MEDIA" ] || [ "$SYMBOL" = "NIFTYMEDIA" ]; then
    YAHOO="%5ECNXMEDIA"
    SYMBOL="NIFTY_MEDIA"

# 4. BROAD MARKET MID & SMALL CAPS
elif [ "$SYMBOL" = "MIDCAP150" ] || [ "$SYMBOL" = "NIFTY_MIDCAP_150" ] || [ "$SYMBOL" = "MIDCAP" ]; then
    YAHOO="NIFTYMIDCAP150.NS"
    SYMBOL="NIFTY_MIDCAP_150"
#elif [ "$SYMBOL" = "SMLCAP100" ] || [ "$SYMBOL" = "NIFTY_SMLCAP_100" ]; then
#    YAHOO="%5ECNXSC"
#    SYMBOL="NIFTY_SMALLCAP_100"
elif [ "$SYMBOL" = "SMLCAP250" ] || [ "$SYMBOL" = "NIFTY_SMLCAP_250" ] || [ "$SYMBOL" = "SMLCAP" ]; then
    YAHOO="NIFTYSMLCAP250.NS"
    SYMBOL="NIFTY_SMALLCAP_250"

# 5. USER MANUAL FALLBACK OVERRIDES
elif [[ "$SYMBOL" == *.* ]] || [[ "$SYMBOL" == ^* ]]; then
    YAHOO=$(echo "$SYMBOL" | sed 's/\^/%5E/g')
else
    YAHOO="${SYMBOL}.NS"
fi

TMP_LONG=$(mktemp)
TMP_RECENT=$(mktemp)

cleanup() {
    rm -f "$TMP_LONG" "$TMP_RECENT"
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


# ============================================================
# PYTHON CALCULATIONS
# ============================================================

python3 - "$TMP_LONG" "$TMP_RECENT" "$SYMBOL" <<'PY'

import sys
import json
import datetime
import calendar

long_file = sys.argv[1]
recent_file = sys.argv[2]
SYMBOL = sys.argv[3]

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

week52_start = today - datetime.timedelta(days=365)

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

ret_15d = trading_return(
    data,
    ref_date,
    ref_close,
    15
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

    year = ref_date.year - years

    day = min(
        ref_date.day,
        calendar.monthrange(
            year,
            ref_date.month
        )[1]
    )

    target = datetime.date(
        year,
        ref_date.month,
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
ret_2y = yearly_return(2)
ret_3y = yearly_return(3)
ret_4y = yearly_return(4)
ret_5y = yearly_return(5)


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
    ret_10d,
    ret_15d
])

medium_trend = medium_long_trend([
    ret_1m,
    ret_2m,
    ret_3m,
    ret_45m,
    ret_6m,
    ret_9m
])

long_trend = medium_long_trend([
    ret_1y,
    ret_2y,
    ret_3y,
    ret_4y,
    ret_5y
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
# TRANCHE LEVELS & SWEET SPOTS
# ============================================================

T0 = low_52
T4 = high_52

step = (T4 - T0) / 4

T1 = T0 + step
T2 = T0 + step * 2
T3 = T0 + step * 3

sweet_spot_1 = (T1 + T2) / 2
sweet_spot_2 = (T2 + T3) / 2

dist_ss1 = return_pct(sweet_spot_1, ref_close)
dist_ss2 = return_pct(sweet_spot_2, ref_close)


def tranche_position(price):

    if price <= T0:
        return "T0"

    if price < T1:
        return "T0-T1"

    if price < T2:
        return "T1-T2"

    if price < T3:
        return "T2-T3"

    if price < T4:
        return "T3-T4"

    return "T4"


current_tranche = tranche_position(
    ref_close
)

from_low = return_pct(
    ref_close,
    low_52
)

from_high = return_pct(
    ref_close,
    high_52
)


# ============================================================
# OUTPUT
# ============================================================

print()
print("=================================================")
print("             STOCK TRANCHE CALCULATOR")
print("=================================================")
print(f"Stock           : {SYMBOL}")
print(f"Reference Date  : {ref_date}")
print(f"Reference Close : Rs. {ref_close:.2f}")
print("-------------------------------------------------")
print(f"52-Week Low     : Rs. {low_52:.2f}")
print(f"52W Low Date    : {low_date}")
print(f"52-Week High    : Rs. {high_52:.2f}")
print(f"52W High Date   : {high_date}")

print()
print("=================================================")
print("             SHORT-TERM MOMENTUM")
print("=================================================")
print(f"1W Return       : {fmt_pct(ret_5d)}")
print(f"2W Return       : {fmt_pct(ret_10d)}")
print(f"3W Return       : {fmt_pct(ret_15d)}")
print("-------------------------------------------------")
print(f"Short Trend     : {short_trend}")

print()
print("=================================================")
print("              MEDIUM-TERM RETURNS")
print("=================================================")
print(f"1M Return       : {fmt_pct(ret_1m)}")
print(f"2M Return       : {fmt_pct(ret_2m)}")
print(f"3M Return       : {fmt_pct(ret_3m)}")
print(f"4.5M Return     : {fmt_pct(ret_45m)}")
print(f"6M Return       : {fmt_pct(ret_6m)}")
print(f"9M Return       : {fmt_pct(ret_9m)}")
print(f"YTD Return      : {fmt_pct(ytd_return)}")
print("-------------------------------------------------")
print(f"Medium Trend    : {medium_trend}")

print()
print("=================================================")
print("               LONG-TERM RETURNS")
print("=================================================")
print(f"1Y Return       : {fmt_pct(ret_1y)}")
print(f"2Y Return       : {fmt_pct(ret_2y)}")
print(f"3Y Return       : {fmt_pct(ret_3y)}")
print(f"4Y Return       : {fmt_pct(ret_4y)}")
print(f"5Y Return       : {fmt_pct(ret_5y)}")
print("-------------------------------------------------")
print(f"Long Trend      : {long_trend}")

print()
print("=================================================")
print("                 OVERALL ANALYSIS")
print("=================================================")
print(f"Short Term      : {short_trend}")
print(f"Medium Term     : {medium_trend}")
print(f"Long Term       : {long_trend}")
print()
print(f"ACTION          : {action}")

print()
print("=================================================")
print("                TRANCHE LEVELS")
print("=================================================")
print(f"T0              : Rs. {T0:.2f}")
print(f"T1              : Rs. {T1:.2f}")
print(f"T2              : Rs. {T2:.2f}")
print(f"T3              : Rs. {T3:.2f}")
print(f"T4              : Rs. {T4:.2f}")
print("-------------------------------------------------")
print(f"Sweet Spot 1    : Rs. {sweet_spot_1:.2f} ({fmt_pct(dist_ss1)}) [T1-T2 Mid]")
print(f"Sweet Spot 2    : Rs. {sweet_spot_2:.2f} ({fmt_pct(dist_ss2)}) [T2-T3 Mid]")
print("-------------------------------------------------")
print(f"Current Tranche : {current_tranche}")
print(f"From 52W Low    : {fmt_pct(from_low)}")
print(f"From 52W High   : {fmt_pct(from_high)}")
print("=================================================")
print()

PY
