# dbt + adapter Doris, ghim phiên bản (chạy: scripts/dbt_doris.sh)
FROM python:3.11-slim
RUN pip install --no-cache-dir dbt-doris==1.0.0 dbt-core==1.12.6 dbt-adapters==1.24.5 dbt-common==1.39.0 mysql-connector-python==26.10.0 \
 && pip freeze | grep -iE '^(dbt-|mysql)' > /dbt-versions.txt
WORKDIR /usr/app
ENTRYPOINT ["dbt"]
