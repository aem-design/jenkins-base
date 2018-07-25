FROM        aemdesign/oracle-jdk:latest

MAINTAINER  devops <devops@aem.design>

LABEL   app.version="2" \
        os.version="centos" \
        java.version="oracle jdk 8" \
        docker.source="https://hub.docker.com/_/jenkins/" \
        docker.dockerfile="https://github.com/jenkinsci/docker/blob/master/Dockerfile" \
        container.description="extended Jenkins Base and remove Volume Mount"

ARG JENKINS_VERSION="2.134"
ARG JENKINS_URL="https://repo.jenkins-ci.org/public/org/jenkins-ci/main/jenkins-war/${JENKINS_VERSION}/jenkins-war-${JENKINS_VERSION}.war"
ARG PYCURL_SSL_LIBRARY="nss"
ARG CHROME_DRIVER_VERSION="2.38"
ARG CHROME_DRIVER_FILE="chromedriver_linux64.zip"
ARG CHROME_DRIVER_URL="https://chromedriver.storage.googleapis.com/${CHROME_DRIVER_VERSION}/${CHROME_DRIVER_FILE}"
ARG CHROME_FILE="google-chrome-stable_current_x86_64.rpm"
ARG CHROME_URL="https://dl.google.com/linux/direct/${CHROME_FILE}"
ARG NODE_VERSION="10.2.1"
ARG NVM_VERSION="v0.33.11"
ARG NVM_URL="https://raw.githubusercontent.com/creationix/nvm/${NVM_VERSION}/install.sh"

ENV JENKINS_HOME="/var/jenkins_home" \
    JENKINS_PORT=8080 \
    JENKINS_SLAVE_AGENT_PORT=50000 \
    JENKINS_UID=10001 \
    JENKINS_USER="jenkins" \
    JENKINS_GUID=10001 \
    JENKINS_GROUP="jenkins" \
    JENKINS_SLAVE_COUNT=2 \
    JENKINS_UC="https://updates.jenkins.io" \
    JENKINS_UC_EXPERIMENTAL="https://updates.jenkins.io/experimental" \
    COPY_REFERENCE_FILE_LOG="/var/jenkins_home/copy_reference_file.log" \
    PYCURL_SSL_LIBRARY=${PYCURL_SSL_LIBRARY} \
    CHROME_DRIVER_VERSION=${CHROME_DRIVER_VERSION} \
    NODE_VERSION=${NODE_VERSION} \
    NVM_DIR="${JENKINS_HOME}/.nvm" \
    NODE_VERSION="${NODE_VERSION}"

COPY tcp-slave-agent-port.groovy jenkins-slave-count.groovy /usr/share/$JENKINS_USER/ref/init.groovy.d/
COPY jenkins.sh install-plugins.sh jenkins-support /usr/local/bin/

RUN \
    groupadd -g ${JENKINS_GUID} ${JENKINS_GROUP} && useradd -d "$JENKINS_HOME" -u ${JENKINS_UID} -g ${JENKINS_GUID} -m -s /bin/bash ${JENKINS_USER} && echo "$JENKINS_USER ALL=NOPASSWD: ALL" >> /etc/sudoers && \
    mkdir -p /usr/share/$JENKINS_USER/ref/init.groovy.d && mkdir -p /var/run/sshd && mkdir -p /usr/share/$JENKINS_USER/ref/plugins && \
    JENKINS_MD5=$(curl -L ${JENKINS_URL}.md5) && curl -fL ${JENKINS_URL} -o /usr/share/$JENKINS_USER/jenkins.war && echo "$JENKINS_MD5 /usr/share/$JENKINS_USER/jenkins-war-${JENKINS_VERSION}.war" >> MD5SUM  && \
    yum update -y && yum install -y epel-release && yum install -y curl tar zip unzip maven ruby groovy ivy junit rsync python-setuptools autoconf gcc-c++ make gcc python-devel openssl-devel openssh-server vim git wget bzip2 ca-certificates chrpath fontconfig freetype libfreetype.so.6 libfontconfig.so.1 libstdc++.so.6 ImageMagick ImageMagick-devel libcurl-devel libffi libffi-devel libtool-ltdl libtool-ltdl-devel && \
    curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.rpm.sh | bash && yum install -y git-lfs && git lfs install && \
    curl -s "https://get.sdkman.io" | bash && source "/root/.sdkman/bin/sdkman-init.sh" && sdk install gradle && \
    easy_install pip setuptools && pip install --upgrade --ignore-installed pyudev rtslib-fb && \
    export PYCURL_SSL_LIBRARY=${PYCURL_SSL_LIBRARY} && pip install --upgrade --ignore-installed pycurl && \
    pip install --upgrade --ignore-installed pycrypto BeautifulSoup4 xmltodict paramiko PyYAML Jinja2 httplib2 boto xmltodict six requests python-consul passlib cryptography appdirs packaging boto ansible 'docker-compose<1.20.0' 'docker<3.0' awscli ansible && \
    pip install https://github.com/wildone/pyaem/archive/master.zip && \
    yum clean all && rm -rf /var/lib/yum/* /tmp/* /var/tmp/* && \
    chmod u=rwx /usr/local/bin/install-plugins.sh && chmod u=rwx /usr/local/bin/jenkins-support && \
    chown -R ${JENKINS_USER} ${JENKINS_HOME} && chown -R ${JENKINS_USER} /usr/share/$JENKINS_USER/ && \
    chmod +x /usr/local/bin/jenkins.sh /usr/local/bin/install-plugins.sh /usr/local/bin/jenkins-support

# install chrome
RUN \
    wget ${CHROME_DRIVER_URL} && unzip ${CHROME_DRIVER_FILE} && cp chromedriver /usr/bin && \
    wget ${CHROME_URL} && yum install -y Xvfb ${CHROME_FILE}

EXPOSE ${JENKINS_PORT} ${JENKINS_SLAVE_AGENT_PORT}

USER ${JENKINS_USER}

# install node and npm modules
RUN \
    export NVM_DIR="${JENKINS_HOME}/.nvm" && mkdir -p ${NVM_DIR} && \
    curl -o- ${NVM_URL} | bash && source ~/.bashrc && \
    nvm install $NODE_VERSION && npm install -g npm yarn

CMD ["/usr/local/bin/jenkins.sh"]