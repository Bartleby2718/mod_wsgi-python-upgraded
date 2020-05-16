FROM grahamdumpleton/mod-wsgi-docker:python-3.5
# Also heavily based on https://hub.docker.com/r/tp33/django/dockerfile

# Environment variables should be defined before RUN
ENV PYTHON_VERSION_MAJOR_MINOR=3.7 \
    PYTHON_VERSION_PATCH=6 \
    WORK_DIR=/app

# Need another ENV statement to use the environment variables above
ENV PYTHON_VERSION=$PYTHON_VERSION_MAJOR_MINOR.$PYTHON_VERSION_PATCH

# Declare environment variables needed during the build
RUN export CC=x86_64-linux-gnu-gcc; \
    export OPENSSL_VERSION=1.1.0l; \
    export INSTALL_ROOT=/usr/local; \
    export SSL_PATH=$INSTALL_ROOT/openssl; \
    export LD_RUN_PATH="$INSTALL_ROOT/python/lib:$INSTALL_ROOT/python/lib64/"; \
    # --enable-optimizations doesn't work with old versions of GCC
    export CONFIG_ARGS="--prefix=$INSTALL_ROOT/python --enable-shared --with-ensurepip=install --with-openssl=$SSL_PATH"; \
    export LDFLAGS="-L$INSTALL_ROOT/python/lib/ -L$INSTALL_ROOT/python/lib64/" && \
    export CPPFLAGS="-I$INSTALL_ROOT/python/include -I$SSL_PATH" && \
    ###########################################################################
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
    ###########################################################################
    # Build OpenSSL from source (https://www.howtoforge.com/tutorial/how-to-install-openssl-from-source-on-linux/)
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
    ldconfig -v >> $WORK_DIR/ldconfig.txt && \
    openssl version -a && \
    openssl version -a >> $WORK_DIR/opensslb4.txt && \
    # Add OpenSSL to PATH
    export PATH=$SSL_PATH/bin:$INSTALL_ROOT/python/bin:$PATH && \
    openssl version -a && \
    openssl version -a >> $WORK_DIR/opensslafter.txt && \
    ###########################################################################
    # Build Python from source: https://unix.stackexchange.com/a/332658
    cd $WORK_DIR && \
    wget "https://www.python.org/ftp/python/$PYTHON_VERSION/Python-$PYTHON_VERSION.tgz" && \
    tar -xvf Python-$PYTHON_VERSION.tgz && \
    cd Python-$PYTHON_VERSION && \
    ./configure $CONFIG_ARGS && \
    make -j $nproc && \
    make altinstall && \
    # Clean up: https://github.com/GrahamDumpleton/mod_wsgi-docker/blob/master/3.5/setup.sh#L158
    unset LD_RUN_PATH && \
    rm -rf $WORK_DIR/* && \
    export PATH=$SSL_PATH/bin:$INSTALL_ROOT/python/bin:$PATH; \
    unlink /usr/local/python/bin/python && \
    unlink /usr/local/python/bin/pip && \
    ln -s $INSTALL_ROOT/python/bin/python$PYTHON_VERSION_MAJOR_MINOR $INSTALL_ROOT/python/bin/python && \
    ln -s $INSTALL_ROOT/python/bin/pip$PYTHON_VERSION_MAJOR_MINOR $INSTALL_ROOT/python/bin/pip && \
    ###########################################################################
    # Create a group and give it the permission for the working directory
    groupadd $MOD_WSGI_GROUP && \
    usermod -a -G $MOD_WSGI_GROUP $MOD_WSGI_GROUP && \
    chown -R $MOD_WSGI_USER:$MOD_WSGI_GROUP $WORK_DIR

ENV LANG=en_US.UTF-8 \
    PYTHONHASHSEED=random\
    PATH=/usr/local/bin/python:/usr/local/apache/bin:/usr/local/python/bin:/usr/local/apache/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    MOD_WSGI_USER=www-data \
    MOD_WSGI_GROUP=www-data

RUN pip install Django==2.2.10 \
    elasticsearch==7.0.5 \
    kafka-python==1.4.7 \
    mysqlclient==1.4.6 \
    mod_wsgi==4.5.18

WORKDIR $WORK_DIR
