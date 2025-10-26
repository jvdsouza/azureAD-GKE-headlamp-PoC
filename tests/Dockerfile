FROM python:3.11-slim

# Set up working directory
WORKDIR /workspace

# Make sure the directory exists and is clean
RUN rm -rf /workspace && mkdir -p /workspace

# Copy requirements
COPY requirements.txt /workspace/

# Install dependencies
RUN pip install --no-cache-dir -r /workspace/requirements.txt

# Copy the rest of the test suite
COPY . /workspace/

# Default command to run all tests
CMD ["pytest", "--maxfail=1", "--disable-warnings", "-q"]
