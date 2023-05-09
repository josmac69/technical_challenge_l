"""Unit tests for pyspark script"""
import unittest
import os
from pyspark.sql import SparkSession
from pyspark.sql.types import Row
from script import calculate_metrics

os.environ['PYSPARK_SUBMIT_ARGS'] = '--packages org.apache.spark:spark-sql_2.12:3.1.1 pyspark-shell'
print("PYSPARK_SUBMIT_ARGS: ", os.environ['PYSPARK_SUBMIT_ARGS'])

print("class TestETLSparkTask(unittest.TestCase)")
class TestETLSparkTask(unittest.TestCase):
    """Unit tests for pyspark script"""
    def setUp(self):
        self.spark = SparkSession.builder \
            .appName("ETLChallengeUnitTest") \
            .config("spark.jars.ivy", "/opt/bitnami/spark/ivy-cache") \
            .master("local") \
            .getOrCreate()
        self.sample_data = [
            Row(timestamp="2021-01-01 12:00:00", action="click"),
            Row(timestamp="2021-01-01 12:05:00", action="click"),
            Row(timestamp="2021-01-01 12:10:00", action="view"),
            Row(timestamp="2021-01-01 12:15:00", action="click")
        ]

    def tearDown(self):
        """Stop Spark session"""
        self.spark.stop()

    def test_calculate_metrics(self):
        """Test calculate_metrics function"""
        input_df = self.spark.createDataFrame(self.sample_data)
        metrics_df = calculate_metrics(input_df)

        expected_data = [
            {"start": "2021-01-01 12:00:00", "action": "click", "count": 2},
            {"start": "2021-01-01 12:10:00", "action": "view", "count": 1},
            {"start": "2021-01-01 12:10:00", "action": "click", "count": 1}
        ]
        expected_df = self.spark.createDataFrame(expected_data)

        self.assertTrue(metrics_df.subtract(expected_df).rdd.isEmpty())
        self.assertTrue(expected_df.subtract(metrics_df).rdd.isEmpty())

if __name__ == "__main__":
    print("unittest.main()")
    unittest.main()
