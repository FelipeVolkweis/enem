# 02: Build Spark Container with Pre-baked Iceberg & S3A Runtimes

**What to build:** A customized Apache Spark container packaging pre-cached Iceberg Spark runtime dependencies and Hadoop AWS / S3A connector bundles. The container is configured to register the Iceberg REST Catalog and MinIO S3 storage directly in Spark SQL sessions, accompanied by a PySpark verification script that demonstrates end-to-end table creation, data insertion, and querying.

**Blocked by:** 01: Provision MinIO Object Storage and Iceberg REST Catalog

**Status:** ready-for-agent

- [ ] A dedicated `spark/Dockerfile` builds an Apache Spark image containing `iceberg-spark-runtime` and `aws-java-sdk-bundle`/`hadoop-aws` jars without relying on dynamic Maven package downloads during execution.
- [ ] Spark service is declared in `docker-compose.yml`, mounting `./jobs` and `./data`, exposing Spark Master on host port 8081 and Spark UI on host port 4040.
- [ ] Spark configuration specifies the Iceberg REST Catalog URI (`http://iceberg-rest:8181`), catalog warehouse location (`s3://warehouse/`), S3 endpoint (`http://minio:9000`), S3 path-style access, and S3 credentials.
- [ ] A PySpark verification script creates an Iceberg table, inserts a sample record, queries it back via Spark SQL, and writes underlying Parquet files and metadata manifests into MinIO.
- [ ] Running the verification script completes with zero errors and outputs the verified row.
