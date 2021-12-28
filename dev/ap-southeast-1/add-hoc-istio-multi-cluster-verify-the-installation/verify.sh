
kubectl create --context="${CTX_CLUSTER1}" namespace sample
kubectl create --context="${CTX_CLUSTER2}" namespace sample


kubectl label --context="${CTX_CLUSTER1}" namespace sample \
    istio-injection=enabled
kubectl label --context="${CTX_CLUSTER2}" namespace sample \
    istio-injection=enabled


kubectl apply --context="${CTX_CLUSTER1}" \
    -f ../../../istio/istio-1.8.1/samples/helloworld/helloworld.yaml \
    -l service=helloworld -n sample

kubectl apply --context="${CTX_CLUSTER2}" \
    -f ../../../istio/istio-1.8.1/samples/helloworld/helloworld.yaml \
    -l service=helloworld -n sample


#Deploy HelloWorld V1
kubectl apply --context="${CTX_CLUSTER1}" \
    -f ../../../istio/istio-1.8.1/samples/helloworld/helloworld.yaml \
    -l version=v1 -n sample


#Deploy HelloWorld V2

kubectl apply --context="${CTX_CLUSTER2}" \
    -f ../../../istio/istio-1.8.1/samples/helloworld/helloworld.yaml \
    -l version=v2 -n sample

#Deploy Sleep
kubectl apply --context="${CTX_CLUSTER1}" \
    -f ../../../istio/istio-1.8.1/samples/sleep/sleep.yaml -n sample

kubectl apply --context="${CTX_CLUSTER2}" \
    -f ../../../istio/istio-1.8.1/samples/sleep/sleep.yaml -n sample


#Verifying Cross-Cluster Traffic
kubectl exec --context="${CTX_CLUSTER1}" -n sample -c sleep \
    "$(kubectl get pod --context="${CTX_CLUSTER1}" -n sample -l \
    app=sleep -o jsonpath='{.items[0].metadata.name}')" \
    -- curl helloworld.sample:5000/hello

kubectl exec --context="${CTX_CLUSTER2}" -n sample -c sleep \
    "$(kubectl get pod --context="${CTX_CLUSTER2}" -n sample -l \
    app=sleep -o jsonpath='{.items[0].metadata.name}')" \
    -- curl helloworld.sample:5000/hello


kubectl  --context="${CTX_CLUSTER1}" get pod -n sample