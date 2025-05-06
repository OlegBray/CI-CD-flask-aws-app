FROM python:3.10-slim

WORKDIR /app

# Create flask-app folder and copy code inside
RUN mkdir -p /app/flask-app
COPY backend-py /app/flask-app/backend-py
COPY frontend    /app/flask-app/frontend

# Ensure the script is executable
RUN chmod +x /app/flask-app/backend-py/start-server.sh

# Remove the bogus pkg‑resources entry so pip won't try to install it
RUN sed -i '/^pkg-resources==0\.0\.0$/d' /app/flask-app/backend-py/requirements.txt  # deletes that exact line :contentReference[oaicite:0]{index=0}

# Upgrade pip & setuptools (prevents future pkg-resources bug) :contentReference[oaicite:1]{index=1}
RUN pip install --upgrade pip setuptools

# Install backend requirements without cache
RUN pip install --no-cache-dir -r /app/flask-app/backend-py/requirements.txt

# Default command
CMD ["/app/flask-app/backend-py/start-server.sh"]
