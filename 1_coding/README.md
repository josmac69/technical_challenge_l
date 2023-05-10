# Coding challenge

## Problem

You can write code in your preferred language (Python, Scala, Java or R) Write a function reverse that:

1. Given an array of integers, find the two positions/indices that sum a specific value a. To consider:
  * There is always a solution. There is only one
  * Negative values possible
  * Not previously sorted
  * It fits in memory

2. Print all possible solutions if there more than one.

3. Describe a solution for the previous case when the data does not fit in memory.

## Solution

After testing some examples I decided to create solution which can handle all cases.
* File script.py contains the solution written in python.
* Using command line parameter `--help` you can see the usage of the script:
```
$ python3 script.py --help
usage: script.py [-h] [--target TARGET] [--verbose] [--array ARRAY]

Find two integers in an array that sum to a target value.

options:
  -h, --help       show this help message and exit
  --target TARGET  Target sum value (default: 10)
  --verbose        Display detailed debug messages (default: False)
  --array ARRAY    Input string formatted as array of integers (default: [2, 7, 11, 15, -3, 8, 3, 1, 0, -1, 7, 2])
```
* Main processing is embedded in the function two_sum which takes 3 arguments:
  * array of integers,
  * target value
  * verbose True/False.
  * The function returns a list of tuples with indices of elements which sum to the target value. If there are no solutions, the function returns an empty list.

### Makefile
* Makefile contains following commands:
  * `make pylint` - run pylint for the script
  * `make pylint SCRIPT=test_script.py` - run pylint for the unit test script
  * `make run` - run the script with default parameters
  * `make run ARGS="--target 6 --verbose --array='[1,1,1,5,-1,7]'"` - run the script with custom parameters
  * `make unittest` - run unit tests

### Discussion of huge data sets
Regarding the case where the data does not fit in memory, we can consider some of the following solutions:

* We can external sorting algorithm (such as merge sort) to sort the data on disk. It can sort the data in chunks that fit in memory and merge those sorted chunks into a single sorted file.

* Once the data is sorted, perform a two-pointer approach to find the two elements that sum to the target value. Read the first and last elements of the sorted file, and if their sum is greater than the target, move the pointer at the end backward. If their sum is less than the target, move the pointer at the beginning forward. Repeat until you find a pair of elements that add up to the target value.

* To find all possible solutions, you can keep iterating in a similar manner, keeping track of the pairs of elements that add up to the target value.

