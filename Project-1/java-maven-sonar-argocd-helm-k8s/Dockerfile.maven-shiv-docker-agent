# Base image with Java 17
FROM eclipse-temurin:17-jdk-jammy

# Install required packages: Maven and Docker CLI
RUN apt-get update && \
    apt-get install -y maven docker.io && \
    apt-get clean

# Set working directory
WORKDIR /app

# Print versions (optional sanity check)
RUN java -version && mvn -version && docker --version

# Default command
CMD ["bash"]
