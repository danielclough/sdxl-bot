FROM node as base

WORKDIR /app

COPY . .

RUN npm i \
    && apt update && apt upgrade -y \
    && apt install -y python3 python-is-python3 python3-pip \
    && mkdir /deps && cd /deps \
    && PYTHON_BIN=$(which python) \
    && cp --parents ${PYTHON_BIN} ./ \
    && for i in `ldd ${PYTHON_BIN} | grep -v linux-vdso.so.1 | awk {' if ( $3 == "") print $1; else print $3 '}`; do cp --parents $i ./ ;done \
    && PYTHON3_BIN=$(which python3) \
    && cp --parents ${PYTHON3_BIN} ./ \
    && for i in `ldd ${PYTHON3_BIN} | grep -v linux-vdso.so.1 | awk {' if ( $3 == "") print $1; else print $3 '}`; do cp --parents $i ./ ;done \
    && PIP_BIN=$(which pip) \
    && cp --parents ${PIP_BIN} ./ \
    && for i in `ldd ${PIP_BIN} | grep -v linux-vdso.so.1 | awk {' if ( $3 == "") print $1; else print $3 '}`; do cp --parents $i ./ ;done \
    && NODE_BIN=$(which node) \
    && cp --parents ${NODE_BIN} ./ \
    && for i in `ldd ${NODE_BIN} | grep -v linux-vdso.so.1 | awk {' if ( $3 == "") print $1; else print $3 '}`; do cp --parents $i ./ ;done 

FROM nvidia/cuda:12.2.0-runtime-ubuntu20.04 as final

COPY --from=base /app /app
COPY --from=base /deps/usr /usr

RUN pip install --break-system-packages diffusers torch transformers accelerate