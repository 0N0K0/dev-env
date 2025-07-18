ARG PYTHON_VERSION=latest
FROM python:${PYTHON_VERSION}

WORKDIR /app
COPY ./api /app
RUN pip install -r requirements.txt
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "80"]
