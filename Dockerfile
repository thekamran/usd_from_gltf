FROM python:2-slim-buster

ENV WORKDIR=/app
ENV USD_SRC_PATH=${WORKDIR}/usd_src
ENV USD_BUILD_PATH=${WORKDIR}/usd
ENV USD_BIN_PATH=${USD_BUILD_PATH}/bin
ENV USD_LIB_PATH=${USD_BUILD_PATH}/lib
ENV UFG_SRC_PATH=${WORKDIR}/ufg_src
ENV UFG_BUILD_PATH=${WORKDIR}/ufg
ENV UFG_BIN_PATH=${UFG_BUILD_PATH}/bin
ENV UFG_LIB_PATH=${UFG_BUILD_PATH}/lib
ENV PATH=${PATH}:${USD_BIN_PATH}:${UFG_BIN_PATH}
ENV LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${USD_LIB_PATH}:${UFG_LIB_PATH}
ENV PYTHONPATH=${PYTHONPATH}:${USD_LIB_PATH}/python:${UFG_BUILD_PATH}/python

WORKDIR ${WORKDIR}

RUN apt-get -qq update && \
  apt-get install -y git \
  build-essential \
  cmake \
  nasm \
  libglew-dev libxrandr-dev libxcursor-dev libxinerama-dev libxi-dev zlib1g-dev && \
  rm -rf /var/lib/apt/lists/*

RUN git clone --depth 1 --branch v21.02 https://github.com/PixarAnimationStudios/USD.git ${USD_SRC_PATH}

RUN python ${USD_SRC_PATH}/build_scripts/build_usd.py --verbose --prefer-safety-over-speed --no-examples --no-tutorials --no-python --no-imaging --no-usdview --draco ${USD_BUILD_PATH}

RUN rm -rf ${USD_SRC_PATH} && \
  rm -rf ${USD_BUILD_PATH}/build && \
  rm -rf ${USD_BUILD_PATH}/cmake && \
  rm -rf ${USD_BUILD_PATH}/pxrConfig.cmake && \
  rm -rf ${USD_BUILD_PATH}/share && \
  rm -rf ${USD_BUILD_PATH}/src

RUN git clone https://github.com/google/usd_from_gltf.git ${UFG_SRC_PATH} && \
  cd ${UFG_SRC_PATH} && git reset --hard 6d288cce8b68744494a226574ae1d7ba6a9c46eb && cd ${WORKDIR}

RUN python ${UFG_SRC_PATH}/tools/ufginstall/ufginstall.py -v ${UFG_BUILD_PATH} ${USD_BUILD_PATH} && \
  cp -r ${UFG_SRC_PATH}/tools/ufgbatch ${USD_BUILD_PATH}/python && \
  rm -rf ${UFG_SRC_PATH} ${USD_BUILD_PATH}/build ${USD_BUILD_PATH}/src

RUN apt-get purge -y git \
  build-essential \
  cmake \
  nasm \
  libglew-dev \
  libxrandr-dev \
  libxinerama-dev \
  libxi-dev \
  zlib1g-dev && \
  apt autoremove -y && \
  apt-get autoclean -y

CMD [ "usd_from_gltf" ]