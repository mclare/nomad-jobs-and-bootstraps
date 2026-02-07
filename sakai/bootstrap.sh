#!/usr/bin/env bash
set -euo pipefail

echo "================================================================================="
echo "[bootstrap] Starting Sakai build environment setup"

# --------------------------------------------------
# Root check
# --------------------------------------------------
if [ "${EUID:-$(id -u)}" -ne 0 ]; then
  echo "[ERROR] This script must be run as root. Exiting."
  exit 1
fi

# --------------------------------------------------
# Environment detection
# --------------------------------------------------
IS_CONTAINER=0
if grep -qE '/docker|/lxc|/kubepods|containerd' /proc/1/cgroup 2>/dev/null || [ -f /.dockerenv ]; then
  IS_CONTAINER=1
fi

ARCH_UNAME="$(uname -m)"
DEB_ARCH="$(dpkg --print-architecture)"   # amd64 / arm64 / etc

echo "[bootstrap] Detected architecture (uname -m): ${ARCH_UNAME}"
echo "[bootstrap] Detected architecture (dpkg):    ${DEB_ARCH}"

if [ "${IS_CONTAINER}" -eq 1 ]; then
  echo "[bootstrap] Running inside a container (Docker/LXC/containerd)."
else
  echo "[bootstrap] Running on a full machine (VM or bare metal)."
fi

# --------------------------------------------------
# Paths
# --------------------------------------------------
WORKSPACE_ROOT="${WORKSPACE_ROOT:-/workspace}"
SAKAI_SRC="${SAKAI_SRC:-${WORKSPACE_ROOT}/sakai}"
MARKER="${MARKER:-${WORKSPACE_ROOT}/.bootstrap_done}"

# Allow overriding test behavior: SKIP_TESTS=false to run tests
SKIP_TESTS="${SKIP_TESTS:-true}"

if [ -f "$MARKER" ]; then
  echo "[bootstrap] Marker file already exists — skipping setup"
  exit 0
fi

export DEBIAN_FRONTEND=noninteractive

# --------------------------------------------------
# Helpers
# --------------------------------------------------
log() { echo "[bootstrap] $*"; }
err() { echo "[ERROR] $*" >&2; }

start_service() {
  local svc="$1"
  if command -v systemctl >/dev/null 2>&1; then
    if systemctl list-unit-files 2>/dev/null | awk '{print $1}' | grep -q "^${svc}\.service$"; then
      log "Starting ${svc} via systemctl"
      systemctl start "$svc"
      systemctl enable "$svc" >/dev/null 2>&1 || true
      return 0
    fi
  fi

  if command -v service >/dev/null 2>&1; then
    log "Starting ${svc} via service"
    service "$svc" start
    return 0
  fi

  err "No service manager found to start ${svc}. If running in a minimal container, start the daemon manually."
  return 1
}

# --------------------------------------------------
# Base packages
# --------------------------------------------------
log "Updating apt package index..."
apt-get update -y

log "Upgrading installed packages..."
apt-get upgrade -y

log "Installing base packages..."
apt-get install -y \
  openjdk-11-jdk \
  git \
  curl \
  unzip \
  ca-certificates \
  software-properties-common \
  mariadb-server mariadb-client

log "Base packages installed"

# --------------------------------------------------
# Java 11 enforcement (arch-agnostic)
# --------------------------------------------------
log "Verifying Java installation..."
if ! command -v java >/dev/null 2>&1; then
  err "Java not found on PATH after installation."
  exit 1
fi

JAVA_HOME_PATH=$(dirname $(dirname $(readlink -f $(which java))))
export JAVA_HOME="$JAVA_HOME_PATH"
export PATH="$JAVA_HOME/bin:$PATH"
JAVA_BIN="${JAVA_HOME_PATH}/bin/java"

if [ ! -x "$JAVA_BIN" ]; then
  err "Java 11 not found at expected path: ${JAVA_BIN}"
  err "Check installed JVMs under: /usr/lib/jvm/"
  exit 1
fi

log "Switching system Java to Java 11 via update-alternatives..."
update-alternatives --set java "$JAVA_BIN" >/dev/null 2>&1 || true
update-alternatives --set javac "${JAVA_HOME_PATH}/bin/javac" >/dev/null 2>&1 || true

export JAVA_HOME="$JAVA_HOME_PATH"
export PATH="$JAVA_HOME/bin:$PATH"
export SAKAI_HOME="/opt/sakai"

log "Using JAVA_HOME=$JAVA_HOME"
java -version

# --------------------------------------------------
# Maven 3.8.8 (installed explicitly)
# --------------------------------------------------
MAVEN_VERSION="3.8.8"
MAVEN_DIR="/opt/apache-maven-${MAVEN_VERSION}"
MAVEN_URL="https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.zip"

log "Setting up Maven ${MAVEN_VERSION}..."

if [ ! -d "$MAVEN_DIR" ]; then
  log "Downloading Maven from $MAVEN_URL"
  curl -fL "$MAVEN_URL" -o /tmp/maven.zip
  unzip -q /tmp/maven.zip -d /opt
  ln -sf "$MAVEN_DIR" /opt/maven
fi

MVN="/opt/maven/bin/mvn"
log "Verifying Maven installation..."
"$MVN" -version

# --------------------------------------------------
# Tomcat 9 (downloaded, not installed via apt)
# --------------------------------------------------
TOMCAT_VERSION="9.0.69"
TOMCAT_DIR="/opt/apache-tomcat-${TOMCAT_VERSION}"
TOMCAT_URL="https://archive.apache.org/dist/tomcat/tomcat-9/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz"

log "Setting up Tomcat ${TOMCAT_VERSION}..."

if [ ! -d "$TOMCAT_DIR" ]; then
  log "Downloading Tomcat from $TOMCAT_URL..."
  curl -fL "$TOMCAT_URL" -o /tmp/tomcat.tar.gz
  tar xzf /tmp/tomcat.tar.gz -C /opt
  ln -sf "$TOMCAT_DIR" /opt/tomcat
fi

# --------------------------------------------------
# Start MariaDB (portable across VM/container)
# --------------------------------------------------
log "Starting MariaDB..."
start_service mariadb || start_service mysql || true

# --------------------------------------------------
# Create Sakai schema + user
# --------------------------------------------------
SAKAI_DB="${SAKAI_DB:-sakai}"
SAKAI_USER="${SAKAI_USER:-sakaiuser}"
SAKAI_PASS="${SAKAI_PASS:-sakaiuserpass}"

log "Creating Sakai database and user..."
mysql <<EOF
CREATE DATABASE IF NOT EXISTS ${SAKAI_DB} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- User for any host (%)
CREATE USER IF NOT EXISTS '${SAKAI_USER}'@'%' IDENTIFIED BY '${SAKAI_PASS}';
GRANT ALL PRIVILEGES ON ${SAKAI_DB}.* TO '${SAKAI_USER}'@'%';

-- User for localhost (for local socket/TCP connections)
CREATE USER IF NOT EXISTS '${SAKAI_USER}'@'localhost' IDENTIFIED BY '${SAKAI_PASS}';
GRANT ALL PRIVILEGES ON ${SAKAI_DB}.* TO '${SAKAI_USER}'@'localhost';

-- Optional: User for 127.0.0.1 (some JDBC URLs connect via TCP explicitly)
CREATE USER IF NOT EXISTS '${SAKAI_USER}'@'127.0.0.1' IDENTIFIED BY '${SAKAI_PASS}';
GRANT ALL PRIVILEGES ON ${SAKAI_DB}.* TO '${SAKAI_USER}'@'127.0.0.1';

FLUSH PRIVILEGES;
EOF


log "MariaDB & Sakai schema/user setup complete."

# --------------------------------------------------
# Environment variables for shells
# --------------------------------------------------
log "Writing environment variables to /etc/profile.d/sakai.sh..."
cat <<EOF > /etc/profile.d/sakai.sh
export JAVA_HOME=${JAVA_HOME_PATH}
export MAVEN_HOME=/opt/maven
export CATALINA_HOME=/opt/tomcat
export PATH=\$MAVEN_HOME/bin:\$JAVA_HOME/bin:\$PATH

export SAKAI_HOME=${SAKAI_HOME}
EOF
chmod +x /etc/profile.d/sakai.sh

# --------------------------------------------------
# Workspace prep
# --------------------------------------------------
log "Creating workspace directories..."
mkdir -p "${WORKSPACE_ROOT}"
mkdir -p "${SAKAI_SRC}"

# --------------------------------------------------
# Checkout Sakai
# --------------------------------------------------
if [ ! -d "${SAKAI_SRC}/.git" ]; then
  log "Cloning Sakai into ${SAKAI_SRC}..."
  git clone https://github.com/sakaiproject/sakai.git "${SAKAI_SRC}"
else
  log "Sakai repo already exists at ${SAKAI_SRC} — skipping clone"
fi

cd "${SAKAI_SRC}"
log "Fetching latest refs..."
git fetch --all --prune

log "Checking out Sakai 23.x branch..."
git checkout 23.x
git pull --ff-only || true

# --------------------------------------------------
# Build + deploy Sakai (single pass)
# --------------------------------------------------
MVN_TEST_FLAGS=""
if [ "${SKIP_TESTS}" = "true" ]; then
  MVN_TEST_FLAGS="-DskipTests -DskipITs"
  log "Skipping tests for bootstrap (set SKIP_TESTS=false to run them)."
fi

log "Building and deploying Sakai to Tomcat..."
"$MVN" ${MVN_TEST_FLAGS} -V -e clean install  -Dmaven.test.skip=true -T 4C sakai:deploy -Dmaven.tomcat.home="${TOMCAT_DIR}" -Dsakai.home="${SAKAI_HOME}"

# --------------------------------------------------
# Create sakai.properties
# --------------------------------------------------
mkdir -p "${SAKAI_HOME}"
mkdir -p "${SAKAI_HOME}/archive" # For site archive imports
chmod 777 "${SAKAI_HOME}/archive"
mkdir -p "${SAKAI_HOME}/content"
chmod 777 "${SAKAI_HOME}/content"

log "Writing to ${SAKAI_HOME}/sakai.properties..."
cat <<EOF > ${SAKAI_HOME}/sakai.properties                                                                          
# Minimal Sakai config
serverId=localhost
serverName=Isaak
serverUrl=http://localhost:8080
accessUrl=http://localhost:8080

portal.default.skin=default-skin

# mysql username and password
username@javax.sql.BaseDataSource=sakaiuser
password@javax.sql.BaseDataSource=sakaiuserpass

## MySQL settings
vendor@org.sakaiproject.db.api.SqlService=mysql
driverClassName@javax.sql.BaseDataSource=org.mariadb.jdbc.Driver
hibernate.dialect=org.hibernate.dialect.MySQL5InnoDBDialect
url@javax.sql.BaseDataSource=jdbc:mysql://127.0.0.1:3306/sakai?useUnicode=true&characterEncoding=UTF-8&useSSL=false
# url@javax.sql.BaseDataSource=jdbc:mysql://127.0.0.1:3306/sakai?useUnicode=true&characterEncoding=UTF-8&useSSL=false&useServerPrepStmts=false
validationQuery@javax.sql.BaseDataSource=select 1 from DUAL
defaultTransactionIsolationString@javax.sql.BaseDataSource=TRAN

# Auto DDL for first run
auto.ddl=true
hibernate.hbm2ddl.auto=update

# Development sanity
portal.cdn.version=local

# Disable virus scanning (prevents early Timer crashes)
content.virus.scan.enabled=false
virusScan.enabled=false

#enable search, set to false to disable (true is the default setting)
search.enable=false


#store content in the file system instead of the database
convertToFile@org.sakaiproject.content.api.ContentHostingService=true
content.factory=org.sakaiproject.content.impl.FileSystemContentHostingService
#content.store=resources
content.store=file
content.repository=${SAKAI_HOME}/content

# Increase upload limits (MB)
content.upload.max=4096
content.upload.siteImport.max=4096
siteinfo.import.max=4096


EOF

# --------------------------------------------------
# Set environment variable for Sakai in Catalina
# --------------------------------------------------
log "Writing to ${TOMCAT_DIR}/bin/setenv.sh..."
cat <<EOF > ${TOMCAT_DIR}/bin/setenv.sh                                                                       
#!/bin/sh





CATALINA_OPTS="-Dsakai.home=${SAKAI_HOME} -Djava.awt.headless=true -Xms1g -Xmx2g"
JAVA_OPTS="-Dsakai.home=${SAKAI_HOME}"

export CATALINA_OPTS
export JAVA_OPTS
EOF
chmod +x "${TOMCAT_DIR}/bin/setenv.sh"

# --------------------------------------------------
# Final marker
# --------------------------------------------------
touch "$MARKER"
echo "================================================================================="
echo "[bootstrap] Setup completed successfully!"
echo "Starting Sakai..."
echo "Portal URL (once started): http://localhost:8080/portal"
echo "Admin credentials (default): admin / admin"
echo "Archives need to unzipped in to ${SAKAI_HOME}/archive for import via Site Archive"
echo "tool to be able to import them into a site."
echo "==============================================================================="
echo "================================================================================="
echo "[bootstrap] COMPLETED SUCCESSFULLY"
if [ "${IS_CONTAINER}" -eq 0 ]; then
  echo "If running in VirtualBox, consider installing virtualbox-guest-additions-iso"

echo "To start Tomcat (as root):"
echo " cd ${TOMCAT_DIR}/bin ; ./startup.sh && tail -f ../logs/catalina.out"
fi
if [ "${IS_CONTAINER}" -eq 1 ]; then
  echo "Starting Sakai:"
  cd ${TOMCAT_DIR}/bin ; ./startup.sh && tail -f ../logs/catalina.out
fi
echo "==============================================================================="
