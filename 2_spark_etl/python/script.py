"""ETL Spark task reading from CSV and writing to PostgreSQL."""
from pyspark.sql import SparkSession
from pyspark.sql.functions import window, count, avg, desc
from pyspark.sql.types import StringType, LongType, TimestampType, StructType, StructField

PG_URL = "jdbc:postgresql://my_postgres:5432/main"

def calculate_metrics(input_data):
    """Calculate the metrics."""
    # Group by window and action, and count the number of actions
    metrics_df = input_data \
        .groupBy(window("timestamp", "10 minutes").alias("window"), "action") \
        .agg(count("*").alias("count")) \
        .select("window.start", "action", "count") \
        .withColumnRenamed("window.start", "start") \
        .orderBy("start", "action")

    # Compute the average number of actions each 10 minutes
    avg_metrics_df = metrics_df \
        .groupBy("start") \
        .agg(avg("count").alias("avg_count")) \
        .orderBy("start")

    # Compute the top 10 minutes with a bigger amount of "open" action
    top_open_df = metrics_df \
        .filter(metrics_df.action == "open") \
        .orderBy(desc("count")) \
        .limit(10)

    return metrics_df, avg_metrics_df, top_open_df

def main():
    """Main function."""
    # Initialize Spark session
    print("Initializing Spark session...")
    spark = SparkSession.builder \
        .appName("ETLChallenge") \
        .master("local") \
        .getOrCreate()

    # Read the CSV file
    print("Reading the CSV file...")
    input_df = spark.read \
        .option("header", "true") \
        .option("inferSchema", "true") \
        .csv("/data/events.csv") \
        .toDF("timestamp", "action")

    # Calculate the metrics
    print("Calculating the metrics...")
    metrics_df, avg_metrics_df, top_open_df = calculate_metrics(input_df)

    # Print the results
    print("Printing the results to STDOUT...")
    print("Metrics:")
    print(metrics_df.show())
    print("Average Metrics:")
    print(avg_metrics_df.show())
    print("Top 10 Minutes with 'open' action:")
    print(top_open_df.show())

    # Save the results to PostgreSQL
    print("Saving the results to PostgreSQL...")
    pg_properties = {
        "user": "myuser",
        "password": "mypassword",
        "driver": "org.postgresql.Driver"
    }

    # Check if the target table exists, and create it if not
    print("Checking if the target table exists, and create it if not...")
    try:
        df = spark.read \
            .jdbc(PG_URL, "metrics", properties=pg_properties)
        table_exists = True
    except Exception as e:
        table_exists = False

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
        .jdbc(PG_URL,"metrics", mode="overwrite", properties=pg_properties)

    # Write the average metrics to a new table
    print("Writing the average metrics to a new table...")
    avg_metrics_df.write \
        .jdbc(PG_URL, "avg_metrics", mode="overwrite", properties=pg_properties)

    # Write the top 10 'open' action minutes to a new table
    print("Writing the top 10 'open' action minutes to a new table...")
    top_open_df.write \
        .jdbc(PG_URL, "top_open", mode="overwrite", properties=pg_properties)

    # Stop Spark session
    print("Stopping Spark session...")
    spark.stop()

if __name__ == "__main__":
    print("main()")
    main()
