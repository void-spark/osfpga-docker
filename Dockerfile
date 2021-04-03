# Anything that may be used for building, but is also needed in the final image
FROM ubuntu:latest AS base
RUN apt-get update -qq \
&& DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y -q \
    ca-certificates \    
    git \
    graphviz \
# nextpnr/yosys use boost, non-dev can only be added by specific version number
    libboost-dev \
    libboost-filesystem-dev \
    libboost-iostreams-dev \
    libboost-program-options-dev \
    libboost-python-dev \
    libboost-system-dev \
    libboost-thread-dev \
    libreadline8 \
    libffi7 \
    libftdi1 \
    make \
    python3 \
    qt5-default \
    tcl \
    xdot \
    zlib1g \
&& rm -rf /var/lib/apt/lists/*


# Anything that is used in more then one of the builds, but not needed in the final image
FROM base AS build_base
RUN apt-get update -qq \
&& DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y -q \
    autoconf \
    bison \
    build-essential \
    flex \
    pkg-config \
&& rm -rf /var/lib/apt/lists/*


# Build IceStorm 
FROM build_base AS build_icestorm
RUN apt-get update -qq \
&& DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y -q \
    libftdi-dev \
&& rm -rf /var/lib/apt/lists/*
RUN git clone --recursive https://github.com/YosysHQ/icestorm.git
WORKDIR icestorm
RUN make -j$(nproc) && make DESTDIR=/tmp/icestorm install
WORKDIR /


# Build nextpnr
FROM build_base AS build_nextpnr
RUN apt-get update -qq \
&& DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y -q \
    cmake \
    libeigen3-dev \
    libqt5opengl5-dev \
    python3-dev \
&& rm -rf /var/lib/apt/lists/*
COPY --from=build_icestorm /tmp/icestorm/ /
RUN git clone --recursive https://github.com/YosysHQ/nextpnr.git
WORKDIR nextpnr
RUN cmake -DARCH=ice40 -DCMAKE_INSTALL_PREFIX=/usr/local . && make -j$(nproc) && make DESTDIR=/tmp/nextpnr install
WORKDIR /


# Build Yosys
FROM build_base AS build_yosys
RUN apt-get update -qq \
&& DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y -q \
    clang \
    gawk \
    libreadline-dev \
    libffi-dev \
    tcl-dev \
    zlib1g-dev \    
&& rm -rf /var/lib/apt/lists/*
RUN git clone --recursive https://github.com/YosysHQ/yosys.git
WORKDIR yosys
RUN make -j$(nproc) && make DESTDIR=/tmp/yosys install
WORKDIR /


# Build Verilator
FROM build_base AS build_verilator
RUN apt-get update -qq \
&& DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y -q \
    libfl2 \
    libfl-dev \
&& rm -rf /var/lib/apt/lists/*
RUN git clone --recursive https://github.com/verilator/verilator.git
WORKDIR verilator
RUN autoconf && ./configure && make -j$(nproc) && make DESTDIR=/tmp/verilator install
WORKDIR /


# Build Icarus Verilog
FROM build_base AS build_iverilog
RUN apt-get update -qq \
&& DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y -q \
    gperf \
&& rm -rf /var/lib/apt/lists/*
RUN git clone --recursive https://github.com/steveicarus/iverilog.git
WORKDIR iverilog
RUN sh autoconf.sh && ./configure && make -j$(nproc) && make DESTDIR=/tmp/iverilog install
WORKDIR /


# Avengers assemble!
FROM base
RUN apt-get update -qq \
&& DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y -q \
    gtkwave \
&& rm -rf /var/lib/apt/lists/*
COPY --from=build_icestorm /tmp/icestorm/ /
COPY --from=build_nextpnr /tmp/nextpnr/ /
COPY --from=build_yosys /tmp/yosys/ /
COPY --from=build_verilator /tmp/verilator /
COPY --from=build_iverilog /tmp/iverilog /

CMD [ "/bin/bash" ]
