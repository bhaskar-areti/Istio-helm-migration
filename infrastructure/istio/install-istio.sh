#!/bin/bash
if [ -z "$1" ]; then
  echo "istio version must be supplied. eg. sh install-istio.sh 1.9.4"
  exit 1
fi

curl -sL https://istio.io/downloadIstio | ISTIO_VERSION=$1 sh -
          ISTIO_DIR=$(find . -name 'istio-*' -type d -maxdepth 1 -print | head -n1)
          
          echo "Build manifests for ${ISTIO_VERSION} in dir ${ISTIO_DIR}"
          helm template --include-crds \
          ${ISTIO_DIR}/manifests/charts/istio-operator/ > ./manifests.yaml
          
          rm -rf ${ISTIO_DIR}
          if [[ $(git diff --stat) != '' ]]; then
            echo ::set-output name=version::${ISTIO_VERSION}
          fi