ARG PYTHON_VERSION=3.12
FROM python:${PYTHON_VERSION}

WORKDIR /app
COPY ./api /app
RUN pip install -r requirement.txt
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "80"]
