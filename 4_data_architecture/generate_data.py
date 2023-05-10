import csv
import datetime
import random

# Define the start and end date ranges for the records
START_DATE = datetime.datetime(2023, 3, 1, 0, 0, 0)
END_DATE = datetime.datetime(2023, 4, 30, 23, 59, 59)

# Define the user IDs
USER_IDS = [1, 2, 3, 4, 5]

# Open the output CSV file
with open('parking_data.csv', 'w', newline='') as csv_file:
    csv_writer = csv.writer(csv_file)
    csv_writer.writerow(['user_id', 'entry_time', 'exit_time'])

    # Generate records for each user
    for user_id in USER_IDS:
        # Generate one record for each day in the date range
        current_date = START_DATE
        while current_date <= END_DATE:
            # Generate a random entry and exit time for the record
            entry_time = current_date + datetime.timedelta(hours=random.randint(8, 10),
                                                           minutes=random.randint(0, 59),
                                                           seconds=random.randint(0, 59))
            exit_time = current_date + datetime.timedelta(hours=random.randint(16, 19),
                                                          minutes=random.randint(0, 59),
                                                          seconds=random.randint(0, 59))

            # Check if there is any overlap with previous records for this user
            with open('parking_data.csv', 'r') as existing_csv:
                existing_reader = csv.reader(existing_csv)
                for row in existing_reader:
                    # Skip the header row and any records for different users or dates
                    if row[0] != str(user_id) or row[1].split()[0] != entry_time.date().isoformat():
                        continue
                    # Check for overlap between the current and previous records
                    prev_entry_time = datetime.datetime.fromisoformat(row[1])
                    prev_exit_time = datetime.datetime.fromisoformat(row[2])
                    if entry_time < prev_exit_time and exit_time > prev_entry_time:
                        # If there is overlap, generate new entry and exit times and check again
                        entry_time = current_date + datetime.timedelta(hours=random.randint(8, 10),
                                                                       minutes=random.randint(0, 59),
                                                                       seconds=random.randint(0, 59))
                        exit_time = current_date + datetime.timedelta(hours=random.randint(16, 19),
                                                                      minutes=random.randint(0, 59),
                                                                      seconds=random.randint(0, 59))
                        # Restart the loop from the beginning to check for overlaps with all previous records
                        current_date = START_DATE
                        continue

            # Write the record to the CSV file
            csv_writer.writerow([user_id, entry_time, exit_time])

            # Increment the date by one day
            current_date += datetime.timedelta(days=1)
