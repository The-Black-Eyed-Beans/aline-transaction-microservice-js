FROM openjdk:11-jre-slim

ENV APP_PORT=8073

COPY transaction-microservice/target/*.jar app.jar
ENTRYPOINT ["java", "-jar", "/app.jar"]