"""Unit tests for script.py."""
import unittest
from script import two_sum

class TestTwoSum(unittest.TestCase):
    """Unit tests for two_sum function."""

    def test_two_sum(self):
        """Test two_sum function."""
        # Test case 1
        print("Test case 1")
        arr = [2, 7, 11, 15]
        target = 9
        expected_result = [((0, 1), (2, 7))]
        actual_result = two_sum(arr, target)
        print("Expected result:", expected_result)
        print("Actual result:", actual_result)
        self.assertEqual(actual_result, expected_result)

        # Test case 2
        print("Test case 2")
        arr = [2, 7, 11, 15, -3, 8, 3, 1, 0, -1, 7, 2]
        target = 6
        expected_result = [((1, 9), (7, -1)), ((9, 10), (-1, 7))]
        actual_result = two_sum(arr, target)
        print("Expected result:", expected_result)
        print("Actual result:", actual_result)
        self.assertEqual(actual_result, expected_result)

        # Test case 3
        print("Test case 3")
        arr = [2, 7, 11, 15]
        target = 50
        expected_result = []
        actual_result = two_sum(arr, target)
        print("Expected result:", expected_result)
        print("Actual result:", actual_result)
        self.assertEqual(actual_result, expected_result)

        # Test case 4
        print("Test case 4")
        arr = [2, 2, 2, 2, 2, 2]
        target = 4
        expected_result = [((0, 1), (2, 2)), ((0, 2), (2, 2)), ((1, 2), (2, 2)),
                           ((0, 3), (2, 2)), ((1, 3), (2, 2)), ((2, 3), (2, 2)),
                           ((0, 4), (2, 2)), ((1, 4), (2, 2)), ((2, 4), (2, 2)),
                           ((3, 4), (2, 2)), ((0, 5), (2, 2)), ((1, 5), (2, 2)),
                           ((2, 5), (2, 2)), ((3, 5), (2, 2)), ((4, 5), (2, 2))]
        actual_result = two_sum(arr, target)
        print("Expected result:", expected_result)
        print("Actual result:", actual_result)
        self.assertEqual(actual_result, expected_result)

        # Test case 5
        print("Test case 5")
        arr = []
        target = 10
        expected_result = []
        actual_result = two_sum(arr, target)
        print("Expected result:", expected_result)
        print("Actual result:", actual_result)
        self.assertEqual(actual_result, expected_result)

if __name__ == "__main__":
    unittest.main()
