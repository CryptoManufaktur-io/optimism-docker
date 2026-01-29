from prometheus_client import start_http_server, Gauge
import requests
import json
import time
import os

# Define Prometheus metrics
block_height_metric = Gauge('block_height', 'Current block height')
block_timestamp_metric = Gauge('block_timestamp', 'Current block timestamp')
block_hash_metric = Gauge('block_hash', 'Current block hash')

# URL for the API
api_url = f'http://{os.environ["NETWORK"]}:8545'

# Function to update metrics from JSON data
def update_metrics():
    try:
        # Craft the headers and data for the request
        headers = {'Content-Type': 'application/json'}
        payload = {
            'jsonrpc': '2.0',
            'method': 'eth_getBlockByNumber',
            'params': ['finalized', False],
            'id': 1
        }

        # Make the HTTP request
        response = requests.post(api_url, headers=headers, data=json.dumps(payload))
        data = response.json()

        # Update Prometheus metrics
        block_height_metric.set(int(data['result']['number'], 16))
        block_timestamp_metric.set(int(data['result']['timestamp'], 16))
        block_hash_metric.set(int(data['result']['hash'], 16))

    except Exception as e:
        print(f"Error updating metrics: {e}")

# Start Prometheus metrics server on all interfaces
if __name__ == '__main__':
    start_http_server(8000)

    # Keep the script running to periodically update metrics
    while True:
        update_metrics()
        time.sleep(60)  # Update metrics every 60 seconds
