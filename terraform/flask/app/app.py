from flask import Flask, jsonify
from redis import Redis
import prometheus_client
from prometheus_client import Counter, Histogram
import os
import time

app = Flask(__name__)

# Redis connection
redis_client = Redis(
    host=os.getenv('REDIS_HOST', 'redis'),
    port=int(os.getenv('REDIS_PORT', 6379)),
    password=os.getenv('REDIS_PASSWORD'),
    decode_responses=True
)

# Prometheus metrics
REQUEST_COUNT = Counter('flask_request_count', 'App Request Count', ['method', 'endpoint', 'http_status'])
REQUEST_LATENCY = Histogram('flask_request_latency_seconds', 'Request latency')

# Expose metrics endpoint
@app.route('/metrics')
def metrics():
    return prometheus_client.generate_latest()

@app.route('/health')
def health():
    return jsonify({"status": "healthy"}), 200

@app.route('/')
@REQUEST_LATENCY.time()
def hello():
    try:
        visits = redis_client.incr('visits')
        REQUEST_COUNT.labels(method='GET', endpoint='/', http_status=200).inc()
        return jsonify({
            "message": "Hello from Flask!",
            "visits": visits
        })
    except Exception as e:
        REQUEST_COUNT.labels(method='GET', endpoint='/', http_status=500).inc()
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
