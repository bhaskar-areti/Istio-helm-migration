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