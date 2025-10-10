Inspired by work done on repo:
https://github.com/stefanprodan/gitops-istio/blob/main/.github/workflows/update-istio.yaml

# Install istio in this repo

Run this script in THIS directory (ie. /infrastructure/istio). This will download istio and the istio manifest.yaml file into istio-operator-crds for the given version

This takes 1 parameter which is the istio version you want to install

```
sh install-istio.sh 1.9.2
```

If you want to just download and keep the 'downloaded' istio (not needed for deployments, the above script does the same thing but deletes the downloaded istio files on completion), you can run:
```
sh download-istio.sh 1.9.2
```


Multi cluster communication

https://istio.io/latest/docs/tasks/security/cert-management/plugin-ca-cert/

Run this script in THIS directory (ie. /infrastructure/istio). This will download istio and generate the root certs, cluster-app certs and cluster-db certs for multi-cluster communication 

This takes 1 parameter which is the istio version you want to install

```
sh generate-istio-certs.sh 1.9.2
```

NOTE: This should not be done for production. Homework for Jim is to move these certs into a more secure CA server and pull them down. This is for demo purposes only


# INSTALL CERTS. Before we install istio via flux, we need to do the following to configure the certificates


Setup cluster-app. Run this script against the app cluster's context and can only be run once istio is setup via flux:


```
kubectl create namespace istio-system

kubectl --context=como-db create secret generic cacerts -n istio-system \
      --from-file=certs/cluster-app/ca-cert.pem \
      --from-file=certs/cluster-app/ca-key.pem \
      --from-file=certs/cluster-app/root-cert.pem \
      --from-file=certs/cluster-app/cert-chain.pem
```


Setup cluster-db. Run this script against the app cluster's context and can only be run once istio is setup via flux:

```
kubectl create namespace istio-system

kubectl --context=como-db create secret generic cacerts -n istio-system \
      --from-file=certs/cluster-db/ca-cert.pem \
      --from-file=certs/cluster-db/ca-key.pem \
      --from-file=certs/cluster-db/root-cert.pem \
      --from-file=certs/cluster-db/cert-chain.pem
```


deploy istio to both clusters via flux. Ie. add the istio and istio-operator kustomizations to your cluster's config/
https://istio.io/latest/docs/setup/install/multicluster/multi-primary/
Then run these scripts to create remote secrets (Enable Endpoint Discovery). This should be done once istio is up and running

run against cluster-app (context names will need to change based on what they are called on your machine)
```
 istioctl x create-remote-secret \
    --context="como-app" \
    --name=cluster-app | \
    kubectl apply -f - --context="como-db"
```

to generate as a sealed secret:
```
istioctl x create-remote-secret \
--context="como-app" \
--name=cluster-app \
| kubectl apply -f - --context="como-db" \
--dry-run=client -o yaml | kubeseal -o yaml > istio-remote-secret-cluster-app.yaml

```


run against cluster-db (context names will need to change based on what they are called on your machine)
```
 istioctl x create-remote-secret \
    --context="como-db" \
    --name=cluster-db | \
    kubectl apply -f - --context="como-app"
```

```
istioctl x create-remote-secret \
--context="como-db" \
--name=cluster-db \
| kubectl apply -f - --context="como-app" \
--dry-run=client -o yaml | kubeseal -o yaml > istio-remote-secret-cluster-db.yaml

```



Once done, you can verify the install by following these steps:
https://istio.io/latest/docs/setup/install/multicluster/verify/

Debugging:

default check the services that a given pod has 'access' to
```
istioctl --context $CTX_CLUSTER1 proxy-config endpoint sleep-5b56dfc4c-8vrkt.sample | grep helloworld
```


Force delete dangling istio commands:
```
https://stackoverflow.com/questions/65186930/istio-delete-istio-control-plane-process-is-frozen
``` 

Drain istio listeners from pod:
```
kubectl --context="${CTX_CONTEXT1}" exec (pod-name) \
  -n sample -c istio-proxy -- curl -sSL -X POST 127.0.0.1:15000/drain_listeners

kubectl --context="${CTX_CONTEXT2}" exec (pod-name) \
  -n sample -c istio-proxy -- curl -sSL -X POST 127.0.0.1:15000/drain_listeners
```

Run command against POD to test communication
```
kubectl exec --context="${CTX_CONTEXT1}" -n sample -c sleep \
  "$(kubectl get pod --context="${CTX_CONTEXT1}" -n sample -l \
  app=sleep -o jsonpath='{.items[0].metadata.name}')" \
  -- curl -sSL helloworld.sample:5000/hello
```


Get External IP:
```
kubectl get svc istio-ingressgateway -n istio-system
```

