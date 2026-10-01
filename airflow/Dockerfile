# syntax=docker/dockerfile:1
ARG AIRFLOW_BASE_IMAGE=apache/airflow:3.3.2
FROM spark-dist AS spark-dist
FROM ${AIRFLOW_BASE_IMAGE}

USER root

ARG AIRFLOW_VERSION=3.3.2

ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV SPARK_HOME=/opt/spark
ENV PATH="${SPARK_HOME}/bin:${JAVA_HOME}/bin:${PATH}"

# Install Java 17 runtime for the Spark submission client
RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates curl openjdk-17-jre-headless procps && \
    rm -rf /var/lib/apt/lists/*

# Re-use Spark distribution and pre-baked Iceberg/Hadoop AWS JARs directly from enem-spark
COPY --from=spark-dist /opt/spark /opt/spark
RUN chmod -R a+rX /opt/spark

# Copy entrypoint script, strip potential CRLF line endings, and ensure executable permissions
COPY entrypoint.sh /entrypoint.sh
RUN sed -i 's/\r$//' /entrypoint.sh && chmod a+rx /entrypoint.sh

USER airflow

# Install Airflow Spark provider pinned to the image's Airflow constraints
RUN airflow_python_version="$(python -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')" && \
    pip install --no-cache-dir \
      "apache-airflow==${AIRFLOW_VERSION}" \
      "apache-airflow-providers-apache-spark==6.3.2" \
      --constraint "https://raw.githubusercontent.com/apache/airflow/constraints-${AIRFLOW_VERSION}/constraints-${airflow_python_version}.txt"

ENTRYPOINT ["/entrypoint.sh"]
