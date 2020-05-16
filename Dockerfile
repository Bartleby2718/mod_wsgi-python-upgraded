FROM grahamdumpleton/mod-wsgi-docker:python-3.5
# Also heavily based on https://hub.docker.com/r/tp33/django/dockerfile

# Some customizable Environment variables
ENV PYTHON_VERSION_MAJOR_MINOR=3.8 \
    PYTHON_VERSION_PATCH=3 \
    OPENSSL_VERSION=1.1.0l \
    MOD_WSGI_VERSION=4.7.1 \
    INSTALL_ROOT=/usr/local \
    MOD_WSGI_USER=www-data \
    MOD_WSGI_GROUP=www-data \
    WORK_DIR=/app \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Another ENV instruction to use the environment variables above
ENV PYTHON_VERSION=$PYTHON_VERSION_MAJOR_MINOR.$PYTHON_VERSION_PATCH \
    SSL_PATH=$INSTALL_ROOT/openssl

# Install necessary packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    # tp33/django
    git \
    libmysqlclient-dev \
    unattended-upgrades \
    # https://linuxize.com/post/how-to-install-python-3-7-on-debian-9/
    # Install more packages https://unix.stackexchange.com/a/332658
    build-essential \
    libbz2-dev \
    liblzma-dev \
    libncurses5-dev \
    libsqlite3-dev \
    tk-dev \
    uuid-dev \
    wget \
    zlib1g-dev \
    # Can't connect to HTTPS URL: https://stackoverflow.com/a/44758621
    libc6-dev \
    libgdbm-dev \
    libreadline-dev

# Download Python
RUN cd $WORK_DIR && \
    wget "https://www.python.org/ftp/python/$PYTHON_VERSION/Python-$PYTHON_VERSION.tgz" && \
    tar -xf Python-$PYTHON_VERSION.tgz

# Download OpenSSL
RUN cd $INSTALL_ROOT && \
    wget "https://www.openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz" && \
    tar -xf openssl-$OPENSSL_VERSION.tar.gz

# Build OpenSSL from source (https://www.howtoforge.com/tutorial/how-to-install-openssl-from-source-on-linux/)
# apt-get install gives you OpenSSL 1.0.1, but Python 3.7 wants 1.0.2+
RUN export CC=x86_64-linux-gnu-gcc && \
    cd $SSL_PATH-$OPENSSL_VERSION && \
    ./config --prefix=$SSL_PATH --openssldir=$SSL_PATH shared zlib && \
    make -j $nproc && \
    make install && \
    echo $SSL_PATH/lib >> /etc/ld.so.conf.d/openssl.conf && \
    ldconfig

# Build Python from source
RUN cd $WORK_DIR/Python-$PYTHON_VERSION && \
    export PATH=$SSL_PATH/bin:$PATH && \
    # --enable-optimizations doesn't work with old versions of GCC
    ./configure --prefix=$INSTALL_ROOT/python --enable-shared --with-ensurepip=install --with-openssl=$SSL_PATH && \ 
    export LD_RUN_PATH="$INSTALL_ROOT/python/lib:$INSTALL_ROOT/python/lib64" && \
    export LDFLAGS="-L$INSTALL_ROOT/python/lib -L$INSTALL_ROOT/python/lib64" && \
    export CPPFLAGS="-I$INSTALL_ROOT/python/include -I$SSL_PATH" && \
    make -j $nproc && \
    make altinstall

# Clean up
RUN rm -rf $WORK_DIR/* && \
    # Create symbolic links
    ln -sf $INSTALL_ROOT/python/bin/python$PYTHON_VERSION_MAJOR_MINOR $INSTALL_ROOT/python/bin/python && \
    ln -sf $INSTALL_ROOT/python/bin/pip$PYTHON_VERSION_MAJOR_MINOR $INSTALL_ROOT/python/bin/pip

# Give mod_wsgi necessary permissions
RUN usermod -a -G $MOD_WSGI_GROUP $MOD_WSGI_GROUP && \
    chown -R $MOD_WSGI_USER:$MOD_WSGI_GROUP $WORK_DIR

RUN which python && python --version && which pip && pip --version

# Install Python packages
RUN pip install Django==2.2.10 \
    elasticsearch==7.0.5 \
    kafka-python==1.4.7 \
    mysqlclient==1.4.6 \
    mod_wsgi==$MOD_WSGI_VERSION

WORKDIR $WORK_DIR
