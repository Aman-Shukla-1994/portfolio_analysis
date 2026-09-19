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

if [[ "$SYMBOL" == *.* ]] || [[ "$SYMBOL" == ^* ]]; then
    YAHOO=$(python3 - "$SYMBOL" <<'PY'
import sys, urllib.parse
print(urllib.parse.quote(sys.argv[1], safe=''))
PY
)
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

python3 - "$TMP_LONG" "$TMP_RECENT" <<'PY'

import sys
import json
import datetime
import calendar
import math

long_file = sys.argv[1]
recent_file = sys.argv[2]

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


def trunc_pct(current, previous):

    if previous is None or previous == 0:
        return None

    return math.trunc((current - previous) / previous * 100 * 100) / 100


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


# ============================================================
# LOAD + MERGE
# ============================================================

long_close, long_high, long_low, _ = load_yahoo(long_file)
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

ltp = ref_close
ltp_date = ref_date
market_price = meta_recent.get("regularMarketPrice")
market_timestamp = meta_recent.get("regularMarketTime")
if market_price is not None:
    try:
        ltp = float(market_price)
        if market_timestamp is not None:
            ltp_date = datetime.datetime.fromtimestamp(
                market_timestamp,
                IST
            ).date()
    except (TypeError, ValueError, OverflowError):
        ltp = ref_close
        ltp_date = ref_date

return_data = dict(data)
if ltp_date >= ref_date:
    return_data[ltp_date] = ltp

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

# ============================================================
# SHORT TERM
# ============================================================

one_week_target = ltp_date - datetime.timedelta(days=7)
_, one_week_close = nearest_on_or_before(
    return_data,
    one_week_target
)
ret_5d = return_pct(ltp, one_week_close)

# ============================================================
# CALENDAR RETURN
# ============================================================

def calendar_return(months=0, extra_days=0):

    month = ltp_date.month - months
    year = ltp_date.year

    while month <= 0:

        month += 12
        year -= 1

    day = min(
        ltp_date.day,
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

    _, old_close = nearest_on_or_before(
        return_data,
        target
    )

    return return_pct(
        ltp,
        old_close
    )


ret_1m = calendar_return(months=1)
ret_3m = calendar_return(months=3)

# 4.5 months = 4 calendar months + 15 days
ret_6m = calendar_return(months=6)


# ============================================================
# YTD
# ============================================================

year_start = datetime.date(
    today.year,
    1,
    1
)

ytd_dates = sorted(
    d for d in return_data
    if year_start <= d <= ltp_date
)

if len(ytd_dates) > 1:

    ytd_start_close = data[ytd_dates[0]]

    ytd_return = return_pct(
        ltp,
        ytd_start_close
    )

else:

    ytd_start_close = None
    ytd_return = None


# ============================================================
# YEARLY RETURNS
# ============================================================

def yearly_return(years):

    months = round(years * 12)
    target_month_index = ltp_date.year * 12 + ltp_date.month - 1 - months
    year, month_index = divmod(target_month_index, 12)
    month = month_index + 1

    day = min(
        ltp_date.day,
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

    _, old_close = nearest_on_or_before(
        return_data,
        target
    )

    return return_pct(
        ltp,
        old_close
    )


ret_1y = yearly_return(1)
ret_3y = yearly_return(3)
ret_5y = yearly_return(5)
from_low = trunc_pct(
    ltp,
    low_52
)

from_high = trunc_pct(
    ltp,
    high_52
)

# ============================================================
# OUTPUT
# ============================================================

print("=================================================")
print("        STOCK DETAILS & FUNDAMENTALS")
print("=================================================")
print(f"LTP             : Rs. {ltp:.2f}")
print(f"LTP date        : {ltp_date}")
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
