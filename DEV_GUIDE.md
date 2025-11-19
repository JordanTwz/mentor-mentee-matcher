# Developer Guide

## 1. Overview
- Flask + Pandas + SciPy application that ingests mentor/mentee Excel exports and runs the Hungarian algorithm to maximize weighted match scores.
- Core logic lives in `match_mentors.py`, which also embeds the HTML templates for the upload form and results page.
- Optional RapidFuzz dependency allows fuzzy comparisons; code falls back to exact matching if unavailable.

## 2. Repository Layout
```
match_mentors.py              # Flask app, templates, scoring logic
requirements.txt              # Python dependencies
Sorted_*_Updated_14_Feb.xlsx  # Sample mentor/mentee spreadsheets
docker-compose.yml / Dockerfile / init.sh / init.ps1  # Local container tooling
terraform/**                  # Optional infrastructure provisioning
```

## 3. Application Flow
1. **Upload** (`/match`):
   - Reads mentor & mentee workbooks with `pandas.read_excel`.
   - Validates fuzzy threshold and priority order from the form.
2. **Preprocessing**:
   - `preprocess_mentors` builds normalized lists (industries, interests, keywords) and role strings.
   - `preprocess_mentees` captures ordered industry preferences plus role/interests/keywords.
3. **Scoring**:
   - `compute_score` iterates mentee preferences, applies base weights + priority multipliers, computes keyword overlap counts, and returns a float.
   - `linear_sum_assignment(-M)` maximizes the overall score matrix.
   - `match_details` records textual overlap info; `score_breakdown` recomputes component totals for the modal.
4. **Rendering**:
   - Results passed into `RESULT_HTML`. Each table row contains serialized breakdown data for the Bootstrap modal. `_last_df` caches rows for CSV downloads.

## 4. Weights & Priorities
```python
base = {'industry': {1: 10, 2: 6, 3: 3}}
weights = {
    'industry': base['industry'],
    'priority_factor': {keys[0]: 4, keys[1]: 3, keys[2]: 2, keys[3]: 1}
}
```
- Drag order dictates priority multipliers; `keys` comes from the client-side drag list.
- Industry scoring: first/second/third preferences earn 10/6/3 base points, then multiplied by the priority factor for the “industry” key.
- Role/Interest/Keyword: presence or overlap count multiplied by their respective factors.
- `score_breakdown` recomputes the same math to ensure the modal’s totals always equal the displayed score.

## 5. Environment & Tooling
- **Virtual environment**: `python -m venv venv && source venv/bin/activate` (or Windows equivalent) before installing requirements.
- **Docker**: `docker-compose up` uses the included Dockerfile to run Gunicorn; mount volumes as needed for Excel inputs.
- **Terraform**: Files under `terraform/` provision networking (VPC, subnets, etc.) if deploying to AWS—review variables and backend config before applying.
- **Secrets**: Update `app.secret_key` or inject via environment variables before deploying.

## 6. Testing & Verification
- **Syntax check**: `python -m py_compile match_mentors.py`.
- **Unit tests**: (Recommended) add `pytest` cases for `compute_score`, `match_details`, and `score_breakdown`.
- **Integration**:
  - Run the Flask app locally, upload sample spreadsheets, verify modal breakdowns equal table scores.
  - Download CSV and ensure JSON-only fields (e.g., `ScoreBreakdown`) are removed before exporting (_last_df filtering handles this).
- **Performance**: Use tools like `cProfile` or `py-spy` to examine the nested scoring loops when datasets grow; see the “Performance profiling & flamegraph analysis” task in the timesheet for context.

## 7. Extending the Project
- **New scoring factors**: Add the factor to the drag list, extend `compute_score`, `match_details`, `score_breakdown`, update templates, and adjust weights dict.
- **Authentication/authorization**: Wrap routes with Flask-Login or an upstream gateway; secure file uploads accordingly.
- **Persistence**: Store mentor/mentee datasets or match results in a database to allow historical auditing or manual overrides.
- **Automation**: Wire CI jobs (GitHub Actions) to run lint/tests, build Docker images, and deploy via Terraform scripts.

## 8. Troubleshooting Checklist
- **Missing dependencies**: Rerun `pip install -r requirements.txt`. RapidFuzz is optional; absence simply forces exact matching.
- **Excel schema drift**: Update column names inside `preprocess_*` functions; keep `normalize_*` helpers applied.
- **Hungarian algorithm errors**: Ensure the score matrix is square—current code pads to `max(len(mentors), len(mentees))`, but NaNs or dtype issues can still occur if inputs contain non-numeric data.
- **Modal not showing**: Confirm Bootstrap JS is included in `RESULT_HTML`, table rows have `data-breakdown` attributes, and no JS errors appear in the console.
- **CSV mismatch**: `_last_df` strips the `ScoreBreakdown` field before saving; if new fields are added, update that filtering logic accordingly.
