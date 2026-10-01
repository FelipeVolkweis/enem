# 02: Build Spark Container with Pre-baked Iceberg & S3A Runtimes

**What to build:** A customized Apache Spark container packaging pre-cached Iceberg Spark runtime dependencies and Hadoop AWS / S3A connector bundles. The container is configured to register the Iceberg REST Catalog and MinIO S3 storage directly in Spark SQL sessions, accompanied by a PySpark verification script that demonstrates end-to-end table creation, data insertion, and querying.

**Blocked by:** 01: Provision MinIO Object Storage and Iceberg REST Catalog

**Status:** resolved

- [x] A dedicated `spark/Dockerfile` builds an Apache Spark image containing `iceberg-spark-runtime` and `aws-java-sdk-bundle`/`hadoop-aws` jars without relying on dynamic Maven package downloads during execution.
- [x] Spark service is declared in `docker-compose.yml`, mounting `./jobs` and `./data`, exposing Spark Master on host port 8081 and Spark UI on host port 4040.
- [x] Spark configuration specifies the Iceberg REST Catalog URI (`http://iceberg-rest:8181`), catalog warehouse location (`s3://warehouse/`), S3 endpoint (`http://minio:9000`), S3 path-style access, and S3 credentials.
- [x] A PySpark verification script creates an Iceberg table, inserts a sample record, queries it back via Spark SQL, and writes underlying Parquet files and metadata manifests into MinIO.
- [x] Running the verification script completes with zero errors and outputs the verified row.

## Answer

Built and verified customized Spark 3.5.3 container:
- `spark/Dockerfile` pre-downloads `iceberg-spark-runtime-3.5_2.12-1.6.1.jar`, `iceberg-aws-bundle-1.6.1.jar`, `hadoop-aws-3.3.4.jar`, and `aws-java-sdk-bundle-1.12.262.jar`.
- `spark/spark-defaults.conf` pre-wires the `demo` REST catalog, MinIO S3 credentials, endpoint, and path-style access.
- `spark/entrypoint.sh` starts the Spark Master on port 7077 (Web UI: 8081) and a Worker daemon.
- Created `jobs/test_iceberg.py` PySpark verification script. Executing it created namespace `demo.enem_dw`, table `smoke_test`, inserted 3 partitioned records, queried them back, and produced Iceberg Parquet and Avro/JSON metadata files directly in `s3://warehouse/`.
