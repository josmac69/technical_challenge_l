import argparse
import ast
from typing import List, Tuple


def two_sum(arr: List[int], target: int, verbose: bool = False) -> List[Tuple[Tuple[int, int], Tuple[int, int]]]:
    hashmap = {}
    result = []

    for i, num in enumerate(arr):
        complement = target - num
        if complement in hashmap:
            for idx in hashmap[complement]:
                result.append(((idx, i), (complement, num)))
        if num not in hashmap:
            hashmap[num] = [i]
        else:
            hashmap[num].append(i)

        if verbose:
            print("Step:", i, "Num:", num, "Complement:", complement, "Hashmap:", hashmap)

    return result


def main():
    parser = argparse.ArgumentParser(description="Find two integers in an array that sum to a target value.")
    parser.add_argument('--target', type=int, default=10, help="Target sum value (default: 10)")
    parser.add_argument('--verbose', action='store_true', help="Display detailed debug messages (default: False)")
    parser.add_argument('--array', type=str, default="[2, 7, 11, 15, -3, 8, 3, 1, 0, -1, 7, 2]",
                        help="Input string formatted as array of integers (default: [2, 7, 11, 15, -3, 8, 3, 1, 0, -1, 7, 2])")

    args = parser.parse_args()

    print(parser.description)
    print("=" * len(parser.description))
    print("Target:", args.target)
    print("Verbose:", args.verbose)
    print("Array:", args.array)
    print()

    target = args.target
    verbose = args.verbose

    try:
        arr = ast.literal_eval(args.array)
        if not isinstance(arr, list) or not all(isinstance(x, int) for x in arr):
            raise ValueError("Array should be a list of integers.")
    except (ValueError, SyntaxError) as e:
        print(f"Error parsing array: {e}")
        return

    solutions = two_sum(arr, target, verbose)

    if len(solutions) == 0:
        print("No solutions found")
    elif len(solutions) == 1:
        print("Solution:", solutions[0])
    else:
        print("All possible solutions:")
        for solution in solutions:
            print("Indices:", solution[0], "Values:", solution[1])


if __name__ == "__main__":
    main()
