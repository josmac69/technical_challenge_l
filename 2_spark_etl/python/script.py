"""ETL Spark task reading from CSV and writing to PostgreSQL."""
from pyspark.sql import SparkSession
from pyspark.sql.functions import window, count
from pyspark.sql.types import StringType, LongType, TimestampType, StructType, StructField

PG_URL = "jdbc:postgresql://my_postgres:5432/main"

def calculate_metrics(input_data):
    """Calculate the metrics."""
    return input_data \
        .groupBy(window("timestamp", "10 minutes").alias("window"), "action") \
        .agg(count("*").alias("count")) \
        .select("window.start", "action", "count") \
        .orderBy("window.start", "action")

# Initialize Spark session
print("Initializing Spark session...")
spark = SparkSession.builder \
    .appName("ETLChallenge") \
    .master("local") \
    .getOrCreate()

# Read the CSV file
print("Reading the CSV file...")
input_df = spark.read \
    .option("header", "false") \
    .option("inferSchema", "true") \
    .csv("/data/events.csv") \
    .toDF("timestamp", "action")

# Calculate the metrics
print("Calculating the metrics...")
metrics_df = calculate_metrics(input_df)

# Print the results
print("Printing the results to STDOUT...")
print(metrics_df.show())

# Save the results to PostgreSQL
print("Saving the results to PostgreSQL...")
pg_properties = {
    "user": "myuser",
    "password": "mypassword",
    "driver": "org.postgresql.Driver"
}

# Check if the target table exists, and create it if not
print("Checking if the target table exists, and create it if not...")
table_exists = spark.catalog.tableExists("metrics")
if not table_exists:
    print("Table does not exist, creating it...")

    # Define the schema for the empty DataFrame
    schema = StructType([
        StructField("start", TimestampType(), True),
        StructField("action", StringType(), True),
        StructField("count", LongType(), True)
    ])

    # Create an empty DataFrame with the defined schema
    empty_df = spark.createDataFrame([], schema)

    # Write the empty DataFrame to create the table in PostgreSQL
    empty_df.write \
        .jdbc(PG_URL, "metrics", mode="overwrite", properties=pg_properties)

# Write the actual data to the table
print("Writing the actual data to the table...")
metrics_df.write \
    .jdbc(PG_URL, "metrics", mode="overwrite", properties=pg_properties)

# Stop Spark session
print("Stopping Spark session...")
spark.stop()
