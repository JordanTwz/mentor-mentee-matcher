# User Guide

## 1. Overview
- The Mentor-Mentee Matcher pairs mentees with mentors using survey data and weighted priorities (industry, role, interest, keyword).
- Users upload `.xlsx` spreadsheets exported from the official forms, configure priority order, and review/download the resulting matches in their browser.

## 2. Quick Start
1. Install Python 3.10+.
2. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```
3. Run the Flask server:
   ```bash
   python match_mentors.py
   ```
4. Open `http://127.0.0.1:5000/` in a browser.

## 3. Uploading Data
- Provide both mentor and mentee Excel files in `.xlsx` format.
- The sheets must contain the columns referenced in `preprocess_mentors` and `preprocess_mentees` (see the sample spreadsheets in the repo for a template).
- Invalid or missing columns trigger a “Sheet format error” flash message.

## 4. Configuring Matching
- **Fuzzy threshold**: Controls how strict role/keyword comparisons are (0 = exact only, 100 = very lenient).
- **Drag-to-rank priorities**: Reorder Industry, Role, Interest, and Keyword to change their weighting. All four must be present; highest position receives the largest multiplier.
- Submission validates the order; duplicates or missing entries raise “Drag to rank all four priorities uniquely.”

## 5. Viewing Results
- The results table lists each mentee → mentor pairing, the total score, and detail columns (industry matches, role match, etc.).
- **Sorting**: Use the dropdown to sort by any column. Score sorts descending; “Mentee” sorts numerically by suffix.
- **Score breakdown modal**: Click any row to open a modal with per-component points (industry ranks hit, role status, interest overlaps, keyword overlaps, total). Component totals always sum to the main score.
- **CSV export**: Use “Download CSV” to export the current matches. Rows include the detail columns shown in the table.

## 6. Common Tasks & Troubleshooting
- **Run a new match**: Click “New Match” to return to the upload form and submit fresh spreadsheets.
- **Understand scores**: Within the modal, industry matches are labeled as `rank:value` (e.g., `1:aerospace`). Notebook/tooltip hints explain the calculation.
- **Upload failures**: “File error” indicates parsing issues; verify the spreadsheet is a valid `.xlsx`. “Sheet format error” means mandatory columns are missing/renamed.
- **Priority mistakes**: Reorder the drag list until all four categories are unique; the hidden field must contain each key exactly once.
