#!/bin/bash

# Create the cache directory and grant write permissions
mkdir -p /home/spark/.ivy2/cache
chmod -R 777 /home/spark/.ivy2/cache

$SPARK_HOME/bin/spark-submit \
  --packages org.postgresql:postgresql:42.2.18 \
  --master local[*] \
  /app/script.py
