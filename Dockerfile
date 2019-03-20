# Simple Dockerfile
# To run:
# docker build ./ -t recollections
# docker run -it -v$(pwd):/code --entrypoint /bin/bash recollections
# Then run: pytest in shell to test.

FROM python:3.6-slim

# coincurve requires libgmp
RUN apt-get update && \
    apt-get install -y --no-install-recommends apt-utils gcc libc6-dev libc-dev libssl-dev libgmp-dev && \
    rm -rf /var/lib/apt/lists/*

ADD . /code

WORKDIR /code

RUN pip install --upgrade pip && \
    pip install -r requirements.txt && \
    apt-get purge -y --auto-remove apt-utils gcc libc6-dev libc-dev libssl-dev
