ARG BASE_CONTAINER=gcc:7.5.0
FROM $BASE_CONTAINER

LABEL maintainer="Siewyan Hoh <shoh@ukm.edu.my>"

ARG SOURCE_MPI=https://download.open-mpi.org/release/open-mpi/v3.1/openmpi-3.1.4.tar.gz
ARG SOURCE_EPOCH=https://github.com/Warwick-Plasma/epoch/releases/download/v4.17.16/epoch-4.17.16.tar.gz
ARG SOURCE_VISIT_SCRIPT=https://github.com/visit-dav/visit/releases/download/v3.3.1/visit-install3_3_1
ARG SOURCE_VISIT=https://github.com/visit-dav/visit/releases/download/v3.3.1/visit3_3_1.linux-x86_64-debian10.tar.gz

USER root

# install require packages
RUN DEBIAN_FRONTEND=noninteractive apt update
RUN DEBIAN_FRONTEND=noninteractive apt install cpio cmake xserver-xorg-core xinit -y
RUN export DISPLAY=${DISPLAY}

# install open-mpi
RUN cd /opt
RUN wget --progress=bar:force --no-check-certificate $SOURCE_MPI -O- | tar xz
RUN cd openmpi-$( echo $SOURCE_MPI |  awk -F "-" '{print $NF}' | awk -F ".tar.gz" '{print $1}') && \
    mkdir build && \
    cd build && \
    ../configure --prefix=/usr/local && \
    make -j8 && make install && \
    ldconfig

# install visit
RUN cd /opt
RUN wget --progress=bar:force --no-check-certificate $SOURCE_VISIT_SCRIPT && \
    wget --progress=bar:force --no-check-certificate $SOURCE_VISIT
RUN chmod +x ./visit-install3_3_1 && \
    echo "1" | ./visit-install3_3_1 3.3.1 linux-x86_64-debian10 /usr/local

# install epoch
RUN cd /opt
RUN wget --progress=bar:force --no-check-certificate $SOURCE_EPOCH -O- | tar xz
RUN cd epoch-$( echo $SOURCE_EPOCH |  awk -F "-" '{print $NF}' | awk -F ".tar.gz" '{print $1}') && \
    cd epoch1d && make COMPILER=gfortran -j8 && make visit && \
    cd ../epoch2d && make COMPILER=gfortran -j8 && make visit && \
    cd ../epoch3d && make COMPILER=gfortran -j8 && make visit

RUN cd /

CMD ["/usr/local/bin/visit"]