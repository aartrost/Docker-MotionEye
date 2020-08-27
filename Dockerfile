FROM debian:buster-slim
LABEL maintainer="Marcus Klein <himself@kleini.org>"

ENV MOTIONEYE_VERSION="0.42.1"
ENV MOTION_VERSION="4.3.1"

ARG BUILD_DATE
ARG VCS_REF
LABEL org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.docker.dockerfile="extra/Dockerfile" \
    org.label-schema.license="GPLv3" \
    org.label-schema.name="motioneye" \
    org.label-schema.url="https://github.com/ccrisan/motioneye/wiki" \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-type="Git" \
    org.label-schema.vcs-url="https://github.com/ccrisan/motioneye.git"

RUN apt-get update && \
    DEBIAN_FRONTEND="noninteractive" apt-get -t stable --yes --option Dpkg::Options::="--force-confnew" --no-install-recommends install \
      curl \
      wget \
      ffmpeg \
      libmicrohttpd12 \
      libpq5 \
      lsb-release \
      mosquitto-clients \
      python-jinja2 \
      python-pil \
      python-pip \
      python-pip-whl \
      python-pycurl \
      python-setuptools \
      python-tornado \
      python-tz \
      python-wheel \
      v4l-utils \
      # custom packages
      nano \
      tzdata \
      git \
      automake \
      autoconf \
      libtool \
      build-essential \
      gettext \
      gdebi-core \
      gifsicle

# Install latest motion from release package
RUN cd ~ \
    && wget https://github.com/Motion-Project/motion/releases/download/release-$MOTIONEYE_VERSION/buster_motion_$MOTIONEYE_VERSION-1_amd64.deb \
    && gdebi buster_motion_$MOTIONEYE_VERSION-1_amd64.deb \
    && rm ~/buster_motion_$MOTIONEYE_VERSION-1_amd64.deb

# install motioneye & custom stuff for personal use
RUN pip install motioneye==$MOTIONEYE_VERSION numpy requests pysocks pillow

# Install latest mp4fpsmod (can be used to fix stutter issues on passthrough videos with variable framerate)
RUN cd ~ \
    && git clone https://github.com/nu774/mp4fpsmod \
    && cd mp4fpsmod \
    && ./bootstrap.sh \
    && ./configure \
    && make \
    && strip mp4fpsmod \
    && make install \
    && rm -r ~/mp4fpsmod

# Cleanup
RUN apt-get purge --yes python-setuptools python-wheel git automake autoconf libtool gettext build-essential gdebi-core && \
    apt-get autoremove --yes && \
    apt-get --yes clean && rm -rf /var/lib/apt/lists/* && rm -f /var/cache/apt/*.bin

# R/W needed for motioneye to update configurations
VOLUME /etc/motioneye

# Video & images
VOLUME /var/lib/motioneye

# set default conf and start the MotionEye Server
CMD test -e /etc/motioneye/motioneye.conf || \
    cp /usr/local/share/motioneye/extra/motioneye.conf.sample /etc/motioneye/motioneye.conf; \
    /usr/local/bin/meyectl startserver -c /etc/motioneye/motioneye.conf

EXPOSE 8765
