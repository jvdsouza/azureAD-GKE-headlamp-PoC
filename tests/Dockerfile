FROM python:3.11-slim
WORKDIR /workspace

COPY requirements.txt .     # ✅ fixed
RUN pip install -r requirements.txt

RUN apt-get update && apt-get install -y curl && \
    curl -Lo /usr/local/bin/kubectl https://dl.k8s.io/release/v1.30.0/bin/linux/amd64/kubectl && \
    chmod +x /usr/local/bin/kubectl && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

CMD ["pytest", "tests/"]
