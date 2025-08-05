FROM python:3.12-slim

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    POETRY_VERSION=1.8.2 \
    POETRY_HOME="/opt/poetry" \
    POETRY_CACHE_DIR=/tmp/poetry_cache \
    POETRY_VENV_IN_PROJECT=1

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    build-essential \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Poetry
RUN pip install poetry==$POETRY_VERSION poetry-dynamic-versioning

# Create core user and group
RUN groupadd -r core && useradd -r -g core -d /home/core -s /bin/bash core

# Create necessary directories
RUN mkdir -p /home/core /opt/core /opt/core/logs && \
    chown -R core:core /home/core /opt/core

# Switch to core user
USER core
WORKDIR /home/core

# Clone the repository with all submodules
RUN git clone --recursive https://github.com/eitssg/simple-cloud-kit.git sck

# Copy service script from the docker project to sck folder
COPY --chown=core:core service.sh /home/core/sck/service.sh
RUN chmod +x /home/core/sck/service.sh

# Setup Poetry virtual environment
WORKDIR /home/core/sck/sck-core-api
RUN poetry env use python3.12 && \
    poetry install --only=main,prod 

# Get the virtual environment path
RUN echo "VENV_PATH=$(poetry env info --path)" >> /home/core/.env

# Update .bashrc to activate virtual environment
RUN echo 'source /home/core/.env' >> /home/core/.bashrc && \
    echo 'source $VENV_PATH/bin/activate' >> /home/core/.bashrc && \
    echo 'cd /home/core/sck' >> /home/core/.bashrc

# Expose FastAPI port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Set working directory back to home
WORKDIR /home/core/sck

# Start the service
CMD ["/home/core/sck/service.sh"]