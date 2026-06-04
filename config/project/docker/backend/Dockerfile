FROM python:3.11.6-slim

RUN pip config set global.index-url http://172.21.3.9:8081/repository/PyPI_group/simple \
    && pip config set global.trusted-host 172.21.3.9

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8081

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8081", "--reload"]
