# Heavily based on https://hub.docker.com/r/tp33/django/dockerfile
FROM grahamdumpleton/mod-wsgi-docker:python-3.5

# Declare environment variables needed during the setup
RUN export BUILD_PATH=/app; \
    export PYTHON_VERSION_MAJOR_MINOR=3.7; \
    export PYTHON_VERSION_PATCH=6; \
    export PYTHON_VERSION=$PYTHON_VERSION_MAJOR_MINOR.$PYTHON_VERSION_PATCH; \
    export CC=x86_64-linux-gnu-gcc; \
    export OPENSSL_VERSION=1.1.0l; \
    export INSTALL_ROOT=/usr/local; \
    export SSL_PATH=$INSTALL_ROOT/openssl; \
    export LD_RUN_PATH="$INSTALL_ROOT/python/lib:$INSTALL_ROOT/python/lib64/"; \
    export CONFIG_ARGS="--prefix=$INSTALL_ROOT/python --enable-optimizations --enable-shared --with-ensurepip=install --with-openssl=$SSL_PATH"; \
    export LDFLAGS="-L$INSTALL_ROOT/python/lib/ -L$INSTALL_ROOT/python/lib64/"; \
    export CPPFLAGS="-I$INSTALL_ROOT/python/include -I$SSL_PATH"; \
    # Install necessary packages in tp33/django
    apt-get update && \
    apt-get install -y --no-install-recommends \
    git \
    libmysqlclient-dev \
    unattended-upgrades \
    # https://linuxize.com/post/how-to-install-python-3-7-on-debian-9/
    # Install more packages https://unix.stackexchange.com/a/332658
    build-essential \
    zlib1g-dev \
    libbz2-dev \
    libsqlite3-dev \
    wget \
    uuid-dev \
    libncurses5-dev \
    tk-dev \
    liblzma-dev \
    # Can't connect to HTTPS URL: https://stackoverflow.com/a/44758621
    libgdbm-dev \
    libc6-dev \
    libreadline-dev && \
    # Install OpenSSL from source (https://www.howtoforge.com/tutorial/how-to-install-openssl-from-source-on-linux/)
    # apt-get install gives you OpenSSL 1.0.1, but Python 3.7 wants 1.0.2+
    cd $INSTALL_ROOT && \
    wget "https://www.openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz" && \
    tar -xf openssl-$OPENSSL_VERSION.tar.gz && \
    cd $SSL_PATH-$OPENSSL_VERSION && \
    ./config --prefix=$SSL_PATH --openssldir=$SSL_PATH shared zlib && \
    make -j $nproc && \
    make install && \
    echo $SSL_PATH/lib >> /etc/ld.so.conf.d/openssl.conf && \
    ldconfig -v && \
    ldconfig -v >> $BUILD_PATH/ldconfig.txt && \
    openssl version -a &&  \
    openssl version -a >> $BUILD_PATH/opensslb4.txt && \
    export PATH=$SSL_PATH/bin:$INSTALL_ROOT/python/bin:$PATH && \
    openssl version -a && \
    openssl version -a >> $BUILD_PATH/opensslafter.txt && \
    # Install Python from source: https://unix.stackexchange.com/a/332658
    cd $BUILD_PATH && \
    wget "https://www.python.org/ftp/python/$PYTHON_VERSION/Python-$PYTHON_VERSION.tgz" && \
    tar -xvf Python-$PYTHON_VERSION.tgz && \
    cd Python-$PYTHON_VERSION && \
    ./configure $CONFIG_ARGS && \
    make -j $nproc && \
    make altinstall && \
    # Clean up: https://github.com/GrahamDumpleton/mod_wsgi-docker/blob/master/3.5/setup.sh#L158
    unset LD_RUN_PATH && \
    # Make python/pip point to the newly installed versions
    export PATH=$SSL_PATH/bin:$INSTALL_ROOT/python/bin:$PATH && \
    ln -sf $INSTALL_ROOT/python/bin/python$PYTHON_VERSION_MAJOR_MINOR $(which python) && \
    ln -sf $INSTALL_ROOT/python/bin/pip$PYTHON_VERSION_MAJOR_MINOR $(which pip) && \
    # Fixup permissions: https://github.com/GrahamDumpleton/mod_wsgi-docker/blob/master/3.5/setup.sh#L254
    chgrp -R root $INSTALL_ROOT && \
    find $INSTALL_ROOT -type d -exec chmod g+ws {} && \
    find $INSTALL_ROOT -perm 2755 -exec chmod g+w {} && \
    find $INSTALL_ROOT -perm 0644 -exec chmod g+w {}

ENV LANG=en_US.UTF-8 PYTHONHASHSEED=random \
    PATH=/usr/local/bin/python$PYTHON_VERSION_MAJOR_MINOR:/usr/local/apache/bin:$PATH \
    MOD_WSGI_USER=www-data MOD_WSGI_GROUP=www-data \ 
    # Environment variables are not supported by RUN, so need to specify again
    PYTHON_VERSION_MAJOR_MINOR=3.7 \
    PYTHON_VERSION_PATCH=6
# Need a new ENV statement to user previously defined environment variables
ENV	PYTHON_VERSION=${PYTHON_VERSION_MAJOR_MINOR}.${PYTHON_VERSION_PATCH}

WORKDIR /app
