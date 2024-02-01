# Use the official Python image as the base image
FROM python:3.8-slim

# Set the working directory in the container
WORKDIR /app

# Copy the Python script and requirements file into the container at /app
# COPY getall-monitor.py /app/getall.py
COPY metrics.py /app/metrics.py

# Install required Python packages
RUN pip install prometheus_client requests

# Expose the port where Prometheus will access the metrics
EXPOSE 8000

# Run your Python script when the container launches
CMD ["python", "/app/metrics.py"]
