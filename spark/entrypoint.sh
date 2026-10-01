#!/bin/bash
set -e

echo "Starting Spark Master on port 7077 (Web UI: 8081)..."
/opt/spark/sbin/start-master.sh -h 0.0.0.0 -p 7077 --webui-port 8081

echo "Starting Spark Worker..."
/opt/spark/sbin/start-worker.sh spark://localhost:7077 --webui-port 8082

echo "Spark Master and Worker started."

# Trap termination signals to cleanly shut down
trap '/opt/spark/sbin/stop-worker.sh; /opt/spark/sbin/stop-master.sh; exit 0' SIGTERM SIGINT

# Keep container running and stream logs
exec tail -F /opt/spark/logs/*
