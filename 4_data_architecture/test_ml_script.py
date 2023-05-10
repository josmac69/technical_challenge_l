"""Unit tests for the parking predictive model script"""
import datetime
from io import StringIO
import unittest
from unittest.mock import patch
import pandas as pd
from ml_script import predict_parking_usage

class TestParkingPredictiveModel(unittest.TestCase):
    """Unit tests for the parking predictive model script"""
    def setUp(self):
        # Create test data
        self.test_data = StringIO("""user_id,entry_time,exit_time
        1,2022-01-01 09:00:00,2022-01-01 10:00:00
        1,2022-01-02 10:00:00,2022-01-02 11:00:00
        1,2022-01-03 11:00:00,2022-01-03 12:00:00
        2,2022-01-01 09:00:00,2022-01-01 10:00:00
        2,2022-01-02 10:00:00,2022-01-02 11:00:00
        2,2022-01-03 11:00:00,2022-01-03 12:00:00
        """)
        self.test_df = pd.read_csv(self.test_data, parse_dates=['entry_time', 'exit_time'])

    @patch('builtins.print')
    def test_predict_parking_usage(self, mock_print):
        """Test the predict_parking_usage function"""
        # Create expected output
        expected_output = f"""Predicting for User 1\nUser 1 is predicted to use the parking lot
            next on Monday at {datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
            \nUser 1 is predicted to stay for 60 minutes (1 hours and 0 minutes)
            \nPredicting for User 2\nUser 2 is predicted to use the parking lot
            next on Monday at {datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
            \nUser 2 is predicted to stay for 60 minutes (1 hours and 0 minutes)\n"""

        # Run the function with test data
        predict_parking_usage(self.test_df, self.test_data)

        # Check if the output is as expected
        self.assertEqual(mock_print.call_args_list[2], expected_output)

if __name__ == '__main__':
    unittest.main()
