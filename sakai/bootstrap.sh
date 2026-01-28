#!/bin/bash
set -euo pipefail

MARKER=/workspace/.bootstrap_done

if [ -f "$MARKER" ]; then
  echo "[bootstrap] Already completed. Skipping."
  exit 0
fi

export DEBIAN_FRONTEND=noninteractive

echo "[bootstrap] Installing base packages"
apt-get update
apt-get install -y \
  openjdk-11-jdk \
  git \
  curl \
  unzip \
  ca-certificates

# -----------------------------
# Maven 3.8.8
# -----------------------------
MAVEN_VERSION=3.8.8
MAVEN_DIR=/opt/apache-maven-${MAVEN_VERSION}

if [ ! -d "$MAVEN_DIR" ]; then
  echo "[bootstrap] Installing Maven ${MAVEN_VERSION}"
  curl -fsSL https://downloads.apache.org/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.zip \
    -o /tmp/maven.zip
  unzip /tmp/maven.zip -d /opt
  ln -sf "$MAVEN_DIR" /opt/maven
fi

# -----------------------------
# Tomcat 9
# -----------------------------
TOMCAT_VERSION=9.0.69
TOMCAT_DIR=/opt/apache-tomcat-${TOMCAT_VERSION}

if [ ! -d "$TOMCAT_DIR" ]; then
  echo "[bootstrap] Installing Tomcat ${TOMCAT_VERSION}"
  curl -fsSL https://downloads.apache.org/tomcat/tomcat-9/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz \
    -o /tmp/tomcat.tar.gz
  tar xzf /tmp/tomcat.tar.gz -C /opt
  ln -sf "$TOMCAT_DIR" /opt/tomcat
fi

# -----------------------------
# Environment variables
# -----------------------------
cat <<'EOF' > /etc/profile.d/sakai.sh
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
export MAVEN_HOME=/opt/maven
export CATALINA_HOME=/opt/tomcat
export PATH=$MAVEN_HOME/bin:$PATH
EOF

chmod +x /etc/profile.d/sakai.sh

mkdir -p /workspace/sakai

touch "$MARKER"
echo "[bootstrap] Completed successfully"
