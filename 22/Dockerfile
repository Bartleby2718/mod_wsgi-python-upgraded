FROM grahamdumpleton/mod-wsgi-docker:python-3.5
ENV PYTHON_VERSION_MAJOR_MINOR=3.7 \
    PYTHON_VERSION_PATCH=6 \
    MOD_WSGI_USER=www-data \
    MOD_WSGI_GROUP=www-data \
    WORK_DIR=/app
ENV PYTHON_VERSION=$PYTHON_VERSION_MAJOR_MINOR.$PYTHON_VERSION_PATCH
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    git \
    libmysqlclient-dev \
    unattended-upgrades \
    build-essential \
    zlib1g-dev \
    libbz2-dev \
    libsqlite3-dev \
    wget \
    uuid-dev \
    libncurses5-dev \
    tk-dev \
    liblzma-dev \
    libgdbm-dev \
    libc6-dev \
    libreadline-dev
WORKDIR $WORK_DIR
RUN wget "https://www.python.org/ftp/python/$PYTHON_VERSION/Python-$PYTHON_VERSION.tgz" && \
    tar -xvf Python-$PYTHON_VERSION.tgz
RUN export CC=x86_64-linux-gnu-gcc; \
    export OPENSSL_VERSION=1.1.0l; \
    export INSTALL_ROOT=/usr/local; \
    export SSL_PATH=$INSTALL_ROOT/openssl; \
    export LD_RUN_PATH="$INSTALL_ROOT/python/lib:$INSTALL_ROOT/python/lib64/"; \
    export LDFLAGS="-L$INSTALL_ROOT/python/lib/ -L$INSTALL_ROOT/python/lib64/" && \
    export CPPFLAGS="-I$INSTALL_ROOT/python/include -I$SSL_PATH" && \
    cd $INSTALL_ROOT && \
    wget "https://www.openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz" && \
    tar -xf openssl-$OPENSSL_VERSION.tar.gz && \
    cd $SSL_PATH-$OPENSSL_VERSION && \
    ./config --prefix=$SSL_PATH --openssldir=$SSL_PATH shared zlib && \
    make -j $nproc && \
    make install && \
    echo $SSL_PATH/lib >> /etc/ld.so.conf.d/openssl.conf && \
    export PATH=$SSL_PATH/bin:$INSTALL_ROOT/python/bin:$PATH && \
    cd $WORK_DIR && \
    cd Python-$PYTHON_VERSION && \
    ./configure --prefix=$INSTALL_ROOT/python --enable-shared --with-ensurepip=install --with-openssl=$SSL_PATH && \
    make -j $nproc && \
    make altinstall && \
    rm -rf $WORK_DIR/* && \
    export PATH=$SSL_PATH/bin:$INSTALL_ROOT/python/bin:$PATH; \
    ln -sf $INSTALL_ROOT/python/bin/python$PYTHON_VERSION_MAJOR_MINOR $INSTALL_ROOT/python/bin/python && \
    ln -sf $INSTALL_ROOT/python/bin/pip$PYTHON_VERSION_MAJOR_MINOR $INSTALL_ROOT/python/bin/pip
RUN usermod -a -G $MOD_WSGI_GROUP $MOD_WSGI_GROUP && \
    chown -R $MOD_WSGI_USER:$MOD_WSGI_GROUP $WORK_DIR
RUN which python && python --version && which pip && pip --version
RUN pip install Django==2.2.10 \
    elasticsearch==7.0.5 \
    kafka-python==1.4.7 \
    mysqlclient==1.4.6 \
    mod_wsgi==4.5.18
WORKDIR $WORK_DIR