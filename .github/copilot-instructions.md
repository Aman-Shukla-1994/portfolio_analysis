# Copilot instructions

## Project shape

This repository is a shell-based portfolio and market-index analysis tool. It has two executable entry points:

- `scripts/stock.sh SYMBOL` is the single-symbol calculator. Bash validates and normalizes the symbol, maps known Indian indices to Yahoo Finance tickers, downloads 10 years plus a recent 10-day window of daily chart data, and passes the temporary JSON files to an embedded Python 3 program.
- `scripts/watchlist.sh holdings.txt` is the batch dashboard. It reads one symbol per line, invokes `stock.sh` for each symbol, extracts values from the calculator's human-readable output, sorts rows by action priority, and renders a colorized table.

The data files are inputs rather than application code:

- `holdings.txt` contains stock symbols to process in the dashboard.
- `indices.txt` contains the supported index/watchlist aliases.

The Python section inside `stock.sh` merges the long and recent Yahoo responses, selects the latest completed trading day, rejects stale or insufficient data, calculates short-, medium-, and long-term returns, classifies trends, derives an overall action, and computes T0-T4 tranche levels from the 52-week intraday low/high.

## Commands

There is no package manager, build system, automated test suite, or configured linter in this repository. The scripts require Bash, `curl`, standard Unix tools (`awk`/`grep`/`sed`/`sort`/`xargs`/`mktemp`), and Python 3. They are intended to run in a Unix-like shell; on Windows use WSL or Git Bash.

Run a single symbol:

```bash
bash scripts/stock.sh BSE
bash scripts/stock.sh NIFTY
```

Run the holdings dashboard:

```bash
bash scripts/watchlist.sh watchlists/holdings.txt
```

Run the existing shell syntax checks:

```bash
bash -n scripts/stock.sh
bash -n scripts/watchlist.sh
```

There is no isolated unit-test command because the calculation logic is embedded in `stock.sh`. A practical smoke test is `bash scripts/stock.sh NIFTY`, which requires network access to Yahoo Finance and current, non-stale market data.

## Implementation conventions

- Treat the labels and spacing printed by `stock.sh` as an interface. `watchlist.sh` parses exact labels such as `ACTION`, `1W Return`, `From 52W High`, and `YTD Return`; changing them requires updating the parser in the same change.
- Normalize user symbols to uppercase before mapping. Add aliases in the ordered mapping block near the top of `stock.sh`; preserve the canonical display name separately from the Yahoo ticker.
- Known indices use explicit Yahoo symbols. Unknown symbols default to `<SYMBOL>.NS`; symbols containing `.` or beginning with `^` use the manual fallback path. Keep URL encoding behavior compatible with Yahoo's chart endpoint.
- The calculator deliberately uses daily bars, merges the 10-day refresh over the long history, and converts Yahoo timestamps to India Standard Time before grouping by date. Preserve this timezone and merge behavior when changing date calculations.
- Missing or stale market data is an error, not a zero-valued result. The batch script keeps failed symbols visible in the dashboard instead of silently dropping them.
- Use temporary files with `mktemp` and retain the existing `trap` cleanup pattern. Do not leave downloaded JSON or intermediate dashboard files in the repository.
- Trend/action strings are consumed both by humans and by the dashboard's ranking logic. If an action or trend label changes, update the color and priority branches in `watchlist.sh`.
- Dashboard rows use `|` as an internal delimiter and are sorted by the first field (`A` through `F`). Keep symbol inputs free of pipe characters and update field extraction consistently if the row shape changes.
- Preserve the existing Bash style: quote variables used as paths or command arguments, use explicit nonzero exits for invalid input/data failures, and avoid broad silent fallbacks. The recent-data request is the one intentional fallback: it warns and continues with long history.
- Input watchlists should remain one symbol per line, with blank lines tolerated by `watchlist.sh`.
