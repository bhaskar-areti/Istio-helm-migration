# Istio-helm-migration
Test istio operator migration to helm
##
#Google
##
1. Disable the Istio Operator:
    Scale down the IstioOperator deployment to 0 replicas to prevent it from reconciling resources during the migration.
    
2.  Convert Operator Configuration to Helm Values:
    Utilize the istioctl manifest translate command (available in Istio 1.24 and above) to convert your existing IstioOperator YAML into a values.yaml file and a script for installing equivalent Helm charts.
       istioctl manifest translate -f istiooperator.yaml > values.yaml

3. Install Istio Components via Helm:
    Install the base Istio charts (e.g., istio/base, istio/istiod, istio/gateway) using the generated values.yaml and the Helm installation script. This will bring the Istio control plane and gateways under Helm management.

   helm install istio-base istio/base -n istio-system --values values.yaml
   helm install istiod istio/istiod -n istio-system --values values.yaml
   # Install gateways if applicable, potentially with separate HelmReleases for each gateway

4. Address Gateway Configuration Changes:
    Be aware that the new Helm-based gateway package (istio-gateway) might handle gateway configuration differently than the old operator. Gateways might be destroyed and recreated, potentially leading to changes in external load balancer hostnames/IPs if you are using them. Update DNS records accordingly.

5. Clean Up Istio Operator Resources:
    Once the Helm installation is verified and functional, remove the old IstioOperator resources, including the IstioOperator custom resource, the istio-operator namespace, and the istiooperators.install.istio.io CRD.

6. Verify the Migration:
    Ensure that all services within the mesh are still reachable and functioning correctly.
    Verify that the Istio control plane and gateways are now managed by Helm.

Important Considerations:
    Downtime: This process may require downtime for your configured gateways due to the potential recreation of gateway resources.
    Istio Version: Ensure your Istio version is 1.24 or above to utilize the istioctl manifest translate command.
    Gateway Ports: The new Helm charts might default to different gateway ports (e.g., 80 and 443 instead of 8080 and 8443). Update any AuthorizationPolicies or other configurations that reference these ports, or customize the Helm chart values to match your old defaults.
    Future Upgrades: With the migration to Helm, future Istio upgrades will be managed using Helm upgrade commands.

    #############

The difference between the base, istio, and gateway Helm charts, specifically in the context of Istio, lies in their purpose and the components they install:

a. base Helm chart (Istio):
Purpose: This chart installs the foundational Custom Resource Definitions (CRDs) required by Istio. CRDs define new resource types within Kubernetes, enabling Istio to extend Kubernetes' capabilities.
Components: It only installs the CRDs, not any running Istio components like control plane services or proxies.
Prerequisite: The base chart must be installed before installing other Istio components that rely on these CRDs.

The istio-base chart is a foundational component for Istio installations.
It installs only the cluster-wide Custom Resource Definitions (CRDs) and RBAC roles that other Istio components need to function.

his minimalist approach is the correct way to handle your istio-base installation. Remember that istio-base is a prerequisite for the other charts and only contains CRDs, so it doesn't need complex values. You will need a separate HelmRelease for istiod and potentially istio-gateway with their own.

b. istio Helm chart (or istiod for the control plane):
Purpose: This chart installs the core Istio control plane, responsible for managing and configuring the service mesh.
Components: It includes components like istiod (the main control plane component), which handles configuration, policy enforcement, and telemetry collection for the mesh.
Dependency: It relies on the CRDs installed by the base chart.

c. gateway Helm chart (Istio):
Purpose: This chart deploys an Istio Gateway, which acts as the entry and exit point for traffic into and out of the service mesh.
Components: It creates a Kubernetes Deployment and Service for the Istio Ingress Gateway, typically a specialized Envoy proxy, configured to handle external traffic.
Configuration: You then use Istio Gateway and VirtualService resources to define how traffic should be routed through this deployed gateway.
Note: While Istio provides its own gateway chart, some users might opt for other API gateways like Kong or use the Kubernetes Gateway API, which offers a more standardized and extensible approach to managing ingress.

In summary:
The base chart provides the necessary definitions for Istio resources.
The istio (or istiod) chart deploys the core control plane logic.
The gateway chart deploys the actual proxy instances that handle ingress/egress traffic for the mesh.
These charts are typically installed in a specific order: base first, then istio (or istiod), and finally gateway if you need to expose services to external traffic via an Istio Gateway.

Useful links:
https://github.com/istio/istio/issues/44604

https://github.com/istio/istio/blob/master/manifests/charts/gateway/values.yaml
https://github.com/istio/istio/blob/master/manifests/charts/gateways/istio-ingress/values.yaml

https://github.com/istio/istio/blob/release-1.24/manifests/charts/istio-control/istio-discovery/values.yaml
Gateway chart ref: https://github.com/istio/istio/blob/0fb9e6f274272cc77d0d5a49d6ed1ff10edc7b20/manifests/charts/gateway/Chart.yaml

infrastructure/
├── istio_1.23.4/
│   └── kustomization.yaml (This defines the Istio Operator deployment)
│   └── manifests.yaml (This defines the Istio Operator deployment)
│   └── namespce.yaml (This defines the Istio Operator deployment)
├── istio-routing-como-app-nonprod/
│   └── kustomization.yaml
│   └── gateway.yaml
│   └── virtual-service.yaml
├── istio_1.24.5_canary/
│   ├── helmrelease-istio-base.yaml
│   ├── helmrelease-istiod.yaml (istiod-v124)
│   ├── helmrelease-istio-ingressgateway.yaml (istio-ingressgateway-v124)
│   └── helmrelease-istio-egressgateway.yaml (istio-egressgateway-v124)
cluster-test
├── istio.yml
├── istio-operator.yml
├── istio1.24.5.yml

Current directories structure in k8s-deployemnts 
Caitalgroup
  como-main
  ├── .k8s
  │    ├── como-bgprocessor.yaml
  │    ├── como-scheduler.yaml
  ├── .github
  │    ├── workflows/
  │    │     ├── build-test-all.yaml
  │    │     ├── pr-unit-tests.yaml
  │    │ 
  │    └── dependabot.yml 
  k8s-deployment
  ├── clusters/
  │   └── Live-cluster
  │   └── test-cluster/
  │        └── flux-system/
  │             ├── kustomization.yaml
  │             └── gotk-sync.yaml
  │             └── gotk-components.yaml
  ├── apps/
  │   ├── nginx-test/
  │      ├── deployment.yaml
  │      ├── service.yaml
  │      └── kustomization.yaml
  │  
  └── infrastructure/

#################
  bhaskar-areti/
  test-githubactions/
  │  ├── .k8s
  │  │    ├── nginx.yaml
  │  │  
  │  ├── .github
  │        ├── workflows/
  │        │    ├── build-test-all.yaml
  │        │    ├── pr-unit-tests.yaml
  │        │
  │        └──-deploy-nginx.yaml 
  istio-helm-migration
  ├── clusters/
  │      └── test-cluster/
  │             └── flux-system/
  │             │     ├── kustomization.yaml
  │             │     └── gotk-sync.yaml
  │             │     └── gotk-components.yaml
  │             │
  │             └── trivy-operator.yml
  │             └── github-runners-test.yml
  │             └── istio1.25.5
  ├── apps/
  │   ├── github-runners-test
  │   │   ├── repository-runner.yaml
  │   │   ├── test-pda-api-runner.yaml
  │   ├── nginx-test/
  │      ├── deployment.yaml
  │      ├── service.yaml
  │      └── kustomization.yaml
  │  
  └── infrastructure/
  ######
  ARC flow

test-githubactions repo
        ↓
GitHub Actions (self-hosted ARC runner)
        ↓
Commit to istio-helm-migration repo
        ↓
Flux reconciliation
        ↓
Kubernetes cluster (gha-test namespace)
GitHub Actions decides when and what to deploy
Flux decides how and where to deploy
Git is the only bridge between them
No kubectl from CI or No secrets for the cluster in CI or No Flux logic in the app repo

##
two repositories and what each one does
# test-githubactions as CI / intent like “What I want to deploy”
# Istio-helm-migration as GitOps / source of truth like “What is deployed in the cluster”
Flux only watches Istio-helm-migration.
GitHub Actions only touches Git — never the cluster.


# test-githubactions (CI / GitHub Actions repo)
Only three things matter here for deployments
test-githubactions/
├── .k8s lasting.html
│   └── nginx.yaml              --> SOURCE manifest
├── .github
│   └── workflows
│       └── deploy-nginx.yaml   --> DEPLOY workflow
└── (everything else)
# .k8s/nginx.yaml -->This is the deployment template.

You edit image tags here --> This file is NOT deployed directly
It is copied by GitHub Actions into the GitOps repo
Think of it as: “Desired deployment content”

# .github/workflows/deploy-nginx.yaml -->This is the only file that connects CI → GitOps.
What it does:

Runs on ARC runner
Checks out both repos
Copies .k8s/nginx.yaml
Commits to Istio-helm-migration
Pushes to Git

This is the only deployment trigger from GitHub Actions.   If this file doesn’t run, GA is not involved

# Istio-helm-migration(Flux GitOps repo) -->This is the only repo Flux watches.
The minimal working folder structure (what actually matters)
Istio-helm-migration/
├── clusters/
│   └── test-cluster/
│       ├── flux-system/
│       │   ├── gotk-components.yaml
│       │   └── gotk-sync.yaml
│       └── apps.yaml              --> tells Flux “watch ./apps”
│
├── apps/
│   ├── github-runners-test/
│   │   └── test-githubactions-runner.yaml --> ARC runner
│   │
│   └── nginx-test/
│       ├── deployment.yaml        --> ACTUAL deployed manifest
│       └── kustomization.yaml
│
└── infrastructure/ (ignored for nginx)

 Above Files that actually participate in nginx deployment
 clusters/test-cluster/apps.yaml
This is critical.
spec:
  path: ./apps

This tells Flux: “Everything under apps/ is deployable content”
Without this file → nothing deploys.
 apps/nginx-test/deployment.yaml -->This is the only file Kubernetes actually applies.

This is what Flux reconciles -->This is what created your nginx Pod
This file is written by GitHub Actions; Flux does not care who wrote it

 apps/nginx-test/kustomization.yaml -->Just wires the app directory together.

apps/github-runners-test/test-githubactions-runner.yaml
Creates the self‑hosted runner that executes the workflow.
Without this:

GitHub Actions job would stay Pending forever

#### What happens when you update the nginx image (step by step)
We Correct way (GitHub Actions + Flux together)
You edit: test-githubactions/.k8s/nginx.yaml
GitHub Actions workflow runs
ARC runner copies the file into
    Istio-helm-migration/apps/nginx-test/deployment.yaml
GitHub Actions commits + pushes; Flux notices Git change
Flux applies the new Deployment; Kubernetes updates the Pod image

This is exactly what we just tested successfully

❌ Direct edit in GitOps repo (Flux only)
If you edit: -->Istio-helm-migration/apps/nginx-test/deployment.yaml

✅ Flux deploys
❌ GitHub Actions is not involved
This is expected — and useful — but not CI‑driven.


We now have:  Clean separation of CI and CD
 No kubectl in GitHub Actions and  No cluster credentials in CI
 Reproducible GitOps state and ARC runners scoped to repo
 Flux remains the authority
This is exactly how large organisations do Kubernetes deployments safely.

GitHub Actions writes intent → Git commits state → Flux applies state

