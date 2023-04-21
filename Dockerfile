FROM maven:3.8.6-eclipse-temurin-11 AS dependencies

RUN mkdir -p /var/jars
COPY pom.xml /var/jars
WORKDIR /var/jars

RUN mvn dependency:copy-dependencies

FROM eclipse-temurin:11

# busybox unzip allows us to unzip from a piped source
RUN apt-get update && apt-get install busybox

ENV CANTALOUPE_VERSION 5.0.5
ENV CANTALOUPE_URL https://github.com/cantaloupe-project/cantaloupe/releases/download/v${CANTALOUPE_VERSION}/cantaloupe-${CANTALOUPE_VERSION}.zip

RUN curl -sL "${CANTALOUPE_URL}" | busybox unzip - -d /opt

COPY cantaloupe.properties delegates.rb /etc
WORKDIR /opt/cantaloupe-${CANTALOUPE_VERSION}
EXPOSE 8182

# Twelve Monkeys ImageIO plugins for more lenient handling of JPEGs
ENV IIO_PLUGIN_VERSION 3.9.4
COPY --from=dependencies /var/jars/target/dependency/*.jar /opt/cantaloupe-${CANTALOUPE_VERSION}

ENV CLASSPATH cantaloupe-${CANTALOUPE_VERSION}.jar:imageio-core-${IIO_PLUGIN_VERSION}.jar:imageio-jpeg-${IIO_PLUGIN_VERSION}.jar:imageio-metadata-${IIO_PLUGIN_VERSION}.jar:common-image-${IIO_PLUGIN_VERSION}.jar:common-io-${IIO_PLUGIN_VERSION}.jar:common-lang-${IIO_PLUGIN_VERSION}.jar

CMD ["java", "-Dcantaloupe.config=/etc/cantaloupe.properties", "-Xmx4g", "edu.illinois.library.cantaloupe.StandaloneEntry"]
