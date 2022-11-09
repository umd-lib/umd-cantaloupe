FROM eclipse-temurin:11

# busybox unzip allows us to unzip from a piped source
RUN apt-get update && apt-get install busybox

ENV CANTALOUPE_VERSION 5.0.5
ENV CANTALOUPE_URL https://github.com/cantaloupe-project/cantaloupe/releases/download/v${CANTALOUPE_VERSION}/cantaloupe-${CANTALOUPE_VERSION}.zip

RUN curl -sL "${CANTALOUPE_URL}" | busybox unzip - -d /opt

COPY cantaloupe.properties delegates.rb /etc
WORKDIR /opt/cantaloupe-${CANTALOUPE_VERSION}
RUN ln -s "cantaloupe-${CANTALOUPE_VERSION}.jar" "cantaloupe.jar"
EXPOSE 8182

CMD ["java", "-Dcantaloupe.config=/etc/cantaloupe.properties", "-Xmx2g", "-jar", "cantaloupe.jar"]
