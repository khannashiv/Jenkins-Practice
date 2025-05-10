# Base image
FROM python:3.10-slim

# Set working directory inside the container
WORKDIR /app

# Copy only what's needed
COPY requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the app
COPY . .

# Expose the port Gunicorn will listen on
EXPOSE 8000

# Run the app with Gunicorn
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "wsgi:app"]

