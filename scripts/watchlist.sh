#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

resolve_watchlist() {
    local candidate="$1"

    if [ -z "$candidate" ]; then
        return 1
    fi

    if [ -f "$candidate" ]; then
        printf '%s\n' "$candidate"
        return 0
    fi

    if [ -f "$REPO_ROOT/$candidate" ]; then
        printf '%s\n' "$REPO_ROOT/$candidate"
        return 0
    fi

    if [ -f "$REPO_ROOT/watchlists/$candidate" ]; then
        printf '%s\n' "$REPO_ROOT/watchlists/$candidate"
        return 0
    fi

    return 1
}

WATCHLIST="$(resolve_watchlist "$1")"
OUTPUT_CSV="${2:-}"
if [ -z "$WATCHLIST" ]; then
    echo "Usage: $0 <filename> [output.csv]"
    exit 1
fi

TMP_OUTPUT=$(mktemp)
TMP_CSV=$(mktemp)
TMP_PY=$(mktemp)
trap 'rm -f "$TMP_OUTPUT" "$TMP_CSV" "$TMP_PY"' EXIT

if [ -n "$OUTPUT_CSV" ]; then
    mkdir -p "$(dirname "$OUTPUT_CSV")" 2>/dev/null || true
    printf '%s\n' 'SYMBOL,LTP,Sector,MarketType,PE,PEG,PB,DivYield,1W,1M,3M,6M,YTD,1Y,3Y,5Y,52WH,%-chg,52WHDate' > "$TMP_CSV"
fi

colorize_return() {
    local value="${1:-}"
    if [ -z "$value" ] || [ "$value" = "N/A" ]; then
        printf '%s' "$value"
        return
    fi
    if [[ "$value" == -* || "$value" == \+* ]]; then
        case "$value" in
            -*) printf '\033[41m%s\033[0m' "$value" ;;
            +*) printf '\033[42m%s\033[0m' "$value" ;;
            *) printf '%s' "$value" ;;
        esac
    elif [[ "$value" == *% ]]; then
        if [[ "$value" == -* ]]; then
            printf '\033[41m%s\033[0m' "$value"
        else
            printf '\033[42m%s\033[0m' "$value"
        fi
    else
        printf '%s' "$value"
    fi
}

printf '%-12s %-8s %-18s %-15s %-8s %-8s %-8s %-18s %-12s %-12s %-12s %-12s %-12s %-12s %-12s %-12s %-12s %-12s %-12s\n' \
    "SYMBOL" "LTP" "Sector" "MarketType" "PE" "PEG" "PB" "DivYield" "1W" "1M" "3M" "6M" "YTD" "1Y" "3Y" "5Y" "52WH" "%-chg" "52WHDate"
echo "-----------------------------------------------------------------------------------------------------------------------------------"

while IFS= read -r raw_line || [ -n "$raw_line" ]; do
    line=$(echo "$raw_line" | tr -d '\r')
    if [ -z "$line" ]; then
        continue
    fi

    bash "$SCRIPT_DIR/stock.sh" "$line" > "$TMP_OUTPUT" 2>&1 || true

    symbol="$line"
    ltp=$(grep '^LTP[[:space:]]*:[[:space:]]*Rs\.' "$TMP_OUTPUT" | head -n 1 | sed -E 's/.*Rs\. ([0-9,]+(\.[0-9]+)?).*/\1/' | tr -d ',')
    sector=$(grep '^Sector[[:space:]]*:' "$TMP_OUTPUT" | head -n 1 | sed -E 's/^Sector[[:space:]]*:[[:space:]]*(.*)$/\1/')
    market_cap_type=$(grep '^MarketType[[:space:]]*:' "$TMP_OUTPUT" | head -n 1 | sed -E 's/^MarketType[[:space:]]*:[[:space:]]*(.*)$/\1/')
    pe=$(grep '^PE[[:space:]]*:' "$TMP_OUTPUT" | head -n 1 | sed -E 's/^PE[[:space:]]*:[[:space:]]*(.*)$/\1/')
    peg=$(grep '^PEG[[:space:]]*:' "$TMP_OUTPUT" | head -n 1 | sed -E 's/^PEG[[:space:]]*:[[:space:]]*(.*)$/\1/')
    pb=$(grep '^PB[[:space:]]*:' "$TMP_OUTPUT" | head -n 1 | sed -E 's/^PB[[:space:]]*:[[:space:]]*(.*)$/\1/')
    div_yield=$(grep '^DivYield[[:space:]]*:' "$TMP_OUTPUT" | head -n 1 | sed -E 's/^DivYield[[:space:]]*:[[:space:]]*(.*)$/\1/')
    w1=$(grep '^1W Return[[:space:]]*:' "$TMP_OUTPUT" | head -n 1 | sed -E 's/^1W Return[[:space:]]*:[[:space:]]*(.*)$/\1/')
    m1=$(grep '^1M Return[[:space:]]*:' "$TMP_OUTPUT" | head -n 1 | sed -E 's/^1M Return[[:space:]]*:[[:space:]]*(.*)$/\1/')
    m3=$(grep '^3M Return[[:space:]]*:' "$TMP_OUTPUT" | head -n 1 | sed -E 's/^3M Return[[:space:]]*:[[:space:]]*(.*)$/\1/')
    m6=$(grep '^6M Return[[:space:]]*:' "$TMP_OUTPUT" | head -n 1 | sed -E 's/^6M Return[[:space:]]*:[[:space:]]*(.*)$/\1/')
    ytd=$(grep '^YTD Return[[:space:]]*:' "$TMP_OUTPUT" | head -n 1 | sed -E 's/^YTD Return[[:space:]]*:[[:space:]]*(.*)$/\1/')
    y1=$(grep '^1Y Return[[:space:]]*:' "$TMP_OUTPUT" | head -n 1 | sed -E 's/^1Y Return[[:space:]]*:[[:space:]]*(.*)$/\1/')
    y3=$(grep '^3Y Return[[:space:]]*:' "$TMP_OUTPUT" | head -n 1 | sed -E 's/^3Y Return[[:space:]]*:[[:space:]]*(.*)$/\1/')
    y5=$(grep '^5Y Return[[:space:]]*:' "$TMP_OUTPUT" | head -n 1 | sed -E 's/^5Y Return[[:space:]]*:[[:space:]]*(.*)$/\1/')
    high=$(grep '^52WH[[:space:]]*:' "$TMP_OUTPUT" | head -n 1 | sed -E 's/^52WH[[:space:]]*:[[:space:]]*Rs\. ([0-9,]+(\.[0-9]+)?).*/\1/' | tr -d ',')
    from_high=$(grep '^52WH %-chg[[:space:]]*:' "$TMP_OUTPUT" | head -n 1 | sed -E 's/^52WH %-chg[[:space:]]*:[[:space:]]*(.*)$/\1/')
    high_date=$(grep '^52WH Date[[:space:]]*:' "$TMP_OUTPUT" | head -n 1 | sed -E 's/^52WH Date[[:space:]]*:[[:space:]]*(.*)$/\1/')

    : "${ltp:=N/A}"
    : "${sector:=N/A}"
    : "${market_cap_type:=N/A}"
    : "${pe:=N/A}"
    : "${peg:=N/A}"
    : "${pb:=N/A}"
    : "${div_yield:=N/A}"
    : "${w1:=N/A}"
    : "${m1:=N/A}"
    : "${m3:=N/A}"
    : "${m6:=N/A}"
    : "${ytd:=N/A}"
    : "${y1:=N/A}"
    : "${y3:=N/A}"
    : "${y5:=N/A}"
    : "${high:=N/A}"
    : "${from_high:=N/A}"
    : "${high_date:=N/A}"

    printf '%-12s %-8s %-18s %-15s %-8s %-8s %-8s %-18s %-12s %-12s %-12s %-12s %-12s %-12s %-12s %-12s %-12s %-12s %-12s\n' \
        "$symbol" "$ltp" "$sector" "$market_cap_type" "$pe" "$peg" "$pb" "$div_yield" "$(colorize_return "$w1")" "$(colorize_return "$m1")" "$(colorize_return "$m3")" "$(colorize_return "$m6")" "$(colorize_return "$ytd")" "$(colorize_return "$y1")" "$(colorize_return "$y3")" "$(colorize_return "$y5")" "$(colorize_return "$high")" "$(colorize_return "$from_high")" "$(colorize_return "$high_date")"

    if [ -n "$OUTPUT_CSV" ]; then
        printf '%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n' \
            "$symbol" \
            "$ltp" \
            "$sector" \
            "$market_cap_type" \
            "$pe" \
            "$peg" \
            "$pb" \
            "$div_yield" \
            "$w1" \
            "$m1" \
            "$m3" \
            "$m6" \
            "$ytd" \
            "$y1" \
            "$y3" \
            "$y5" \
            "$high" \
            "$from_high" \
            "$high_date" >> "$TMP_CSV"
    fi
done < "$WATCHLIST"

if [ -n "$OUTPUT_CSV" ]; then
    if [[ "$OUTPUT_CSV" == *.xlsx || "$OUTPUT_CSV" == *.XLSX ]]; then
        printf '%s\n' \
            'import csv' \
            'import sys' \
            '' \
            'try:' \
            '    from openpyxl import Workbook' \
            '    from openpyxl.styles import PatternFill' \
            'except ImportError as exc:' \
            '    print(f"ERROR: openpyxl is required for XLSX export: {exc}", file=sys.stderr)' \
            '    sys.exit(1)' \
            '' \
            'input_csv, output_xlsx = sys.argv[1:3]' \
            'red_fill = PatternFill(fill_type="solid", fgColor="FFB3B3")' \
            'green_fill = PatternFill(fill_type="solid", fgColor="B8F2B8")' \
            'wb = Workbook()' \
            'ws = wb.active' \
            'ws.title = "Watchlist"' \
            '' \
            'with open(input_csv, newline="", encoding="utf-8") as f:' \
            '    rows = list(csv.reader(f))' \
            '' \
            'if not rows:' \
            '    wb.save(output_xlsx)' \
            '    raise SystemExit' \
            '' \
            'header = [cell.strip() for cell in rows[0]]' \
            'return_columns = {' \
            '    idx + 1 for idx, name in enumerate(header) if name in {"1W", "1M", "3M", "6M", "YTD", "1Y", "3Y", "5Y", "%-chg"}' \
            '}' \
            '' \
            'for row_index, row in enumerate(rows, start=1):' \
            '    for col_index, value in enumerate(row, start=1):' \
            '        if row_index == 1:' \
            '            continue' \
            '        if col_index not in return_columns:' \
            '            continue' \
            '        cell = ws.cell(row=row_index, column=col_index, value=value)' \
            '        if not value:' \
            '            continue' \
            '        try:' \
            '            numeric = float(value.replace("%", "").replace(",", "").replace("+", ""))' \
            '        except ValueError:' \
            '            continue' \
            '        if numeric < 0:' \
            '            cell.fill = red_fill' \
            '        elif numeric > 0:' \
            '            cell.fill = green_fill' \
            '' \
            'for col in ws.columns:' \
            '    max_len = 0' \
            '    for cell in col:' \
            '        v = cell.value or ""' \
            '        max_len = max(max_len, len(str(v)))' \
            '    ws.column_dimensions[col[0].column_letter].width = min(max_len + 2, 24)' \
            '' \
            'wb.save(output_xlsx)' > "$TMP_PY"
        python3 "$TMP_PY" "$TMP_CSV" "$OUTPUT_CSV"
        echo "Excel export written to: $OUTPUT_CSV"
    else
        mv -f "$TMP_CSV" "$OUTPUT_CSV"
        echo "CSV export written to: $OUTPUT_CSV"
    fi
fi
