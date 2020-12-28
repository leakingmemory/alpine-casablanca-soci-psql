FROM leakingmemory/alpine-casablanca:build AS build-img-stage1
RUN apk update
RUN apk add libpq

FROM build-img-stage1 AS builddeps
RUN apk add postgresql-dev
RUN apk add g++ cmake ninja boost-static patch

FROM builddeps AS build
RUN wget https://github.com/SOCI/soci/archive/3.2.3.tar.gz
RUN tar xzvf 3.2.3.tar.gz
COPY soci-libdir.patch /soci-libdir.patch
RUN patch -p0 < soci-libdir.patch
RUN mkdir soci-3.2.3/src/build
WORKDIR soci-3.2.3/src/build
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
