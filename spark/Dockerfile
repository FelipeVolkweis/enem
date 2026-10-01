FROM apache/spark:4.1.3

USER root

# Install curl to fetch Iceberg and S3A jars
RUN apt-get update && apt-get install -y --no-install-recommends curl procps && rm -rf /var/lib/apt/lists/*

# Pre-bake required Iceberg and AWS/Hadoop runtime jars
ENV ICEBERG_VERSION=1.12.0
ENV HADOOP_VERSION=3.4.2

RUN curl -fSL "https://repo1.maven.org/maven2/org/apache/iceberg/iceberg-spark-runtime-4.1_2.13/${ICEBERG_VERSION}/iceberg-spark-runtime-4.1_2.13-${ICEBERG_VERSION}.jar" \
    -o /opt/spark/jars/iceberg-spark-runtime-4.1_2.13-${ICEBERG_VERSION}.jar && \
    curl -fSL "https://repo1.maven.org/maven2/org/apache/iceberg/iceberg-aws-bundle/${ICEBERG_VERSION}/iceberg-aws-bundle-${ICEBERG_VERSION}.jar" \
    -o /opt/spark/jars/iceberg-aws-bundle-${ICEBERG_VERSION}.jar && \
    curl -fSL "https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/${HADOOP_VERSION}/hadoop-aws-${HADOOP_VERSION}.jar" \
    -o /opt/spark/jars/hadoop-aws-${HADOOP_VERSION}.jar

# Copy default Spark configuration
COPY spark-defaults.conf /opt/spark/conf/spark-defaults.conf
COPY entrypoint.sh /opt/spark/entrypoint.sh
RUN chmod +x /opt/spark/entrypoint.sh

# Create jobs and data mount directories with appropriate permissions
RUN mkdir -p /opt/spark/jobs /opt/spark/data && \
    chown -R 185:root /opt/spark/conf /opt/spark/jars /opt/spark/jobs /opt/spark/data

USER 185

ENTRYPOINT ["/opt/spark/entrypoint.sh"]
