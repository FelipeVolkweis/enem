FROM apache/superset:6.1.0

# The image ships without database drivers; add Trino's into Superset's venv.
USER root
RUN uv pip install --no-cache --python /app/.venv/bin/python trino==0.339.0
USER superset
