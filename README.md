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