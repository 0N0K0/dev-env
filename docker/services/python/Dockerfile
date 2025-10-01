ARG PYTHON_VERSION=latest
ARG SOURCE_DIR=api
FROM python:${PYTHON_VERSION}

WORKDIR /app
COPY ./${SOURCE_DIR} /app

# Dépendances gérées via Homebrew
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "80"]
