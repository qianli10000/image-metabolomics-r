# Originally from Artem Klevtsov a.a.klevtsov@gmail.com

FROM alpine:3.6

ARG version=3.4.2

ENV ENV=~/.ashrc

ENV archive_url https://cran.r-project.org/src/base/R-3/R-${version}.tar.gz

ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8

ENV build_deps \
  bash \
  bzip2-dev \
  cairo-dev \
  coreutils \
  curl \
  curl-dev \
  file \
  g++ \
  gcc \
  gfortran \
  icu-dev \
  libjpeg-turbo-dev \
  libpng-dev \
  libxml2-dev \
  lzip \
  make \
  openjdk8-jre-base \
  pango-dev \
  pcre-dev \
  perl \
  readline-dev \
  tcl-dev \
  tiff-dev  \
  tk-dev \
  xz-dev \
  zip

RUN echo ${build_deps} > /.build_deps

# Had an error w/ busybox version of ed so this builds and overrides the command
RUN set -ex \
  && apk --no-cache --virtual .build_deps add $(cat /.build_deps) \
  \
  && curl -sSL http://mirror.csclub.uwaterloo.ca/gnu/ed/ed-1.4.tar.lz | lzip -dc | tar xf - \
  && cd ed-1.4 \
  && ./configure && make && make install \
  && cd - && rm -rf ed-1.4 \
  && echo 'ed() { /usr/local/bin/ed "$@"; } >> $ENV' \
  && run_deps=$(for f in $(scanelf --needed --nobanner --format '%n#p' --recursive /usr/local | tr ',' '\n' | sort -u); do \
                test $(find /usr/local -type f -name ${f} | wc -l) -eq 0 && echo so:$f; done) \
  \
  && apk --no-cache --virtual .run_deps add ${run_deps} \
  \
  && apk del .build_deps

RUN set -ex \
  && ed --version \
  && apk --no-cache --virtual .build_deps add $(cat /.build_deps) \
  \
  && curl -sSL ${archive_url} | tar -zxf - \
  \
  && cd R-${version} && \
  \
  CFLAGS="-g -O2 -fstack-protector-strong -D_DEFAULT_SOURCE -D__USE_MISC" \
  CXXFLAGS="-g -O2 -fstack-protector-strong -D_FORTIFY_SOURCE=2 -D__MUSL__" \
  ./configure --prefix=/usr/local \
              --localstatedir=/var \
              --disable-nls \
              --with-readline \
              --without-x \
              --without-recommended-packages \
              --enable-memory-profiling \
              --enable-R-shlib 2>&1 | tee -a /build.log \
  \
  && make -j $(nproc) 2>&1 | tee -a /build.log \
  && make install 2>&1 | tee -a /build.log \
  && cd src/nmath/standalone \
  && make -j $(nproc) 2>&1 | tee -a /build.log \
  && make install | tee -a /build.log \
  \
  && echo "R_LIBS_SITE=\${R_LIBS_SITE-'/usr/local/lib/R/site-library'}" >> /usr/local/lib/R/etc/Renviron \
  && echo 'options(repos = c(CRAN = "https://cloud.r-project.org/"))' >> /usr/local/lib/R/etc/Rprofile.site \
  \
  \
  && run_deps=$(for f in $(scanelf --needed --nobanner --format '%n#p' --recursive /usr/local | tr ',' '\n' | sort -u); do \
                test $(find /usr/local -type f -name ${f} | wc -l) -eq 0 && echo so:$f; done) \
  \
  && apk --no-cache --virtual .run_deps add ${run_deps} \
  \
  && apk del .build_deps \
  \
  && mkdir -p /usr/local/lib/R/site-library \
  \
  && cd / \
  && rm -rf R-${version}

COPY install-packages.R /install-packages.R

RUN set -ex \
  && apk --no-cache --virtual .build_deps add $(cat /.build_deps) \
  \
  && mkdir ~/.R \
  && echo 'CPPFLAGS += -DBOOST_PHOENIX_NO_VARIADIC_EXPRESSION' > ~/.R/Makevars \
  \
  && R -f /install-packages.R \
  \
  && run_deps=$(for f in $(scanelf --needed --nobanner --format '%n#p' --recursive /usr/local | tr ',' '\n' | sort -u); do \
                test $(find /usr/local -type f -name ${f} | wc -l) -eq 0 && echo so:$f; done) \
  && apk --no-cache --virtual .run_deps add ${run_deps} bash \
  \
  && apk del .build_deps

CMD ["/bin/sh"]
