# redhat-openjdk18-openshift:1.2
FROM openshift/base-centos7

LABEL maintainer="Eric George <eric@nolab.org>"

ENV DROPWIZ_BUILDER_VERSION 1.0

LABEL io.k8s.description="Platform for building Dropwizard apps" \
      io.k8s.display-name="Dropwizard Builder 1.0" \
      io.openshift.expose-services="8080:http" \
      io.openshift.tags="builder,dropwizard"

EXPOSE 8080

ENV JAVA_VERSON 1.8.0
ENV MAVEN_VERSION 3.3.9

RUN yum update -y && \
    yum install -y curl && \
    yum install -y java-$JAVA_VERSON-openjdk java-$JAVA_VERSON-openjdk-devel && \
    yum clean all

RUN curl -fsSL https://archive.apache.org/dist/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz | tar xzf - -C /usr/share && \
    mv /usr/share/apache-maven-$MAVEN_VERSION /usr/share/maven && \
    ln -s /usr/share/maven/bin/mvn /usr/bin/mvn

ENV JAVA_HOME /usr/lib/jvm/java
ENV MAVEN_HOME /usr/share/maven

# s2i default WORKDIR is /opt/app-root/src
# we want our deployment artifacts to be in /opt/app-root/dist
ENV DEPLOY_DIR /opt/app-root/dist
RUN mkdir -p $DEPLOY_DIR

# Default runtime vars
ENV DW_ACT server
ENV DW_CONFIG ${DEPLOY_DIR}/config.yml

# Add configuration files, bashrc and other tweaks
COPY ./s2i/bin/ $STI_SCRIPTS_PATH

RUN chown -R 1001:0 ../
USER 1001

# Set the default CMD to print the usage of the language image
CMD $STI_SCRIPTS_PATH/usage
