FROM alpine:latest
Label maintainer="Matthew Goldey <mgoldey@greenkeytech.com>"

ENV JAVA_HOME /usr/lib/jvm/default-jvm/
ENV BAZEL_VERSION 0.16.1
ENV TENSORFLOW_VERSION ff2049a0719ac2a53f5a20dbe2144b3a1b6e87b8

# apk installs
RUN apk add --no-cache \
    bash \
    build-base\
    cmake \
    curl \
    fftw \
    freetype \
    freetype-dev \
    g++ \
    gcc \
    git \
    graphviz \
    imagemagick \
    libc-dev \
    libev \
    libev-dev \
    libjpeg-turbo \
    libjpeg-turbo-dev \
    libpng \
    libpng-dev \
    linux-headers \
    make \
    musl-dev \
    openblas-dev \
    openjdk8 \
    patch \
    perl \
    py-numpy-dev \
    py3-pip \
    python3 \
    python3-dev\
    python3-tkinter \
    rsync \
    sed \
    swig \
    wget \
    zip && \
  cd /tmp && \
  pip3 install --no-cache-dir wheel &&  \
  $(cd /usr/bin && ln -s python3 python)

# Bazel download
RUN curl -SLO https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VERSION}/bazel-${BAZEL_VERSION}-dist.zip && \
  mkdir bazel-${BAZEL_VERSION} && \
  unzip -qd bazel-${BAZEL_VERSION} bazel-${BAZEL_VERSION}-dist.zip

# Bazel install
RUN cd bazel-${BAZEL_VERSION} && \
  sed -i -e 's/-classpath/-J-Xmx8192m -J-Xms128m -classpath/g' scripts/bootstrap/compile.sh && \
  bash compile.sh && \
  cp -p output/bazel /usr/bin/

# Download Tensorflow
RUN cd /tmp && \
  git clone https://github.com/tensorflow/tensorflow.git && cd tensorflow && git checkout $TENSORFLOW_VERSION

# This has bad code ->
# curl -SL https://github.com/tensorflow/tensorflow/archive/v${TENSORFLOW_VERSION}.tar.gz | tar xzf -

RUN apk add --no-cache  --allow-untrusted --repository http://dl-3.alpinelinux.org/alpine/edge/testing  hdf5 hdf5-dev

RUN pip3 install -U numpy==1.14.5 \
  keras_applications==1.0.4 \
  keras_preprocessing==1.0.2 \
  h5py==2.8.0

# Build Tensorflow
RUN cd /tmp/tensorflow && \
  : musl-libc does not have "secure_getenv" function && \
  sed -i -e '/JEMALLOC_HAVE_SECURE_GETENV/d' third_party/jemalloc.BUILD && \
  sed -i -e '/define TF_GENERATE_BACKTRACE/d' tensorflow/core/platform/default/stacktrace.h && \
  sed -i -e '/define TF_GENERATE_STACKTRACE/d' tensorflow/core/platform/stacktrace_handler.cc && \
  PYTHON_BIN_PATH=/usr/bin/python \
    PYTHON_LIB_PATH=/usr/lib/python3.6/site-packages \
    CC_OPT_FLAGS="-march=native" \
    TF_NEED_JEMALLOC=1 \
    TF_NEED_GCP=0 \
    TF_NEED_HDFS=0 \
    TF_NEED_S3=0 \
    TF_ENABLE_XLA=0 \
    TF_NEED_GDR=0 \
    TF_NEED_VERBS=0 \
    TF_NEED_NGRAPH=0 \
    TF_NEED_OPENCL_SYCL=0 \
    TF_NEED_KAFKA=0 \
    TF_NEED_AWS=0 \
    TF_NEED_CUDA=0 \
    TF_DOWNLOAD_CLANG=0 \
    TF_CUDA_CLANG=0 \
    TF_NEED_MPI=0 \
    TF_NEED_COMPUTECPP=0 \
    TF_SET_ANDROID_WORKSPACE=0 \
    bash configure
RUN cd /tmp/tensorflow && \
  bazel build -c opt //tensorflow/tools/pip_package:build_pip_package
RUN cd /tmp/tensorflow && \
  ./bazel-bin/tensorflow/tools/pip_package/build_pip_package /tmp/tensorflow_pkg && \
  cp /tmp/tensorflow_pkg/tensorflow*.whl /root

# Make sure it's built properly
RUN pip3 install --no-cache-dir /root/tensorflow-*.whl && \
  python3 -c 'import tensorflow'
