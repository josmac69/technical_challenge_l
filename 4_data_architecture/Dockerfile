# Use a Python base image
FROM python:latest

# Copy the protobuf script and requirements file into the container
COPY requirements.txt /pip/requirements.txt

# Install required Python dependencies
RUN pip install --upgrade pip \
    && pip install --verbose -r /pip/requirements.txt

# Set the working directory
WORKDIR /app

CMD ["python3"]