
export CTX_CLUSTER1=arn:aws:eks:ap-southeast-1:891349355538:cluster/eks-istio-cluster-1-dev-v1
export CTX_CLUSTER2=arn:aws:eks:ap-southeast-1:891349355538:cluster/eks-istio-cluster-2-dev-v1
export PATH=$PATH:$HOME/.istioctl/bin

cat <<EOF > cluster1.yaml
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

istioctl install --context="${CTX_CLUSTER1}" -f cluster1.yaml


cat <<EOF > cluster2.yaml
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



istioctl install --context="${CTX_CLUSTER2}" -f cluster2.yaml

#Install the east-west gateway in cluster1

../../../istio/istio-1.8.0/samples/multicluster/gen-eastwest-gateway.sh \
    --mesh mesh1 --cluster cluster1 --network network1 | \
    istioctl --context="${CTX_CLUSTER1}" install -y -f -

#Expose services in cluster1
kubectl --context="${CTX_CLUSTER1}" apply -n istio-system -f \
    ../../../istio/istio-1.8.0/samples/multicluster/expose-services.yaml

#Install the east-west gateway in cluster2

../../../istio/istio-1.8.0/samples/multicluster/gen-eastwest-gateway.sh \
    --mesh mesh1 --cluster cluster2 --network network2 | \
    istioctl --context="${CTX_CLUSTER2}" install -y -f -

#Expose services in cluster2
kubectl --context="${CTX_CLUSTER2}" apply -n istio-system -f \
    ../../../istio/istio-1.8.0/samples/multicluster/expose-services.yaml


istioctl x create-remote-secret \
    --context="${CTX_CLUSTER1}" \
    --name=cluster1 | \
    kubectl apply -f - --context="${CTX_CLUSTER2}"


istioctl x create-remote-secret \
    --context="${CTX_CLUSTER2}" \
    --name=cluster2 | \
    kubectl apply -f - --context="${CTX_CLUSTER1}"




