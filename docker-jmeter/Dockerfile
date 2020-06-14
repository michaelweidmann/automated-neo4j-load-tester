FROM openjdk:latest

COPY ./bin /usr/src/jmeter/bin
COPY ./lib /usr/src/jmeter/lib
COPY ./assets/data.csv /usr/src/jmeter
COPY ./assets/testPlan.jmx /usr/src/jmeter
RUN mkdir /usr/src/jmeter/reports
