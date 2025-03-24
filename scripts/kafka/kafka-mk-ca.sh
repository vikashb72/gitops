#!/usr/bin/env bash

export STEPCAURL="https://ica.home.where-ever.za.net:443"
export STEPDIR=/usr/local/etc/step-ca
export STEPPATH=${STEPDIR}/ca
export CERTDIR=$STEPDIR/certs
export TMPDIR=$STEPDIR/tmp

openssl rand -hex 16 > kafka-cluster-ca.password
openssl rand -hex 16 > kafka-client-ca.password

step certificate create "Kafka Cluster Intermediate CA (2025)" \
	--csr \
	--no-password \
        --insecure \
	--kty RSA \
	kafka-cluster-ca.csr \
	kafka-cluster-ca.key
step certificate sign \
	--profile intermediate-ca \
	--password-file ${STEPDIR}/ca.password.txt \
	--not-after 87660h \
	kafka-cluster-ca.csr  \
	${STEPPATH}/certs/root_ca.crt  \
	${STEPPATH}/secrets/root_ca_key \
	> kafka-cluster-ca.crt

step certificate create "Kafka Client Intermediate CA (2025)" \
	--csr \
	--no-password \
        --insecure \
	--kty RSA \
	kafka-client-ca.csr \
	kafka-client-ca.key

step certificate sign \
    --profile intermediate-ca \
    --password-file ${STEPDIR}/ca.password.txt \
    --not-after 87660h kafka-client-ca.csr  \
    ${STEPPATH}/certs/root_ca.crt  \
    ${STEPPATH}/secrets/root_ca_key \
    > kafka-client-ca.crt

cat ${STEPPATH}/certs/root_ca.crt >> kafka-cluster-ca.crt
cat ${STEPPATH}/certs/root_ca.crt >> kafka-client-ca.crt

openssl pkcs12 -export -in kafka-client-ca.crt \
    -nokeys -out kafka-client-ca.p12 \
    -password pass:`cat kafka-client-ca.password` \
    -caname "Kafka Client Intermediate CA (2025)"

openssl pkcs12 -export -in kafka-cluster-ca.crt \
    -nokeys -out kafka-cluster-ca.p12 \
    -password pass:`cat kafka-cluster-ca.password` \
    -caname "Kafka Cluster Intermediate CA (2025)"
