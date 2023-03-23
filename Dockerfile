FROM nvcr.io/nvidia/l4t-cuda:10.2.460-runtime

RUN apt-get update -y && apt-get upgrade -y && rm -rf /var/lib/apt/lists/*
 
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    build-essential \
    autoconf \
    libtool  \
    pkg-config \
    git \
    python-dev \
    swig3.0 \
    libpcre3-dev \
    nodejs-dev \
    unzip \
    libjpeg-dev \
    libpng-dev \
    libtiff-dev \
    libavcodec-dev \
    libavformat-dev \
    libswscale-dev \
    libv4l-dev \
    libxvidcore-dev \
    libx264-dev \
    libgtk-3-dev \
    libatlas-base-dev \
    gfortran \
    ninja-build \
    python3-dev && rm -rf /var/lib/apt/lists/*

RUN apt-key del http://cuda-internal.nvidia.com/release-candidates/kitpicks/cuda-r10-2-tegra/10.2.460/006/repos/ubuntu1804/arm64

# Upgrade CMake
RUN apt-get update && apt install -y libssl-dev && \
    apt remove cmake && \
    wget --no-check-certificate https://github.com/Kitware/CMake/releases/download/v3.18.3/cmake-3.18.3.tar.gz && \
    tar -xvf cmake-3.18.3.tar.gz && \
    cd cmake-3.18.3 && \
    ./bootstrap && \
    make -j$(nproc) && \
    make install && \
    cd .. && \
    rm -r cmake-3.18.3*

WORKDIR /deb
COPY deb_files ./

RUN dpkg -i libcudnn*
RUN ldconfig

RUN dpkg -i libcudnn*
RUN ldconfig
RUN dpkg -i cuda-repo-l4t-10-2-local-10.2.89_1.0-1_arm64.deb
RUN apt-get -y update
RUN apt-get -y --allow-unauthenticated install cuda-cudart-dev-10-2 libcublas-dev
RUN dpkg -i libnvinfer7_7.1.3-1+cuda10.2_arm64.deb
RUN dpkg -i libnvinfer-dev_7.1.3-1+cuda10.2_arm64.deb
RUN dpkg -i libnvonnxparsers*
RUN dpkg -i libnvparsers7_7.1.3-1+cuda10.2_arm64.deb
RUN dpkg -i libnvparsers-dev_7.1.3-1+cuda10.2_arm64.deb
RUN dpkg -i libnvinfer-plugin7_7.1.3-1+cuda10.2_arm64.deb
RUN dpkg -i libnvinfer-bin_7.1.3-1+cuda10.2_arm64.deb
RUN dpkg -i libnvinfer*

RUN dpkg -i libvisionworks-repo_1.6.0.501_arm64.deb
RUN dpkg -i passlibnvinfer-samples_7.1.3-1+cuda10.2_all.deb
RUN dpkg -i tensorrt*
RUN dpkg -i libnv*
RUN dpkg -i python*

RUN apt-get update

RUN apt-get update && apt install -y tensorrt libvisionworks libvisionworks-dev
RUN apt install -y python3-pip
RUN ldconfig
RUN pip3 install --no-cache-dir --upgrade pip setuptools --trusted-host pypi.org --trusted-host files.pythonhosted.org --trusted-host pypi.python.org
RUN apt install -y python3 python3-dev gcc gfortran musl-dev
RUN pip3 install numpy Cython  --trusted-host pypi.org --trusted-host files.pythonhosted.org --trusted-host pypi.python.org
RUN pip3 install --no-cache-dir libtorch/torch-1.8.0-cp36-cp36m-linux_aarch64.whl --trusted-host pypi.org --trusted-host files.pythonhosted.org --trusted-host pypi.python.org
RUN rm -r /deb 
  
WORKDIR /opencv4
RUN apt-get install wget -y
RUN wget -O opencv.zip https://github.com/opencv/opencv/archive/4.7.0.zip --no-check-certificate
RUN wget -O opencv_contrib.zip https://github.com/opencv/opencv_contrib/archive/4.7.0.zip --no-check-certificate
 
RUN unzip opencv.zip
RUN unzip opencv_contrib.zip
 
RUN apt-get install -y libeigen3-dev libgflags-dev libgoogle-glog-dev 
RUN cd opencv-4.7.0/ && mkdir -p build && cd build && cmake -DOPENCV_EXTRA_MODULES_PATH=/opencv4/opencv_contrib-4.7.0/modules -D OPENCV_EXTRA_MODULES_PATH=/opencv4/opencv_contrib-4.7.0/modules -D HAVE_opencv_python3=ON -DWITH_CUDA=ON D ENABLE_FAST_MATH=ON -D PYTHON_EXECUTABLE=/usr/bin/python3 -D ENABLE_FAST_MATH=1 -D WITH_OPENGL=ON -D WITH_LIBV4L=ON -D WITH_GSTREAMER=ON -D WITH_GSTREAMER_0_10=OFF -D WITH_CUBLAS=ON -D CUDA_FAST_MATH=ON  -DCUDA_TOOLKIT_ROOT_DIR=/usr/local/cuda/ -DCUDA_CUDA_LIBRARY=/usr/local/cuda/targets/aarch64-linux/lib/stubs/libcuda.so -DCUDA_rt_LIBRARY=/usr/lib/aarch64-linux-gnu/librt.so -DCUDA_NVCC_FLAGS:STRING="--default-stream per-thread" -DCMAKE_LIBRARY_PATH=/usr/local/cuda/lib64/stubs .. && make -j$(nproc)
RUN cd opencv-4.7.0/build/ && make -j$(nproc) install

RUN cd /usr/local/lib/python3.6/dist-packages/torch && mkdir -p /usr/local/libtorch/ && cp -r lib share include bin /usr/local/libtorch/

RUN rm -r /opencv4

WORKDIR /yaml-cpp
COPY yaml-cpp yaml-cpp

COPY yaml-cpp yaml-cpp
RUN cd yaml-cpp && mkdir build && cd build && cmake -DYAML_BUILD_SHARED_LIBS=ON .. && make -j$(nproc) && make install
RUN rm -r /yaml-cpp

RUN rm -rf /var/lib/apt/lists/*

COPY OpenGLHeader.patch /usr/local/cuda/include/
RUN cd /usr/local/cuda/include && patch -N cuda_gl_interop.h 'OpenGLHeader.patch'
RUN apt-get update && apt-get install -y libboost-all-dev
RUN cd /usr/local/cuda/lib64 && ln -s libcufft.so.10 libcufft.so
RUN echo "export CMAKE_LIBRARY_PATH=/usr/local/cuda/lib64/stubs" >> ~/.bashrc
RUN ldconfig && apt-get clean

RUN apt-get clean
