# 01: Provision MinIO Object Storage and Iceberg REST Catalog

**What to build:** A functional, locally accessible storage and catalog layer where an S3-compatible object store boots alongside the official Iceberg REST Catalog. MinIO automatically provisions the primary `warehouse` bucket upon container startup, and the Iceberg REST Catalog exposes its API to coordinate ACID commits and table metadata backed by that storage.

**Blocked by:** None (can start immediately)

**Status:** resolved

- [x] `docker-compose.yml` and `.env` define services and environment configuration for MinIO (`cgr.dev/chainguard/minio:latest`), MinIO client initialization (`cgr.dev/chainguard/minio-client:latest`), and Iceberg REST Catalog (`tabulario/iceberg-rest:latest`).
- [x] MinIO S3 API is exposed on host port 9000, and MinIO Console is accessible on host port 9001 with default credentials.
- [x] The initialization service waits for MinIO readiness and idempotently creates the `warehouse` bucket before terminating cleanly.
- [x] Iceberg REST Catalog service is exposed on host port 8181 and configured to point to MinIO S3 endpoint and the `warehouse` bucket.
- [x] Querying `http://localhost:8181/v1/config` returns a valid JSON response indicating the catalog is active.

## Answer

MinIO object storage and Iceberg REST Catalog services were implemented in `docker-compose.yml` backed by `.env`:
- Used Chainguard's secure public images `cgr.dev/chainguard/minio:latest` and `cgr.dev/chainguard/minio-client:latest` with healthcheck on port 9000.
- `minio-init` waits for MinIO health and creates bucket `s3://warehouse/` idempotently.
- `tabulario/iceberg-rest:latest` runs on port 8181, points to MinIO S3 endpoint (`http://minio:9000`) and the warehouse bucket.
- Verified live with `curl http://localhost:8181/v1/config` returning 200 OK and MinIO Console on port 9001.
