# Test stage
FROM alpine AS test
LABEL application=todobackend

# Install basic utilities
RUN apk add --no-cache bash git

# Install build dependencies
# Had to add the cmd:pip3 to get this to work
RUN apk add --no-cache gcc python3-dev cmd:pip3 libffi-dev musl-dev linux-headers mariadb-dev
RUN pip3 install wheel

# Copy requirements
COPY /src/requirements* /build/
WORKDIR /build

# Build and install requirements
RUN pip3 wheel -r requirements_test.txt --no-cache-dir --no-input
RUN pip3 install -r requirements_test.txt -f /build --no-index --no-cache-dir

# Copy source code
COPY /src /app
WORKDIR /app

# Test entrypoint
CMD ["python3", "manage.py", "test", "--noinput"]
# CMD ["python3", "manage.py", "test", "--noinput", "--settings=todobackend.settings_test"]

# Release stage -----------------------
FROM alpine
LABEL application=todobackend

# Install operating system dependencies
RUN apk add --no-cache python3 cmd:pip3 mariadb-client bash curl bats jq

# Create app user
RUN addgroup -g 1000 app && \
    adduser -u 1000 -G app -D app
# we first create a group named app with a group ID of 1000 and then create a
# user called app with a user ID of 1000, which belongs to the app group

# Copy and install application source and pre-built dependencies
COPY --from=test --chown=app:app /build /build
COPY --from=test --chown=app:app /app /app
RUN pip3 install -r /build/requirements.txt -f /build --no-index --no-cache-dir
RUN rm -rf /build

# Create public volume
RUN mkdir /public
RUN chown app:app /public
VOLUME /public

# Set working directory and application user
WORKDIR /app
USER app
