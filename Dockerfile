FROM debian:stable-slim

# Install basic tools and Flutter dependencies
RUN apt-get update && apt-get install -y \
  curl git unzip xz-utils zip libglu1-mesa ca-certificates && \
  apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Flutter
RUN git clone https://github.com/flutter/flutter.git /usr/local/flutter

# Add Flutter, Dart, and pub cache (dhttpd) to PATH
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:/root/.pub-cache/bin:${PATH}"

# Make tar ignore ownership change failures (fixes gradle-wrapper.tgz chown errors)
ENV TAR_OPTIONS="--no-same-owner"

# Enable web and precache web artifacts
RUN flutter config --enable-web
RUN flutter precache --web

# Set app working directory
WORKDIR /app

# Copy project files
COPY . .

# Build Flutter web
RUN flutter build web --release

# Serve build/web with dhttpd (simple Dart HTTP server)
RUN dart pub global activate dhttpd

EXPOSE 8080

# IMPORTANT: bind to 0.0.0.0 so Render can see port 8080
CMD ["dhttpd", "--path", "build/web", "--port", "8080", "--host", "0.0.0.0"]
