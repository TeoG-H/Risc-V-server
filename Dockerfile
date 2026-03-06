FROM python:3.10

RUN apt-get update && apt-get install -y iverilog

WORKDIR /app

COPY . .

RUN pip install flask gunicorn

EXPOSE 10000

CMD ["python", "app.py"]