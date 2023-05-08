#!/bin/bash

$SPARK_HOME/bin/spark-submit \
  --packages org.postgresql:postgresql:42.2.18 \
  --master local[*] \
  /app/script.py
