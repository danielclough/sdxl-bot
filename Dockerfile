FROM node as base

WORKDIR /app

COPY . .

RUN npm i \
    && mkdir /deps && cd /deps \
    && NODE_BIN=$(which node) \
    && cp --parents ${NODE_BIN} ./ \
    && for i in `ldd ${NODE_BIN} | grep -v linux-vdso.so.1 | awk {' if ( $3 == "") print $1; else print $3 '}`; do cp --parents $i ./ ;done 

FROM nvidia/cuda:12.2.0-base-ubuntu22.04 as final

WORKDIR /app

COPY --from=base /app /app
COPY --from=base /deps/lib64 /lib64
COPY --from=base /deps/lib /lib
COPY --from=base /deps/usr /usr

RUN apt update && apt upgrade -y \
    && apt install -y python3 python-is-python3 python3-pip \
    && pip install diffusers torch transformers accelerate