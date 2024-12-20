FROM leakingmemory/alpine-casablanca:build AS build-img-stage1
RUN apk update
RUN apk add libpq

FROM build-img-stage1 AS builddeps
RUN apk add postgresql-dev
RUN apk add g++ cmake ninja boost-static patch

FROM builddeps AS build
ENV SOCI_VERSION=4.0.3
RUN wget -O soci-${SOCI_VERSION}.tar.gz https://sourceforge.net/projects/soci/files/soci/soci-${SOCI_VERSION}/soci-${SOCI_VERSION}.tar.gz/download
RUN tar xzvf soci-${SOCI_VERSION}.tar.gz
RUN mkdir "soci-${SOCI_VERSION}/build"
WORKDIR "soci-${SOCI_VERSION}/build"
RUN cmake -G Ninja .. -DCMAKE_BUILD_TYPE=Release -DSOCI_LIBDIR=lib
RUN ninja
RUN ninja install

FROM leakingmemory/alpine-casablanca:runtime AS alpine-casablanca-soci-psql-runtime
RUN apk update
RUN apk add libpq
COPY --from=build /usr/local/lib/libsoci*.so* /usr/local/lib/

FROM build-img-stage1 AS alpine-casablanca-soci-psql-build
COPY --from=build /usr/local/lib/libsoci*.so* /usr/local/lib/
COPY --from=build /usr/local/lib/libsoci*.a /usr/local/lib/
COPY --from=build /usr/local/include/soci/ /usr/local/include/soci/
