#!/bin/sh

ISTIO_PROXY_NAME=${ISTIO_PROXY_NAME:-"istio-proxy"}
ISTIO_ENDPOINT=${ISTIO_ENDPOINT:-"127.0.0.1:15020"}
K8S_SELF_NAME=${K8S_SELF_NAME:="istio-proxy-quit"}
SLEEP_INTERVAL=${SLEEP_INTERVAL:-"5s"}
API_SERVER=${API_SERVER:-"https://kubernetes.default.svc"}
SERVICE_ACCOUNT=${SERVICE_ACCOUNT:-"/var/run/secrets/kubernetes.io/serviceaccount"}
TOKEN=$(cat ${SERVICE_ACCOUNT}/token)
CACERT=${SERVICE_ACCOUNT}/ca.crt

function getDetails(){
    local result=$( curl --cacert ${CACERT} --header "Authorization: Bearer ${TOKEN}" -X GET "${API_SERVER}/api/v1/namespaces/${K8S_NAMESPACE}/pods" )
    echo $result
}

# Returns the number of istio-proxy pods running
# Expected 1 or 0
function getProxyRunningCount(){
    echo `getDetails` | jq  --arg proxy "$ISTIO_PROXY_NAME" '[.status.containerStatuses[] | select(.name==$proxy and .state.running)] | length'
}

function getPodRunningCount(){
    echo `getDetails` | jq  --arg proxy "$ISTIO_PROXY_NAME" --arg self "$K8S_SELF_NAME" '[.status.containerStatuses[] | select(.name!=$proxy and .name!=$self) | (.state.terminated.exitCode // 1) ] | add'
}

while true;
do
    echo "Checking for completion"
    podRunning=`getPodRunningCount`
    proxyRunning=`getProxyRunningCount`
    if [[ "$podRunning" -eq "0" && "$proxyRunning" -eq "1" ]]; then
        curl -sf -XPOST http://$ISTIO_ENDPOINT/quitquitquit
        exit 0
    fi
    
    echo "Found $podRunning out of 0 expected job containers running."
    echo "Found $proxyRunning out of 1 istio proxy containers running."
    echo "Sleeping for $SLEEP_INTERVAL"
    
    sleep $SLEEP_INTERVAL
done
