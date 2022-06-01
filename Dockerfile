# Copyright (c) 2020, NVIDIA CORPORATION. All rights reserved.
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.

ARG BASE_IMAGE=nvcr.io/nvidia/l4t-base:r32.7.1
ARG PYTORCH_IMAGE=nvcr.io/nvidia/l4t-pytorch:r32.7.1-pth1.10-py3
ARG TENSORFLOW_IMAGE=nvcr.io/nvidia/l4t-tensorflow:r32.7.1-tf2.7-py3

FROM ${PYTORCH_IMAGE} as pytorch
FROM ${TENSORFLOW_IMAGE} as tensorflow
FROM ${BASE_IMAGE}


#
# setup environment
#
ENV DEBIAN_FRONTEND=noninteractive
ENV CUDA_HOME="/usr/local/cuda"
ENV PATH="/usr/local/cuda/bin:${PATH}"
ENV LD_LIBRARY_PATH="/usr/local/cuda/lib64:${LD_LIBRARY_PATH}"
ENV LLVM_CONFIG="/usr/bin/llvm-config-9"

ARG MAKEFLAGS=-j$(nproc)
ARG PYTHON3_VERSION=3.6

RUN printenv


#
# apt packages
#
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
          python3-pip \
                python3-dev \
                python3-matplotlib \
                python3-setuptools\
                build-essential \
                gfortran \
                git \
                cmake \
                curl \
                libopenblas-dev \
                liblapack-dev \
                libblas-dev \
                libhdf5-serial-dev \
                hdf5-tools \
                libhdf5-dev \
                zlib1g-dev \
                zip \
                libjpeg8-dev \
                libopenmpi-dev \
                openmpi-bin \
                openmpi-common \
                protobuf-compiler \
                libprotoc-dev \
                llvm-9 \
                llvm-9-dev \
                libffi-dev \
                libsndfile1 \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean


#
# pull protobuf-cpp from TF container
#
ENV PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION=cpp

COPY --from=tensorflow /usr/local/bin/protoc /usr/local/bin
COPY --from=tensorflow /usr/local/lib/libproto* /usr/local/lib/
COPY --from=tensorflow /usr/local/include/google /usr/local/include/google


#
# python packages from TF/PyTorch containers
# note:  this is done in this order bc TF has some specific version dependencies
#
COPY --from=pytorch /usr/local/lib/python2.7/dist-packages/ /usr/local/lib/python2.7/dist-packages/
COPY --from=pytorch /usr/local/lib/python${PYTHON3_VERSION}/dist-packages/ /usr/local/lib/python${PYTHON3_VERSION}/dist-packages/

COPY --from=tensorflow /usr/local/lib/python2.7/dist-packages/ /usr/local/lib/python2.7/dist-packages/
COPY --from=tensorflow /usr/local/lib/python${PYTHON3_VERSION}/dist-packages/ /usr/local/lib/python${PYTHON3_VERSION}/dist-packages/


#
# python pip packages
#
RUN pip3 install --no-cache-dir --ignore-installed pybind11
#RUN pip3 install --no-cache-dir --verbose onnx
RUN pip3 install --no-cache-dir --verbose scipy
RUN pip3 install --no-cache-dir --verbose scikit-learn
RUN pip3 install --no-cache-dir --verbose pandas
#RUN pip3 install --no-cache-dir --verbose pycuda
#RUN pip3 install --no-cache-dir --verbose numba

#
# CuPy
#
#ARG CUPY_VERSION=v10.2.0
#ARG CUPY_NVCC_GENERATE_CODE="arch=compute_53,code=sm_53;arch=compute_62,code=sm_62;arch=compute_72,code=sm_72;arch=compute_87,code=sm_87"

#RUN git clone -b ${CUPY_VERSION} --recursive https://github.com/cupy/cupy cupy && \
#    cd cupy && \
#    pip3 install --no-cache-dir fastrlock && \
#    python3 setup.py install --verbose && \
#    cd ../ && \
#    rm -rf cupy


#
# PyCUDA
#
#RUN pip3 uninstall -y pycuda
#RUN pip3 install --no-cache-dir --verbose pycuda six


#
# install OpenCV (with CUDA)
# note:  do this after numba, because this installs TBB and numba complains about old TBB
#
#ARG OPENCV_URL=https://nvidia.box.com/shared/static/2hssa5g3v28ozvo3tc3qwxmn78yerca9.gz
#ARG OPENCV_DEB=OpenCV-4.5.0-aarch64.tar.gz

#RUN apt-get purge -y '*opencv*' || echo "previous OpenCV installation not found" && \
#    mkdir opencv && \
#    cd opencv && \
#    wget --quiet --show-progress --progress=bar:force:noscroll --no-check-certificate ${OPENCV_URL} -O ${OPENCV_DEB} && \
#    tar -xzvf ${OPENCV_DEB} && \
#    dpkg -i --force-depends *.deb && \
#    apt-get update && \
#    apt-get install -y -f --no-install-recommends && \
#    dpkg -i *.deb && \
#    rm -rf /var/lib/apt/lists/* && \
#    apt-get clean && \
#    cd ../ && \
#    rm -rf opencv && \
#    PYTHON3_VERSION=`python3 -c 'import sys; version=sys.version_info[:3]; print("{0}.{1}".format(*version))'` && \
#    cp -r /usr/include/opencv4 /usr/local/include/opencv4 && \
#    cp -r /usr/lib/python${PYTHON3_VERSION}/dist-packages/cv2 /usr/local/lib/python${PYTHON3_VERSION}/dist-packages/cv2


#
# JupyterLab
#
#RUN pip3 install --no-cache-dir --verbose jupyter jupyterlab && \
#    pip3 install --no-cache-dir --verbose jupyterlab_widgets

#RUN jupyter lab --generate-config
#RUN python3 -c "from notebook.auth.security import set_password; set_password('nvidia', '/root/.jupyter/jupyter_notebook_config.json')"

#CMD /bin/bash -c "jupyter lab --ip 0.0.0.0 --port 8888 --allow-root &> /var/log/jupyter.log" & \
#       echo "allow 10 sec for JupyterLab to start @ http://$(hostname -I | cut -d' ' -f1):8888 (password nvidia)" && \
#       echo "JupterLab logging location:  /var/log/jupyter.log  (inside the container)" && \
#       /bin/bash


#
# Install OpenCV (with cuda)
#
ENV DEBIAN_FRONTEND=noninteractive
ENV CUDA_HOME="/usr/local/cuda"
ENV PATH="/usr/local/cuda/bin:${PATH}"
ENV LD_LIBRARY_PATH="/usr/local/cuda/lib64:${LD_LIBRARY_PATH}"

WORKDIR /opt


#ARG OPENCV_VERSION="4.4.0"

#RUN apt update -y && \
#    apt install -y software-properties-common && \
#    apt-add-repository universe && \
#    apt-get update

#RUN git clone https://github.com/johnnysclai/buildOpenCV.git
#RUN cd buildOpenCV && \
#    bash ./buildOpenCV.sh

ARG OPENCV_VERSION=4.5.5
ARG ARCH_BIN=5.3
ARG INSTALL_DIR=/usr/local
ARG DOWNLOAD_OPENCV_EXTRAS=NO
ARG OPENCV_SOURCE_DIR=/opt/
ARG WHEREAMI=$PWD
ARG NUM_JOBS=$(nproc)
ARG PACKAGE_OPENCV="-D CPACK_BINARY_DEB=ON"

RUN git clone https://github.com/johnnysclai/buildOpenCV.git

RUN apt update -y
RUN apt install -y software-properties-common
RUN apt-add-repository universe
RUN apt-get update
RUN cd $WHEREAMI
RUN apt-get install -y \
    build-essential \
    cmake \
    libavcodec-dev \
    libavformat-dev \
    libavutil-dev \
    libeigen3-dev \
    libglew-dev \
    libgtk2.0-dev \
    libgtk-3-dev \
    libjpeg-dev \
    libpng-dev \
    libpostproc-dev \
    libswscale-dev \
    libtbb-dev \
    libtiff5-dev \
    libv4l-dev \
    libxvidcore-dev \
    libx264-dev \
    qt5-default \
    zlib1g-dev \
    pkg-config

# We will be supporting OpenGL, we need a little magic to help
# https://devtalk.nvidia.com/default/topic/1007290/jetson-tx2/building-opencv-with-opengl-support-/post/5141945/#5141945

RUN cd /usr/local/cuda/include && \
    patch -N cuda_gl_interop.h ${OPENCV_SOURCE_DIR}'buildOpenCV/patches/OpenGLHeader.patch'

# GStreamer support
RUN apt-get install -y libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev

RUN cd ${OPENCV_SOURCE_DIR} && \
    git clone --branch ${OPENCV_VERSION} https://github.com/opencv/opencv.git && \
    git clone --branch ${OPENCV_VERSION} https://github.com/opencv/opencv_contrib.git

# Patch the Eigen library issue ...
RUN cd ${OPENCV_SOURCE_DIR}/opencv && \
    sed -i 's/include <Eigen\/Core>/include <eigen3\/Eigen\/Core>/g' modules/core/include/opencv2/core/private.hpp

RUN cd ${OPENCV_SOURCE_DIR}/opencv && \
    mkdir build && \
    cd build && \
    cmake -D CMAKE_BUILD_TYPE=RELEASE \
      -D CMAKE_INSTALL_PREFIX=${INSTALL_DIR} \
      -D CMAKE_LIBRARY_PATH=/usr/local/cuda/lib64/stubs \
      -D WITH_CUDA=ON \
      -D CUDA_ARCH_BIN=${ARCH_BIN} \
      -D CUDA_ARCH_PTX="" \
      -D ENABLE_FAST_MATH=ON \
      -D CUDA_FAST_MATH=ON \
      -D WITH_CUBLAS=ON \
      -D WITH_LIBV4L=ON \
      -D WITH_V4L=ON \
      -D WITH_GSTREAMER=ON \
      -D WITH_GSTREAMER_0_10=OFF \
      -D WITH_QT=ON \
      -D WITH_OPENGL=ON \
      -D BUILD_opencv_python2=ON \
      -D BUILD_opencv_python3=ON \
      -D BUILD_TESTS=OFF \
      -D BUILD_PERF_TESTS=OFF \
      -D OPENCV_EXTRA_MODULES_PATH=../../opencv_contrib/modules \
      ../

RUN cd opencv/build && make -j$(nproc)
RUN cd opencv/build && make install
RUN cd opencv/build && make package

RUN cp -r /usr/local/lib/python3.6/site-packages/cv2 /usr/local/lib/python3.6/dist-packages/

RUN rm -r *