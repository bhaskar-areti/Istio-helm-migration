if [ -z "$1" ]; then
  echo "istio version must be supplied. eg. sh install-istio.sh 1.9.4"
  exit 1
fi

curl -sL https://istio.io/downloadIstio | ISTIO_VERSION=$1 sh -
          ISTIO_DIR=$(find . -name 'istio-*' -type d -maxdepth 1 -print | head -n1)
# generate the certs. Inspired by https://istio.io/latest/docs/tasks/security/cert-management/plugin-ca-cert/
          mkdir -p certs
          pushd certs
# generate root certs
          make -f ../${ISTIO_DIR}/tools/certs/Makefile.selfsigned.mk root-ca
# generate cluster-app certs
          make -f ../${ISTIO_DIR}/tools/certs/Makefile.selfsigned.mk cluster-app-cacerts
# generate cluster-db certs
          make -f ../${ISTIO_DIR}/tools/certs/Makefile.selfsigned.mk cluster-db-cacerts
#clean up and delete the istio install directory
          rm -rf ../${ISTIO_DIR}