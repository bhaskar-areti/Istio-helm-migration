if [ -z "$1" ]; then
  echo "istio version must be supplied. eg. sh download-istio.sh 1.9.4"
  exit 1
fi

curl -sL https://istio.io/downloadIstio | ISTIO_VERSION=$1 sh 