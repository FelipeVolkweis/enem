import sys
from pyspark.sql import SparkSession

def main():
    print("=" * 60)
    print("Starting Iceberg + MinIO PySpark Verification Script")
    print("=" * 60)

    # Spark defaults configured in /opt/spark/conf/spark-defaults.conf
    # will automatically wire the 'demo' REST catalog and MinIO S3 credentials
    spark = SparkSession.builder \
        .appName("IcebergVerification") \
        .getOrCreate()

    spark.sparkContext.setLogLevel("WARN")

    print("\n[1/5] Current Catalogs & Namespaces:")
    spark.sql("SHOW NAMESPACES IN demo").show()

    print("\n[2/5] Creating Database 'demo.enem_dw'...")
    spark.sql("CREATE NAMESPACE IF NOT EXISTS demo.enem_dw")

    print("\n[3/5] Creating Iceberg Table 'demo.enem_dw.smoke_test'...")
    spark.sql("DROP TABLE IF EXISTS demo.enem_dw.smoke_test")
    spark.sql("""
        CREATE TABLE demo.enem_dw.smoke_test (
            id INT,
            student_name STRING,
            score DOUBLE,
            created_at TIMESTAMP
        ) USING iceberg
        PARTITIONED BY (id)
    """)

    print("\n[4/5] Inserting Sample Records...")
    spark.sql("""
        INSERT INTO demo.enem_dw.smoke_test VALUES 
        (1, 'Alice Silva', 850.5, current_timestamp()),
        (2, 'Bruno Santos', 720.0, current_timestamp()),
        (3, 'Carla Souza', 910.2, current_timestamp())
    """)

    print("\n[5/5] Querying Back Records from Iceberg Table:")
    df = spark.sql("SELECT * FROM demo.enem_dw.smoke_test ORDER BY id")
    df.show(truncate=False)

    # Validate Schema
    expected_fields = {"id", "student_name", "score", "created_at"}
    actual_fields = set(df.columns)
    if expected_fields != actual_fields:
        print(f"ERROR: Schema mismatch! Expected {expected_fields}, got {actual_fields}")
        sys.exit(1)
    print("Schema Verification: PASSED (columns match expected schema)")

    count = df.count()
    print(f"Total Rows Verified: {count}")
    if count != 3:
        print(f"ERROR: Expected 3 rows, but got {count}")
        sys.exit(1)

    print("\n[Bonus] Inspecting Iceberg Snapshots Metadata:")
    spark.sql("SELECT snapshot_id, parent_id, operation, summary['total-records'] as total_records FROM demo.enem_dw.smoke_test.snapshots").show(truncate=False)

    print("=" * 60)
    print("✅ ICEBERG SMOKE TEST SUCCESSFUL!")
    print("=" * 60)
    spark.stop()

if __name__ == "__main__":
    main()
