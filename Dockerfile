FROM httpd
# Also heavily based on https://hub.docker.com/r/tp33/django/dockerfile

# Some customizable environment variables with default values
ARG PYTHON_VERSION_MAJOR_MINOR=3.7
ARG PYTHON_VERSION_PATCH=7
ARG MOD_WSGI_VERSION=4.7.1 
ARG INSTALL_ROOT=/usr/local 
ARG MOD_WSGI_USER=www-data 
ARG MOD_WSGI_GROUP=www-data 
ARG WORK_DIR=/app

ENV PYTHON_VERSION=$PYTHON_VERSION_MAJOR_MINOR.$PYTHON_VERSION_PATCH \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Install necessary packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    # OpenSSL
    openssl \
    libssl-dev \
    # tp33/django
    git \
    default-libmysqlclient-dev \
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
    libreadline-dev \
    # The certificate of ... doesn't have a known issuer. https://stackoverflow.com/a/27144445
    ca-certificates \
    # Cannot install mysqlclient https://stackoverflow.com/a/59389154
    libffi-dev && \
    rm -rf /var/lib/apt/lists/*

# Download Python
RUN mkdir $WORK_DIR && \
    cd $WORK_DIR && \
    wget "https://www.python.org/ftp/python/$PYTHON_VERSION/Python-$PYTHON_VERSION.tgz" && \
    tar -xf Python-$PYTHON_VERSION.tgz

# Build Python from source
RUN cd $WORK_DIR/Python-$PYTHON_VERSION && \
    ./configure --prefix=$INSTALL_ROOT/python --enable-shared --with-ensurepip=install --enable-optimizations && \ 
    export LD_RUN_PATH="$INSTALL_ROOT/python/lib:$INSTALL_ROOT/python/lib64" && \
    export LDFLAGS="-L$INSTALL_ROOT/python/lib -L$INSTALL_ROOT/python/lib64" && \
    export CPPFLAGS="-I$INSTALL_ROOT/python/include -I/usr/include" && \
    make -j $nproc && \
    make altinstall && \
    make distclean

# Clean up
RUN rm -rf $WORK_DIR/* && \
    # Create symbolic links
    ln -sf $INSTALL_ROOT/python/bin/python$PYTHON_VERSION_MAJOR_MINOR $INSTALL_ROOT/python/bin/python && \
    ln -sf $INSTALL_ROOT/python/bin/pip$PYTHON_VERSION_MAJOR_MINOR $INSTALL_ROOT/python/bin/pip

# Give mod_wsgi necessary permissions
RUN usermod -a -G $MOD_WSGI_GROUP $MOD_WSGI_GROUP && \
    chown -R $MOD_WSGI_USER:$MOD_WSGI_GROUP $WORK_DIR

ENV LANG=en_US.UTF-8 \
    PYTHONHASHSEED=random \
    PATH=$INSTALL_ROOT/python/bin:$PATH

RUN which python && python --version && which pip && pip --version

# Install Python packages
RUN pip install Django==2.2.10 \
    elasticsearch==7.0.5 \
    kafka-python==1.4.7 \
    mysqlclient==1.4.6 \
    mod_wsgi==$MOD_WSGI_VERSION

WORKDIR $WORK_DIR
