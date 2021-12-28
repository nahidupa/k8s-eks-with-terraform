
export CTX_CLUSTER1=arn:aws:eks:ap-southeast-1:891349355538:cluster/eks-istio-cluster-1-dev-v1
export CTX_CLUSTER2=arn:aws:eks:ap-southeast-1:891349355538:cluster/eks-istio-cluster-2-dev-v1
export PATH=$PATH:$HOME/.istioctl/bin

#install root-ca to both cluster

pushd
cd certs


make -f ../../../../istio/istio-1.8.1/tools/certs/Makefile.selfsigned.mk root-ca

make -f ../../../../istio/istio-1.8.1/tools/certs/Makefile.selfsigned.mk cluster1-cacerts

make -f ../../../../istio/istio-1.8.1/tools/certs/Makefile.selfsigned.mk cluster2-cacerts


kubectl --context="${CTX_CLUSTER1}" create namespace istio-system

kubectl --context="${CTX_CLUSTER1}" create secret generic cacerts -n istio-system \
      --from-file=cluster1/ca-cert.pem \
      --from-file=cluster1/ca-key.pem \
      --from-file=cluster1/root-cert.pem \
      --from-file=cluster1/cert-chain.pem

kubectl --context="${CTX_CLUSTER2}" create namespace istio-system

kubectl --context="${CTX_CLUSTER2}" create secret generic cacerts -n istio-system \
      --from-file=cluster2/ca-cert.pem \
      --from-file=cluster2/ca-key.pem \
      --from-file=cluster2/root-cert.pem \
      --from-file=cluster2/cert-chain.pem

popd

#Set the default network for cluster1

kubectl --context="${CTX_CLUSTER1}" label namespace istio-system topology.istio.io/network=network1

cat <<EOF > install-multi-primary-cluster1.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  values:
    global:
      meshID: mesh1
      multiCluster:
        clusterName: cluster1
      network: network1
EOF

istioctl install --context="${CTX_CLUSTER1}" -f install-multi-primary-cluster1.yaml

#Install the east-west gateway in cluster1
../../../istio/istio-1.8.1/samples/multicluster/gen-eastwest-gateway.sh \
    --mesh mesh1 --cluster cluster1 --network network1 > eastwest-gateway-cluster1.yaml

cat eastwest-gateway-cluster1.yaml | istioctl --context="${CTX_CLUSTER1}" install -y -f -


#Expose services in cluster1
kubectl --context="${CTX_CLUSTER1}" apply -n istio-system -f \
    ../../../istio/istio-1.8.1/samples/multicluster/expose-services.yaml


#Set the default network for cluster2

cat <<EOF > install-multi-primary-cluster2.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  values:
    global:
      meshID: mesh1
      multiCluster:
        clusterName: cluster2
      network: network2
EOF

kubectl --context="${CTX_CLUSTER2}" label namespace istio-system topology.istio.io/network=network2
istioctl install --context="${CTX_CLUSTER2}" -f install-multi-primary-cluster2.yaml




#Install the east-west gateway in cluster2


../../../istio/istio-1.8.1/samples/multicluster/gen-eastwest-gateway.sh \
    --mesh mesh1 --cluster cluster2 --network network2 > eastwest-gateway-cluster2.yaml

cat eastwest-gateway-cluster2.yaml | istioctl --context="${CTX_CLUSTER2}" install -y -f -


#Expose services in cluster2

kubectl --context="${CTX_CLUSTER2}" apply -n istio-system -f \
../../../istio/istio-1.8.1/samples/multicluster/expose-services.yaml


#Enable Endpoint Discovery
istioctl x create-remote-secret \
  --context="${CTX_CLUSTER1}" \
  --name=cluster1 | \
  kubectl apply -f - --context="${CTX_CLUSTER2}"


istioctl x create-remote-secret \
  --context="${CTX_CLUSTER2}" \
  --name=cluster2 | \
  kubectl apply -f - --context="${CTX_CLUSTER1}"


kubectl --context="${CTX_CLUSTER1}" apply -f ../../../istio/istio-1.8.1/samples/addons/kiali.yaml

kubectl --context="${CTX_CLUSTER1}" apply -f ../../../istio/istio-1.8.1/samples/addons/prometheus.yaml

istioctl --context="${CTX_CLUSTER1}" dashboard kiali


kubectl --context="${CTX_CLUSTER1}" apply -n istio-system -f expose-services.yaml

kubectl --context="${CTX_CLUSTER2}" apply -n istio-system -f expose-services.yaml

kubectl --context="${CTX_CLUSTER2}" delete namespace istio-system
