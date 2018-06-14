#!/bin/bash

set -e

function vault () {
	docker run -it --rm -e VAULT_ADDR --entrypoint=/bin/sh vault -c "vault auth $VAULT_TOKEN &>/dev/null; vault $*"
}

function run_tests() {

	# Run Vault
	VAULT_HOST=`docker inspect -f '{{ .NetworkSettings.IPAddress }}' vault`
	export VAULT_ADDR="http://${VAULT_HOST}:8200"
	export VAULT_TOKEN="vault-gatekeeper-test-token-id"
	export DOCKER_PROVIDER="test"

	# Import minimesos env args
	# TODO: reenable
	# eval `minimesos info | tail -n+3`

	# wait for vault to startup
	sleep 5
	# Vault 0.10+ enables the KV v2 secret backend mounted at secret by default.
	# v-g-m expects the KV v1 secret backend at that path (& is not configurable).
	vault secrets disable secret/
	vault secrets enable -version=1 -path=secret kv

	vault auth enable userpass
	# If using Docker for Mac, IP should be localhost
	if [ "$(uname)" == "Darwin" ]; then
	    export VAULT_ADDR="http://127.0.0.1:8200"
	fi
	go test -v ./
}

run_tests
