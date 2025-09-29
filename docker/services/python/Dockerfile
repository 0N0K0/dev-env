ARG PYTHON_VERSION=latest
ARG SOURCE_DIR=api
FROM python:${PYTHON_VERSION}

WORKDIR /app
COPY ./${SOURCE_DIR} /app
# Dependencies managed locally with Homebrew pip/poetry
# Only install runtime essentials in container
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "80"]
