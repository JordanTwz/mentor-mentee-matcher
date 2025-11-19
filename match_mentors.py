#!/usr/bin/env python3
"""
match_mentors_ui.py

One-to-One Mentor–Mentee Matching with Drag-Drop Priority, Tooltips & Error Handling
----------------------------------------------------------------------------
Industry fuzzy matching is now exact (threshold=0) to avoid unintended matches. Duplicate industry matches are removed.
Usage:
    python match_mentors.py
Open http://127.0.0.1:5000/
"""

import re, logging
from flask import Flask, request, render_template_string, Response, redirect, url_for, flash
import pandas as pd
import numpy as np
from scipy.optimize import linear_sum_assignment

# Optional fuzzy matching
try:
    from rapidfuzz import fuzz
except ImportError:
    fuzz = None

app = Flask(__name__)
app.secret_key = 'replace_with_a_secure_random_key'

INDEX_HTML = """
<!doctype html>
<html>
<head>
  <title>Mentor-Mentee Matcher</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.0.2/dist/css/bootstrap.min.css" rel="stylesheet">
  <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.0.2/dist/js/bootstrap.bundle.min.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/sortablejs@1.14.0/Sortable.min.js"></script>
</head>
<body class="p-4">
  <h1>Mentor-Mentee Matching</h1>
  {% with messages = get_flashed_messages(category_filter=['error']) %}
    {% if messages %}
      <div class="alert alert-danger">
        <ul>
        {% for msg in messages %}<li>{{msg}}</li>{% endfor %}
        </ul>
      </div>
    {% endif %}
  {% endwith %}
  <form id="matchForm" method="post" action="/match" enctype="multipart/form-data">
    <div class="mb-3">
      <label class="form-label">Mentor Excel</label>
      <input type="file" name="mentors" class="form-control" accept=".xlsx" required>
    </div>
    <div class="mb-3">
      <label class="form-label">Mentee Excel</label>
      <input type="file" name="mentees" class="form-control" accept=".xlsx" required>
    </div>
    <div class="mb-3">
      <label class="form-label">
        Fuzzy Threshold
        <span tabindex="0" class="badge bg-info text-dark" data-bs-toggle="tooltip" title="Controls how strictly strings must match. 0 = exact match only; higher values allow more variance (up to 100 for maximum fuzz).">?</span>
      </label>
      <input type="number" name="fuzzy_threshold" class="form-control" value="80" min="0" max="100">
    </div>
    <div class="mb-3">
      <label class="form-label">Drag to Rank Priority</label>
      <ul id="priorityList" class="list-group">
        <li class="list-group-item" data-key="industry">Industry Preference</li>
        <li class="list-group-item" data-key="role">Role Match</li>
        <li class="list-group-item" data-key="interest">Interest Overlap</li>
        <li class="list-group-item" data-key="keyword">Keyword Overlap</li>
      </ul>
      <input type="hidden" name="priorities" id="prioritiesInput">
    </div>
    <button type="submit" class="btn btn-primary mt-2">Match</button>
  </form>
  <script>
    Sortable.create(document.getElementById('priorityList'), { animation: 150 });
    var tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
    tooltipTriggerList.map(function (el) { return new bootstrap.Tooltip(el); });
    document.getElementById('matchForm').addEventListener('submit', function(e) {
      const items = document.querySelectorAll('#priorityList li');
      const keys = Array.from(items).map(li => li.getAttribute('data-key'));
      document.getElementById('prioritiesInput').value = keys.join(',');
    });
  </script>
</body>
</html>
"""

RESULT_HTML = """
<!doctype html>
<html>
<head>
  <title>Matching Results</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.0.2/dist/css/bootstrap.min.css" rel="stylesheet">
  <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.0.2/dist/js/bootstrap.bundle.min.js"></script>
</head>
<body class="p-4">
  <h1>Matching Results</h1>
  <div class="mb-3">
    <a href="/" class="btn btn-secondary">New Match</a>
    <a href="/download" class="btn btn-success ms-2">Download CSV</a>
  </div>
  <div class="mb-3">
    <label class="form-label">Sort by:</label>
    <select id="sortColumn" class="form-select" style="width:auto; display:inline-block;">
      <option value="Score">Score</option>
      <option value="Mentee">Mentee</option>
      <option value="Mentor">Mentor</option>
      <option value="Industry_Matches">Industry Matches</option>
      <option value="Role_Match">Role Match</option>
      <option value="Interest_Overlap">Interest Overlap</option>
      <option value="Keyword_Overlap">Keyword Overlap</option>
    </select>
    <button class="btn btn-primary ms-2" onclick="sortTable()">Sort</button>
  </div>
  <p class="text-muted">Click any result row to see its score breakdown.</p>
  <table id="resultsTable" class="table table-striped">
    <thead>
      <tr>
        <th>Mentee</th>
        <th>Mentor</th>
        <th>Score</th>
        <th>Industry Matches</th>
        <th>Role Match</th>
        <th>Interest Overlap</th>
        <th>Keyword Overlap</th>
      </tr>
    </thead>
    <tbody>
    {% for row in rows %}
      <tr data-breakdown='{{ row.ScoreBreakdown | tojson | safe }}'>
        <td>{{row.Mentee}}</td>
        <td>{{row.Mentor}}</td>
        <td>{{row.Score}}</td>
        <td>{{row.Industry_Matches}}</td>
        <td>{{row.Role_Match}}</td>
        <td>{{row.Interest_Overlap}}</td>
        <td>{{row.Keyword_Overlap}}</td>
      </tr>
    {% endfor %}
    </tbody>
  </table>

  <div class="modal fade" id="breakdownModal" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-lg">
      <div class="modal-content">
        <div class="modal-header">
          <h5 class="modal-title" id="breakdownTitle">Score Breakdown</h5>
          <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
        </div>
        <div class="modal-body">
          <p>Total Score: <strong id="breakdownTotal">0.00</strong></p>
          <div class="table-responsive">
            <table class="table table-bordered">
              <thead>
                <tr>
                  <th>Component</th>
                  <th>Points</th>
                  <th>Details</th>
                </tr>
              </thead>
              <tbody id="breakdownBody"></tbody>
            </table>
          </div>
        </div>
        <div class="modal-footer">
          <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>
        </div>
      </div>
    </div>
  </div>

  <script>
    // Map select-option values to column indexes in the table
    const colIndexMap = {
      "Mentee": 0,
      "Mentor": 1,
      "Score": 2,
      "Industry_Matches": 3,
      "Role_Match": 4,
      "Interest_Overlap": 5,
      "Keyword_Overlap": 6
    };

    function sortTable() {
      const table = document.getElementById("resultsTable");
      const tbody = table.tBodies[0];
      const rows = Array.from(tbody.rows);
      const colName = document.getElementById("sortColumn").value;
      const colIndex = colIndexMap[colName];

      // Comparator: always ascending
      rows.sort((a, b) => {
        let aText = a.cells[colIndex].innerText.trim();
        let bText = b.cells[colIndex].innerText.trim();

        if (colName === "Score") {
          return parseFloat(aText) - parseFloat(bText);
        }

        if (colName === "Mentee") {
          // extract numeric suffix, default to 0
          const aNum = parseInt((aText.match(/\\d+/) || [0])[0], 10);
          const bNum = parseInt((bText.match(/\\d+/) || [0])[0], 10);
          return aNum - bNum;
        }

        return aText.localeCompare(bText);
      });

      // Reverse for all except Mentee (to get descending)
      if (colName !== "Mentee") {
        rows.reverse();
      }

      // Rebuild the tbody
      tbody.innerHTML = "";
      rows.forEach(row => tbody.appendChild(row));
    }
    const breakdownModalEl = document.getElementById("breakdownModal");
    const breakdownModal = breakdownModalEl ? new bootstrap.Modal(breakdownModalEl) : null;
    const breakdownBody = document.getElementById("breakdownBody");
    const breakdownTitle = document.getElementById("breakdownTitle");
    const breakdownTotal = document.getElementById("breakdownTotal");
    const breakdownConfig = [
      { label: "Industry", pointsKey: "industry_points", detailsKey: "industry_details", isList: true },
      { label: "Role", pointsKey: "role_points", detailsKey: "role_details", isList: false },
      { label: "Interest", pointsKey: "interest_points", detailsKey: "interest_details", isList: true },
      { label: "Keyword", pointsKey: "keyword_points", detailsKey: "keyword_details", isList: true }
    ];

    document.querySelectorAll("#resultsTable tbody tr").forEach(row => {
      row.style.cursor = "pointer";
      row.addEventListener("click", () => {
        if (!breakdownModal) {
          return;
        }
        const data = JSON.parse(row.dataset.breakdown || "{}");
        breakdownTitle.textContent = `${row.cells[0].innerText.trim()} - ${row.cells[1].innerText.trim()}`;
        breakdownTotal.textContent = Number(data.total || 0).toFixed(2);
        breakdownBody.innerHTML = "";
        breakdownConfig.forEach(cfg => {
          const tr = document.createElement("tr");
          const nameTd = document.createElement("td");
          nameTd.textContent = cfg.label;
          const pointsTd = document.createElement("td");
          pointsTd.textContent = Number(data[cfg.pointsKey] || 0).toFixed(2);
          const detailTd = document.createElement("td");
          if (cfg.isList) {
            const items = data[cfg.detailsKey] || [];
            if (!items.length) {
              detailTd.textContent = "None";
            } else {
              items.forEach(item => {
                const div = document.createElement("div");
                div.textContent = item;
                detailTd.appendChild(div);
              });
            }
          } else {
            detailTd.textContent = data[cfg.detailsKey] || "None";
          }
          tr.appendChild(nameTd);
          tr.appendChild(pointsTd);
          tr.appendChild(detailTd);
          breakdownBody.appendChild(tr);
        });
        breakdownModal.show();
      });
    });
  </script>
</body>
</html>
"""



_last_df = None

# Helpers

def normalize_text(s): return re.sub(r"\s+"," ", str(s).strip().lower())

def normalize_list(cell):
    if pd.isna(cell): return []
    return [normalize_text(p) for p in re.split(r"[;,]", str(cell)) if p.strip()]

def fuzzy_eq(a,b,th): return fuzz.token_sort_ratio(a,b)>=th if fuzz else a==b


def preprocess_mentors(df):
    df['industries'] = df['Mentor Company Category'].fillna('').apply(normalize_list) + \
                        df['Areas of Industry Experience'].fillna('').apply(normalize_list)
    df['role'] = df['Mentor Job Role Category'].fillna('').apply(normalize_text)
    df['interests'] = df['Mentor Area of Interests Keywords'].fillna('').apply(normalize_list)
    df['keywords'] = df['Mentor Combined Keywords-Cleaned'].fillna('').apply(normalize_list)
    return df


def preprocess_mentees(df):
    prefs = []
    for c in ['Mentee 1st Choice of Industry', 'Mentee 2nd Choice of Industry', 'Mentee 3rd Choice of Industry']:
        prefs.append(df[c].fillna('').apply(normalize_text))
    df['industries_pref'] = list(zip(*prefs))
    df['role'] = df['Mentee Job Role Category'].fillna('').apply(normalize_text)
    df['interests'] = df['Mentee Area of Personal Interest'].fillna('').apply(normalize_list)
    df['keywords'] = df['Mentee Keywords'].fillna('').apply(normalize_list)
    return df


def compute_score(m,n,weights,th):
    sc = 0.0
    for rank,pref in enumerate(n['industries_pref'],1):
        if not pref: continue
        for ind in m['industries']:
            if fuzzy_eq(pref,ind,0):
                sc += weights['industry'].get(rank,0)*weights['priority_factor']['industry']
                break
    if n['role'] and fuzzy_eq(n['role'],m['role'],th): sc+=weights['priority_factor']['role']
    if set(n['interests']) & set(m['interests']): sc+=weights['priority_factor']['interest']
    overlap = set(n['keywords']) & set(m['keywords'])
    sc += len(overlap)*weights['priority_factor']['keyword']
    return sc


def match_details(m,n,th):
    det = {'Industry_Matches': [], 'Role_Match': False, 'Interest_Overlap': [], 'Keyword_Overlap': []}
    for rank,pref in enumerate(n['industries_pref'],1):
        if not pref: continue
        for ind in m['industries']:
            if fuzzy_eq(pref,ind,0):
                det['Industry_Matches'].append(f"{rank}:{ind}")
                break
    det['Role_Match'] = bool(n['role'] and fuzzy_eq(n['role'],m['role'],th))
    seen = set()
    for intr in n['interests']:
        if intr in m['interests'] and intr not in seen:
            det['Interest_Overlap'].append(intr)
            seen.add(intr)
    seen = set()
    for kw in n['keywords']:
        if kw in m['keywords'] and kw not in seen:
            det['Keyword_Overlap'].append(kw)
            seen.add(kw)
    return det


def score_breakdown(mentor_row, mentee_row, weights, th, details):
    industry_points = 0.0
    for rank, pref in enumerate(mentee_row['industries_pref'], 1):
        if not pref:
            continue
        for ind in mentor_row['industries']:
            if fuzzy_eq(pref, ind, 0):
                industry_points += weights['industry'].get(rank, 0) * weights['priority_factor']['industry']
                break

    role_points = weights['priority_factor']['role'] if mentee_row['role'] and fuzzy_eq(mentee_row['role'], mentor_row['role'], th) else 0.0

    interest_points = weights['priority_factor']['interest'] if set(mentee_row['interests']) & set(mentor_row['interests']) else 0.0

    keyword_overlap = set(mentee_row['keywords']) & set(mentor_row['keywords'])
    keyword_points = len(keyword_overlap) * weights['priority_factor']['keyword']

    total = industry_points + role_points + interest_points + keyword_points

    return {
        'industry_points': round(industry_points, 2),
        'industry_details': details['Industry_Matches'],
        'role_points': round(role_points, 2),
        'role_details': 'Match' if details['Role_Match'] else 'No match',
        'interest_points': round(interest_points, 2),
        'interest_details': details['Interest_Overlap'],
        'keyword_points': round(keyword_points, 2),
        'keyword_details': details['Keyword_Overlap'],
        'total': round(total, 2)
    }

@app.route('/', methods=['GET'])
def index(): return render_template_string(INDEX_HTML)

@app.route('/match', methods=['POST'])
def match():
    global _last_df
    try:
        mentors = pd.read_excel(request.files['mentors'])
        mentees = pd.read_excel(request.files['mentees'])
    except Exception as e:
        flash(f"File error: {e}", 'error'); return redirect(url_for('index'))

    try:
        thresh = int(request.form.get('fuzzy_threshold', '80'))
        keys = request.form.get('priorities', '').split(',')
        if set(keys) != {'industry','role','interest','keyword'}:
            raise ValueError('Drag to rank all four priorities uniquely')
    except Exception as e:
        flash(f"Input error: {e}", 'error'); return redirect(url_for('index'))

    base = {'industry': {1:10, 2:6, 3:3}}
    weights = {'industry': base['industry'], 'priority_factor': {keys[0]:4, keys[1]:3, keys[2]:2, keys[3]:1}}

    try:
        mentors = preprocess_mentors(mentors)
        mentees = preprocess_mentees(mentees)
    except Exception as e:
        flash(f"Sheet format error: {e}", 'error'); return redirect(url_for('index'))

    n_mn, n_me = len(mentors), len(mentees)
    size = max(n_mn, n_me)
    M = np.zeros((size, size))
    for i in range(n_me):
        for j in range(n_mn):
            M[i,j] = compute_score(mentors.iloc[j], mentees.iloc[i], weights, thresh)

    rows, cols = linear_sum_assignment(-M)
    out = []
    for r, c in zip(rows, cols):
        if r < n_me and c < n_mn:
            m = mentors.iloc[c]; n = mentees.iloc[r]
            det = match_details(m, n, thresh)
            score_value = round(M[r,c], 2)
            out.append({
                'Mentee': n['UG_Full_Name'],
                'Mentor': m['Mentor Name'],
                'Score': score_value,
                'Industry_Matches': ';'.join(det['Industry_Matches']),
                'Role_Match': det['Role_Match'],
                'Interest_Overlap': ';'.join(det['Interest_Overlap']),
                'Keyword_Overlap': ';'.join(det['Keyword_Overlap']),
                'ScoreBreakdown': score_breakdown(m, n, weights, thresh, det)
            })
    _last_df = pd.DataFrame([{k: v for k, v in row.items() if k != 'ScoreBreakdown'} for row in out])
    return render_template_string(RESULT_HTML, rows=out)

@app.route('/download')
def download():
    buf = _last_df.to_csv(index=False)
    return Response(buf, mimetype='text/csv', headers={'Content-Disposition':'attachment;filename=mentor_matches.csv'})

if __name__ == '__main__':
    app.run(debug=True)
