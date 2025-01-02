# generate csr
openssl req -new -nodes \
    -keyout k8s-demo.key \
    -out k8s-demo.csr \
    -config cert-config.conf

# sign the csr with the CA
openssl x509 -req -in k8s-demo.csr \
    -CA ca.crt \
    -CAkey ca.key \
    -CAcreateserial \
    -out k8s-demo.crt \
    -days 365 \
    -extensions v3_req \
    -extfile cert-config.conf

# print cert information for verification
openssl x509 -in k8s-demo.crt -text -noout

# dry run and print yaml for TLS secret
kubectl create secret tls -n istio-system istio-ingressgateway-certs --cert=k8s-demo.crt --key=k8s-demo.key --dry-run=client -o yaml

