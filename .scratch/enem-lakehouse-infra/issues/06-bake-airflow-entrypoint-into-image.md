# 06: Bake Airflow Entrypoint into Custom Docker Image

**What to build:** Improve how the entrypoint script is configured on the Airflow image. Rather than relying on a host bind-mount (`./airflow/entrypoint.sh:/entrypoint.sh:ro`) and an runtime `entrypoint` override in `docker-compose.yml`, bake `entrypoint.sh` directly into the `enem-airflow` Docker image with guaranteed executable permissions and sanitized LF line endings. Set `pull_policy: build` on the Airflow service and add repository `.gitattributes` to prevent cross-platform CRLF checkout issues.

**Blocked by:** 05: Migrate to SparkSubmitOperator and Eliminate Direct Docker Daemon Access

**Status:** claimed

- [ ] Airflow entrypoint script copied into `/entrypoint.sh` directly in `airflow/Dockerfile`.
- [ ] Executable permissions (`chmod +x`) and LF line ending normalization (`sed -i 's/\r$//'`) enforced during image build.
- [ ] Image `ENTRYPOINT ["/entrypoint.sh"]` declared in `airflow/Dockerfile`.
- [ ] `airflow/entrypoint.sh` updated to support executing custom commands when arguments are provided (`exec "$@"`).
- [ ] Bind mount `./airflow/entrypoint.sh:/entrypoint.sh:ro` and `entrypoint:` override removed from `docker-compose.yml`.
- [ ] `pull_policy: build` added to `airflow` service in `docker-compose.yml`.
- [ ] Repository `.gitattributes` added ensuring `*.sh text eol=lf`.
- [ ] Spark image `spark/Dockerfile` also updated with line-ending sanitization for `entrypoint.sh`.
- [ ] Stack rebuilt and tested; smoke test DAG executes and completes with `success`.
