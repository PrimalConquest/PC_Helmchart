#!/bin/bash

KUBECONFIG="/etc/rancher/k3s/k3s.yaml"
NAMESPACE="primal-conquest"
RELEASE_NAME="primal-conquest"
HELM_CHART_DIR="./PrimalConquest"
HELM_PACKAGE="./primal-conquest-0.1.0.tgz"
VALUES_FILE="$HELM_CHART_DIR/values.prod.yaml"

SECRETS_FILE="./deploy-secrets"

