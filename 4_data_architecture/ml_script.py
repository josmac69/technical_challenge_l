"""Predicts the next time a user will use the parking lot based on their historical usage pattern"""
import datetime
import pandas as pd
import statsmodels.api as sm
import numpy as np

def load_data(data_file):
    """Loads the parking data from a CSV file into a pandas DataFrame"""
    # Load the data into a pandas DataFrame
    print("Loading data...")
    data = pd.read_csv(data_file, parse_dates=['entry_time', 'exit_time'])

    # Add a new feature representing the day of the week
    data['day_of_week'] = data['entry_time'].dt.dayofweek

    # Group the data by user_id and day_of_week and calculate the average time between each entry and exit time
    user_data = data \
        .groupby(['user_id', 'day_of_week']).apply(lambda x: x['exit_time'] - x['entry_time']) \
        .reset_index(name='usage_time')
    user_data = user_data \
        .groupby('user_id') \
        .apply(lambda x: x.set_index('day_of_week')['usage_time'].to_dict())

    return user_data

def train_models(user_data):
    """Trains an ARIMA model for each user based on their historical usage pattern"""
    # Train an ARIMA model on each user's usage pattern
    print("Training models:")
    models = {}
    for user_id, usage_times in user_data.items():
        try:
            usage_times = [usage_times.get(i, pd.Timedelta(seconds=0)) for i in range(7)] # fill missing days with 0 seconds usage
            usage_times = [t.total_seconds() for t in usage_times] # convert timedelta to seconds
            usage_times = np.nan_to_num(usage_times, nan=0.0, posinf=0.0, neginf=0.0) # replace NaN and infinite values with 0
            model = sm.tsa.ARIMA(usage_times, order=(1, 0, 1), enforce_stationarity=False, enforce_invertibility=False).fit()
            models[user_id] = model
        except Exception as error_msg:
            # Ignore users with insufficient data
            print(f"Error occurred while training model for User {user_id}: {str(error_msg)}")
            print(f"User {user_id} has insufficient data to train a model")

    return models

def predict_parking_usage(models, user_data):
    """Predicts the next time a user will use the parking lot based on their historical usage pattern"""
    # Predict the next usage time and duration for each user
    print("Predictions:")
    current_time = datetime.datetime.now()
    for user_id, model in models.items():
        print(f"Predicting for User {user_id}")
        usage_times = user_data[user_id]
        if not usage_times:
            print(f"User {user_id} has insufficient data to make a prediction")
            continue
        current_day = datetime.datetime.now().weekday()
        next_day = (current_day + 1) % 7 # predict for the next day
        next_time = model.predict(start=len(usage_times), end=len(usage_times), typ='levels')[0]
        next_time = current_time.replace(hour=int(next_time) %24, minute=int((next_time - int(next_time)) * 60))
        next_time = next_time + datetime.timedelta(days=next_day-current_day) # add the number of days until the next prediction day

        print(f"User {user_id} is predicted to use the parking lot next on {next_time.strftime('%A')} at {next_time}")

        # Calculate the next duration based on the user's historical usage pattern
        usage_times = [t.total_seconds() for t in usage_times.values()]
        next_duration = int(np.mean(usage_times) / 60) # average duration in minutes
        duration_in_hours = next_duration // 60
        remaining_minutes = next_duration % 60
        print(f"User {user_id} is predicted to stay for {next_duration} minutes ({duration_in_hours} hours and {remaining_minutes} minutes)")

if __name__ == "__main__":
    data_file = 'parking_data.csv'
    main_user_data = load_data(data_file)
    models = train_models(main_user_data)
    predict_parking_usage(models, main_user_data)
