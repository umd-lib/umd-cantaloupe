FROM maven:3-eclipse-temurin-11 AS dependencies

RUN mkdir -p /var/jars
COPY pom.xml /var/jars
WORKDIR /var/jars

RUN mvn dependency:copy-dependencies

FROM eclipse-temurin:11

# busybox unzip allows us to unzip from a piped source
RUN apt-get update \
 && apt-get install -y --no-install-recommends busybox \
 && apt-get install -y --no-install-recommends --only-upgrade ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# Address the eMudhra intermediate CA key compromise: remove both affected roots
# from the JDK's own cacerts. Match on the certificate subject, because alias
# naming differs between JDK builds.
RUN keytool -list -v -cacerts -storepass changeit \
    | awk '/^Alias name:/ { a = substr($0, 13) } /^Owner: CN=(emSign ECC Root CA - G3|AAA Certificate Services),/ { print a }' \
    | while IFS= read -r alias; do \
        echo "Removing from Java cacerts: $alias"; \
        keytool -delete -cacerts -storepass changeit -alias "$alias"; \
      done \
 && ! keytool -list -v -cacerts -storepass changeit | grep -qE '^Owner: CN=(emSign ECC Root CA - G3|AAA Certificate Services),'
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
