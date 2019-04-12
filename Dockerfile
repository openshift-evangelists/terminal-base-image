FROM centos/s2i-base-centos7:latest

# Install additional common utilities.

RUN HOME=/root && \
    INSTALL_PKGS="nano python-devel" && \
    yum install -y centos-release-scl && \
    yum -y --setopt=tsflags=nodocs install --enablerepo=centosplus $INSTALL_PKGS && \
    rpm -V $INSTALL_PKGS && \
    yum -y clean all --enablerepo='*'

# Install OpenShift client.

ARG OC_VERSION=3.10.41
ARG ODO_VERSION=0.0.12
RUN curl -s -o /tmp/oc.tar.gz "https://mirror.openshift.com/pub/openshift-v3/clients/$OC_VERSION/linux/oc.tar.gz" && \
    tar -C /usr/local/bin -zxvf /tmp/oc.tar.gz oc && \
    rm /tmp/oc.tar.gz && \
    curl -sL -o /usr/local/bin/odo https://github.com/redhat-developer/odo/releases/download/v$ODO_VERSION/odo-linux-amd64 && \
    chmod +x /usr/local/bin/odo

ARG KUBECTL_VERSION=1.10.0
RUN curl -sL -o /usr/local/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/v$KUBECTL_VERSION/bin/linux/amd64/kubectl && \
    chmod +x /usr/local/bin/kubectl

# Common environment variables.

ENV PYTHONUNBUFFERED=1 \
    PYTHONIOENCODING=UTF-8 \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    PIP_NO_CACHE_DIR=off

# Install Supervisor and Butterfly using system Python 2.7.

RUN HOME=/opt/workshop && \
    mkdir -p /opt/workshop && \
    curl -s -o /tmp/get-pip.py https://bootstrap.pypa.io/get-pip.py && \
    /usr/bin/python /tmp/get-pip.py --user && \
    rm -f /tmp/get-pip.py && \
    $HOME/.local/bin/pip install --no-cache-dir --user virtualenv && \
    $HOME/.local/bin/virtualenv /opt/workshop && \
    source /opt/workshop/bin/activate && \
    pip install supervisor==3.3.4 && \
    mkdir -p /opt/app-root/etc && \
    pip install butterfly==3.2.5 pygments==2.2.0 && \
    curl -sL -o /tmp/asciidoc.tar.gz https://downloads.sourceforge.net/project/asciidoc/asciidoc/8.6.9/asciidoc-8.6.9.tar.gz && \
    tar -C /tmp -zxvf /tmp/asciidoc.tar.gz && \
    (cd /tmp/asciidoc-8.6.9 && \
    ./configure --prefix /opt/workshop && \
    make install && \
    cp asciidocapi.py /opt/workshop/lib/python2.7/site-packages) && \
    rm -rf /tmp/asciidoc-8.6.9 /tmp/asciidoc.tar.gz && \
    rm /opt/app-root/etc/scl_enable

RUN HOME=/opt/workshop && \
    cd /opt/workshop && \
    source scl_source enable rh-nodejs10 && \
    npm install http-proxy

RUN HOME=/opt/workshop && \
    source /opt/workshop/bin/activate && \
    pip install Flask==1.0.2 Flask-Misaka==0.4.1 waitress==1.1.0

ENV BASH_ENV=/opt/workshop/etc/profile \
    ENV=/opt/workshop/etc/profile \
    PROMPT_COMMAND=". /opt/workshop/etc/profile"

COPY s2i/. /usr/libexec/s2i/

COPY bin/. /opt/workshop/bin/
COPY etc/. /opt/workshop/etc/

COPY static/. /opt/workshop/static/
COPY templates/. /opt/workshop/templates/

COPY proxy.js app.py workshop.py /opt/workshop/
COPY asciidoc.conf /opt/workshop/etc/asciidoc/

RUN echo "auth required pam_wheel.so use_uid" >> /etc/pam.d/su && \
    chmod g+w /etc/passwd

RUN touch /opt/workshop/etc/envvars && \
    chown -R 1001:0 /opt/workshop/etc/envvars && \
    chmod g+w /opt/workshop/etc/envvars

RUN mkdir -p /opt/app-root/workshop && \
    mkdir -p /opt/app-root/etc/init.d && \
    mkdir -p /opt/app-root/etc/profile.d && \
    chown -R 1001:0 /opt/app-root && \
    fix-permissions /opt/app-root

LABEL io.k8s.display-name="Terminal (Base Image)." \
      io.openshift.expose-services="8080:http" \
      io.openshift.tags="builder,butterfly" \
      io.openshift.s2i.scripts-url=image:///usr/libexec/s2i

EXPOSE 8080

USER 1001

CMD [ "/usr/libexec/s2i/run" ]
