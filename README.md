# Portfolio Analysis

A Bash-based portfolio and market-index analysis tool for Indian equities and indices. It downloads daily market data from Yahoo Finance, calculates returns and trend signals across multiple time horizons, and places each symbol into price-based tranche levels.

## Requirements

- Bash
- Python 3
- `curl`
- Standard Unix utilities: `grep`, `sed`, `sort`, `xargs`, and `mktemp`
- Network access to Yahoo Finance

The scripts are intended for a Unix-like shell. On Windows, run them through WSL or Git Bash.

## Usage

### Analyze one symbol

```bash
bash tranches.sh RELIANCE
bash tranches.sh NIFTY
```

The symbol is normalized to uppercase. Regular stock symbols default to the Yahoo Finance `.NS` suffix. Common index aliases are mapped automatically, including:

- `NIFTY` / `NIFTY50`
- `SENSEX`
- `BANKNIFTY` / `NIFTYBANK`
- `IT`, `AUTO`, `FMCG`, `PHARMA`, `METAL`, `REALTY`, `ENERGY`, `INFRA`, `MEDIA`
- `PSUBANK`, `NEXT50`, `VIX`
- `MIDCAP150` and `SMLCAP250`

Yahoo-style symbols can also be supplied directly when needed, such as `BRITANNIA.NS` or a symbol beginning with `^`.

### Run the holdings dashboard

```bash
bash read_file.sh holdings.txt
```

`holdings.txt` contains one stock or index symbol per line. Blank lines are ignored. The dashboard analyzes every symbol, reports its 52-week low and high, preserves failed symbols as visible error rows, sorts results by the calculated action, and prints a colorized summary.

To use another watchlist:

```bash
bash read_file.sh path/to/watchlist.txt
```

To get the 52-week low and high for every configured index:

```bash
bash read_file.sh indices.txt
```

## Output

For each symbol, `tranches.sh` reports:

- The latest completed trading-day close
- The percentage distance of the current close above the 52-week low and below the 52-week high
- 1-week, 2-week, and 3-week trading returns
- 1-month, 2-month, 3-month, 4.5-month, 6-month, 9-month, and YTD returns
- 1-year through 5-year returns
- Short-, medium-, and long-term trend classifications
- An overall action such as `ACCUMULATE - UPTREND`, `CAUTIOUS ACCUMULATION`, or `WAIT - DOWNTREND`
- T0 through T4 tranche levels and two intermediate sweet spots
- The current tranche and distance from the 52-week high/low

The calculator downloads a 10-year daily history and overlays a recent 10-day download so the latest available sessions are refreshed. Data is converted to India Standard Time before trading dates are selected. For recognized NSE indices, the displayed 52-week high and low use the official NSE `allIndices` range; Yahoo Finance remains the source for the historical return calculations. Stock symbols and the SENSEX continue to use Yahoo high/low data.

## Tranche calculation

The 52-week intraday low and high define the range:

```text
T0 = 52-week low
T4 = 52-week high
step = (T4 - T0) / 4
T1 = T0 + step
T2 = T0 + 2 * step
T3 = T0 + 3 * step
```

The current close is classified into the interval containing it. The two sweet spots are the midpoints of T1-T2 and T2-T3.

## Development checks

There is no automated test suite or package manager. Run shell syntax checks before submitting changes:

```bash
bash -n tranches.sh
bash -n read_file.sh
```

A network-backed smoke test for the calculator is:

```bash
bash tranches.sh NIFTY
```

## GitHub Actions

The **Run watchlist dashboard** workflow can be started manually from the Actions tab and provides exactly two watchlist choices: `holdings.txt` or `indices.txt`. The **Analyze single symbol** workflow accepts a string such as `BSE` or `NIFTY`. Each workflow retrieves live market data and uploads its report as a workflow artifact.

## Files

- `tranches.sh` - single-symbol data download, calculations, trend classification, and report generation.
- `read_file.sh` - batch processing and colorized dashboard rendering.
- `holdings.txt` - default stock watchlist.
- `indices.txt` - index/watchlist aliases.
- `.github/copilot-instructions.md` - repository-specific guidance for Copilot sessions.

Generated scratch data such as `output.txt` is ignored by Git and should not be committed.

## Data and limitations

Market data is retrieved from Yahoo Finance at runtime and may be unavailable, delayed, stale, or changed by the upstream service. The calculator exits when no completed data is available, when the latest data is more than seven days old, or when 52-week high/low data is insufficient. Results are analytical indicators, not investment advice.
