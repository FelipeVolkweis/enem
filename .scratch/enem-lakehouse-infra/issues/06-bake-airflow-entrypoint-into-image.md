# 06: Bake Airflow Entrypoint into Custom Docker Image

**What to build:** Improve how the entrypoint script is configured on the Airflow image. Rather than relying on a host bind-mount (`./airflow/entrypoint.sh:/entrypoint.sh:ro`) and an runtime `entrypoint` override in `docker-compose.yml`, bake `entrypoint.sh` directly into the `enem-airflow` Docker image with guaranteed executable permissions and sanitized LF line endings. Set `pull_policy: build` on the Airflow service and add repository `.gitattributes` to prevent cross-platform CRLF checkout issues.

**Blocked by:** 05: Migrate to SparkSubmitOperator and Eliminate Direct Docker Daemon Access

**Status:** resolved

- [x] Airflow entrypoint script copied into `/entrypoint.sh` directly in `airflow/Dockerfile`.
- [x] Executable permissions (`chmod +x`) and LF line ending normalization (`sed -i 's/\r$//'`) enforced during image build.
- [x] Image `ENTRYPOINT ["/entrypoint.sh"]` declared in `airflow/Dockerfile`.
- [x] `airflow/entrypoint.sh` updated to support executing custom commands when arguments are provided (`exec "$@"`).
- [x] Bind mount `./airflow/entrypoint.sh:/entrypoint.sh:ro` and `entrypoint:` override removed from `docker-compose.yml`.
- [x] `pull_policy: build` added to `airflow` service in `docker-compose.yml`.
- [x] Repository `.gitattributes` added ensuring `*.sh text eol=lf`.
- [x] Spark image `spark/Dockerfile` also updated with line-ending sanitization for `entrypoint.sh`.
- [x] Stack rebuilt and tested; smoke test DAG executes and completes with `success`.

## Answer

Successfully improved the entrypoint setup for the Airflow image:
- Baked `airflow/entrypoint.sh` directly into `/entrypoint.sh` (with `/opt/airflow/entrypoint.sh` symlink) inside `airflow/Dockerfile`.
- Added CRLF stripping (`sed -i 's/\r$//'`) and executable permissions (`chmod a+rx`) to prevent Windows/cross-platform interpreter lookup failures (`/bin/bash\r: bad interpreter`).
- Configured image-level `ENTRYPOINT ["/entrypoint.sh"]` in `airflow/Dockerfile`.
- Updated `airflow/entrypoint.sh` to allow arbitrary commands (`exec "$@"`) while executing migrations and standalone mode by default.
- Removed the brittle host file bind-mount (`./airflow/entrypoint.sh:/entrypoint.sh:ro`) and `entrypoint:` override from `docker-compose.yml`.
- Added `pull_policy: build` to `airflow` service in `docker-compose.yml` to guarantee automatic local image building across environments.
- Added `.gitattributes` to enforce Unix LF line endings for shell scripts (`*.sh text eol=lf`).
- Rebuilt containers and verified end-to-end execution of `iceberg_lakehouse_smoke_test` DAG to `success`.
