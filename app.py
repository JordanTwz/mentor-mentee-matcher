from flask import Flask, request, jsonify, send_from_directory
from flask_cors import CORS
import pandas as pd
import numpy as np
import io
import re

app = Flask(__name__, static_folder="static")
CORS(app)

def run_match(mentor_df: pd.DataFrame, mentee_df: pd.DataFrame) -> list:
    # 1) Fill missing
    mentor_df = mentor_df.fillna("")
    mentee_df = mentee_df.fillna("")

    # 2) Cross join
    mentor_df['_tmp'] = 1
    mentee_df['_tmp'] = 1
    cp = mentor_df.merge(mentee_df, on='_tmp').drop(columns=['_tmp'])

    # 3) Init score cols
    for col in ['department_score','company_industry_score','job_role_score',
                'personal_interest_score','optional_keyword_score',
                'mentor_department_requirement_score','mentee_matching_requirement_department_score']:
        cp[col] = 0
    cp['Total Score'] = 0

    # Department
    dept_match = cp['Mentor_Department'] == cp['UG_Department']
    cp.loc[dept_match, 'department_score'] = 8
    cp.loc[dept_match, 'Total Score'] += 8

    # Industry
    industry_map = [
        ('Mentee 1st Choice of Industry', 64, '1st'),
        ('Mentee 2nd Choice of Industry', 32, '2nd'),
        ('Mentee 3rd Choice of Industry', 16, '3rd'),
    ]
    cp['industry_details'] = [[] for _ in range(len(cp))]
    for col, pts, label in industry_map:
        mask = cp[col] == cp['Mentor Company Category']
        cp.loc[mask, 'company_industry_score'] += pts
        cp.loc[mask, 'Total Score'] += pts
        for idx in cp[mask].index:
            cp.at[idx, 'industry_details'].append(label + ' Choice')

    # Job role
    job_match = cp['Mentor Job Role Category'] == cp['Mentee Job Role Category']
    cp.loc[job_match, 'job_role_score'] = 16
    cp.loc[job_match, 'Total Score'] += 16
    cp['job_details'] = cp.apply(
        lambda r: r['Mentor Job Role Category'] if job_match.loc[r.name] else "",
        axis=1
    )

    # Personal interests
    def split_terms(s):
        return set(t.strip() for t in re.split(r'[;,]', s) if t.strip())
    mentor_terms = cp['Mentor Area of Interests Keywords'].apply(split_terms)
    mentee_terms = cp['Mentee Area of Personal Interest'].apply(split_terms)
    common = [list(m & n) for m, n in zip(mentor_terms, mentee_terms)]
    cp['personal_interest_score'] = [len(c) for c in common]
    cp['Total Score'] += cp['personal_interest_score']
    cp['personal_details'] = common

    # Optional keywords
    keyword_map = {
        r"\bAerospace\b":64, r"\bArts\b":64, r"Health|Medical|Healthcare":64,
        r"Biopharmaceuticals|Pharmaceutical|Science":64, r"Chemicals":64,
        r"\bSustainability\b":64, r"Business|Business Management|Business Development":64,
        r"Finance":64, r"Consulting":64, r"Entrepreneurship":64,
        r"\bMentoring\b":64, r"Banking":64, r"\bFMCG\b":64,
        r"Communication|Social Skills":64, r"Creative|Digital Transformation|Innovation":64,
        r"Guidance":64, r"Goal":64, r"Leadership|Management|Project Management":64,
        r"Human Management":64, r"UI/UX":64, r"Design":64, r"Education":64,
        r"Academia|Academic":64, r"Research":64, r"Engineering":64,
        r"Science":64, r"Technology":64, r"Robotics":64,
        r"Artificial Intelligence|Analytical|Data Analytics|Data Science|Machine Learning":64,
        r"Logistics":64, r"Energy|Renewables":64, r"Manufacturing":64,
        r"Semiconductors":64, r"Oil and Gas":64, r"Career|Internship":64,
        r"Experience":64, r"Overseas Experience|Overseas Opportunities":64,
        r"Travel":64, r"Volunteer":64, r"Future|Guidance":64,
        r"Food":64, r"Logistics|Supply Chain":64, r"IT|Software|Programming":64,
        r"Public Service|Government":64, r"Online":64, r"Overseas":64,
        r"Non-Engineering":64, r"Singaporean Chinese":64, r"Singaporean":64,
        r"China":64, r"Female":64, r"Male":64, r"Year 4":64
    }
    cp['optional_details'] = [[] for _ in range(len(cp))]
    for pattern, pts in keyword_map.items():
        mask = (
            cp['Mentor Combined Keywords-Cleaned']
              .str.contains(pattern, case=False, na=False)
            & cp['Mentee Keywords']
              .str.contains(pattern, case=False, na=False)
        )
        cp.loc[mask, 'optional_keyword_score'] += pts
        for idx in cp[mask].index:
            cp.at[idx, 'optional_details'].append(pattern)
    cp['Total Score'] += cp['optional_keyword_score']

    # Assignment
    sorted_cp = cp.sort_values('Total Score', ascending=False)
    assigned_m, assigned_t = set(), set()
    results = []
    for _, r in sorted_cp.iterrows():
        m, t = r['Mentor Name'], r['UG_Full_Name']
        if m in assigned_m or t in assigned_t:
            continue
        assigned_m.add(m); assigned_t.add(t)
        results.append({
            'mentor':m, 'mentee':t,
            'totalScore':int(r['Total Score']),
            'departmentScore':int(r['department_score']),
            'industryScore':int(r['company_industry_score']),
            'jobRoleScore':int(r['job_role_score']),
            'personalScore':int(r['personal_interest_score']),
            'optionalScore':int(r['optional_keyword_score']),
            'departmentDetail': r['Mentor_Department'],
            'industryDetails': r['industry_details'],
            'jobDetail': r['job_details'],
            'personalDetails': r['personal_details'],
            'optionalDetails': r['optional_details']
        })
        if len(assigned_t) == len(mentee_df):
            break
    return results

@app.route('/api/match', methods=['POST'])
def match_endpoint():
    if 'mentors' not in request.files or 'mentees' not in request.files:
        return jsonify({'error':'Please upload both files'}),400
    try:
        m_df = pd.read_excel(io.BytesIO(request.files['mentors'].read()))
        t_df = pd.read_excel(io.BytesIO(request.files['mentees'].read()))
    except Exception as e:
        return jsonify({'error':str(e)}),400
    return jsonify({'matches': run_match(m_df, t_df)})

@app.route('/', methods=['GET'])
def serve_frontend():
    return send_from_directory('static','index.html')

if __name__=='__main__':
    app.run(host='0.0.0.0',port=5000,debug=True)
