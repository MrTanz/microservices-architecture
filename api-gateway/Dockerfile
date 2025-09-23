# Build con Maven
FROM maven:3.9.5-eclipse-temurin-17 AS builder

WORKDIR /build

COPY pom.xml .
COPY src ./src

RUN mvn clean package -DskipTests

# Runtime Java
FROM openjdk:17-jdk-slim

WORKDIR /app

COPY --from=builder /build/target/gateway-0.0.1-SNAPSHOT.jar api-gateway.jar

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "api-gateway.jar"]
