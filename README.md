# Getting Started

- Standup the `kind` cluster by executing: `kind create cluster --config ./kind/kind-config.yaml`

- Install Flux using the script found in `./flux2`.

- Create a `secrets.yaml` somewhere in your project. Ensure that it is `.gitignore`'d since this will contain your GitHub/GitLab PAT.

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: git-credentials
  namespace: flux
type: Opaque
stringData:
  username: <YOUR_GITHUB_USERNAME>
  password: <YOUR_GITHUB_PAT>
```

You can verify that flux has connected to your repository by running `kubectl get gitrepo -n flux` and viewing the status.

- Once the GitRepo has connected, you can run `kubectl apply -f flux-kustomize.yaml` to have flux observe and reconcile changes to project resources.

- Verify that the istio ingress gateway is up by using `kubectl get gateway -n istio-system`. Check that the UI is available by running: `curl -L -H "Host: k8s-demo.local" http://localhost -v`, you will need to trust the `certs/ca.crt` on your machine to connect via curl.

> In Ubuntu: `sudo cp certs/ca.crt /usr/local/share/ca-certificates/ && sudo update-ca-certificates`<br/><br/>
If working in WSL2 or using `snap`, you can trust the CA in Firefox by executing the following command: `CERT_DIR=/home/<YOUR_USER>/snap/firefox/common/.mozilla/firefox/<ID>.default/; certutil -d 
sql:$CERT_DIR -A -t "C,," -n "Istio Ingress CA" -i certs/ca.crt`

# Routing through the ingress
```mermaid
flowchart TD
    Browser["Browser<br/>k8s-demo.local"]
    
    subgraph Kind["Kind Cluster"]
        subgraph NodePorts["Node Ports"]
            Port80[":80<br/>NodePort 30080"]
            Port443[":443<br/>NodePort 30443"]
        end
        
        subgraph IstioSystem["istio-system namespace"]
            Gateway["Istio Gateway<br/>(main)"]
            IGService["Istio Ingress Gateway Service<br/>(NodePort)"]
            IGPod["Istio Ingress Gateway Pod"]
        end
        
        subgraph K8sDemoApp["k8s-demo-app namespace"]
            VS["Virtual Service<br/>(ui-virtual-service)"]
            UIService["UI Service<br/>(k8s-demo-ui-service)<br/>port: 3000"]
            UIPod1["UI Pod 1<br/>port: 3000"]
            UIPod2["UI Pod 2<br/>port: 3000"]
            UIPod3["UI Pod 3<br/>port: 3000"]
        end
    end
    
    %% External traffic flow
    Browser -->|HTTPS| Port443
    Browser -->|HTTP| Port80
    
    %% Internal traffic flow
    Port80 --> IGService
    Port443 --> IGService
    IGService --> IGPod
    IGPod --> Gateway
    Gateway --> VS
    VS --> UIService
    UIService --> UIPod1
    UIService --> UIPod2
    UIService --> UIPod3
    
    %% Styling
    %% Updated color scheme
    classDef namespace fill:#f0f4f8,stroke:#8b9cb3,stroke-width:2px
    class IstioSystem,K8sDemoApp namespace
    
    classDef pod fill:#dceefb,stroke:#0b69a3,stroke-width:2px
    class UIPod1,UIPod2,UIPod3,IGPod pod
    
    classDef service fill:#ede9fe,stroke:#7c3aed,stroke-width:2px
    class UIService,IGService service
    
    classDef gateway fill:#d1fae5,stroke:#059669,stroke-width:2px
    class Gateway gateway
    
    classDef virtualservice fill:#fef3c7,stroke:#d97706,stroke-width:2px
    class VS virtualservice

    %% Additional styling for other components
    classDef browser fill:#f8fafc,stroke:#475569,stroke-width:2px
    class Browser browser

    classDef nodeports fill:#fee2e2,stroke:#dc2626,stroke-width:2px
    class Port80,Port443 nodeports
```