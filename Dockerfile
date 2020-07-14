FROM buildpack-deps:buster

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update && \
    apt-get install -y csvtool
RUN mkdir -p /opt/intermediate-certs/certs && \
    curl -sL https://ccadb-public.secure.force.com/mozilla/PublicAllIntermediateCertsWithPEMCSV | \
    csvtool namedcol 'PEM Info' - | \
    csvtool drop 1 - | \
    csvtool call "printf '%q\n'" - | \
    while IFS= read -r e; do \
        pem=$(eval "echo $e" | sed "s/'//"); \
        if echo "$pem" | openssl verify; then \
            echo "$pem" | \
                tee -a /opt/intermediate-certs/ca-bundle.crt \
                > /opt/intermediate-certs/certs/"$(echo "$pem" | openssl x509 -subject -noout | perl -pe 's/\W/_/g')".pem; \
        fi; \
    done && \
    c_rehash /opt/intermediate-certs/certs

COPY ./self-signed/build/interm-ca.pem /opt/intermediate-certs/certs/self-signed.pem
RUN cat /opt/intermediate-certs/certs/self-signed.pem >> /opt/intermediate-certs/ca-bundle.crt && \
    c_rehash /opt/intermediate-certs/certs

RUN curl -sL https://deb.nodesource.com/setup_12.x | bash -
RUN apt-get install -y perl cpanminus golang nodejs
RUN git clone https://github.com/sstephenson/bats.git && cd bats && ./install.sh /usr/local

COPY ./tests/ ./tests

RUN cpanm --global --notests --installdeps ./tests
RUN ln -s /tests/node_modules /node_modules && cd ./tests && npm ci
ENV NODE_PATH /node_modules
