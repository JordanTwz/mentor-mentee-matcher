FROM python:3.12-slim-bookworm

WORKDIR /app

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY match_mentors.py ./

EXPOSE 5000

CMD [ "python", "match_mentors.py" ]
