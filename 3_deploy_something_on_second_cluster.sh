#!/usr/bin/env bash

#doitlive shell: /bin/bash
#doitlive prompt: default
#doitlive speed: 10
#doitlive commentecho: true

#Login to credhub
client_secret="$(bosh int $HOME/vars.yml --path /credhub_admin_client_secret)"
#doitlive env: client_secret="$(bosh int $HOME/vars.yml --path /credhub_admin_client_secret)"

credhub login -s https://10.0.1.252:8844 \
--skip-tls-validation \
--client-name=credhub-admin \
--client-secret="$client_secret"

credhub find -a

credhub find -n /cfsummit-bosh/cfcr-staging/

#Get token to authenticate.
token="$(credhub get -n /cfsummit-bosh/cfcr-staging/kubo-admin-password | bosh int - --path /value)"
#doitlive env: token="$(credhub get -n /cfsummit-bosh/cfcr-staging/kubo-admin-password | bosh int - --path /value)"

#Get and save cluster certificate
credhub get -n /cfsummit-bosh/cfcr-staging/tls-kubernetes | bosh int - --path /value/ca | tee staging_ca.pem

#Get nodes from the cluster
kubectl --certificate-authority=staging_ca.pem --token="$token" --server=https://master.cfcr.internal:8443 get nodes

#Need jumpbox to access it
jumpbox_ip="$(bosh -d cfcr-jumpbox vms --column ips | xargs)"
#doitlive env: jumpbox_ip="$(bosh -d cfcr-jumpbox vms --column ips | xargs)"

HTTPS_PROXY="http://$jumpbox_ip:3128" kubectl --certificate-authority=staging_ca.pem --token="$token" --server=https://master.cfcr.internal:8443 get nodes

https_proxy="http://$jumpbox_ip:3128" kubectl --certificate-authority=staging_ca.pem --token="$token" --server=https://master.cfcr.internal:8443 apply -f k8s_specs/nginx.yml

HTTPS_PROXY="http://$jumpbox_ip:3128" kubectl --certificate-authority=staging_ca.pem --token="$token" --server=https://master.cfcr.internal:8443 rollout status -w deploy/nginx

HTTPS_PROXY="http://$jumpbox_ip:3128" kubectl --certificate-authority=staging_ca.pem --token="$token" --server=https://master.cfcr.internal:8443 describe svc/nginx
