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
    local result=$( curl -sf --cacert ${CACERT} --header "Authorization: Bearer ${TOKEN}" -X GET "${API_SERVER}/api/v1/namespaces/${K8S_NAMESPACE}/pods/${K8S_POD_NAME}" )
    echo $result
}

# Returns the number of istio-proxy pods running
# Expected 1 or 0
function getProxyRunningCount(){
    local response=`getDetails`
    if [[ "$response" != "" ]];
    then
        echo $response | jq  --arg proxy "$ISTIO_PROXY_NAME" '[.status.containerStatuses[] | select(.name==$proxy and .state.running)] | length';
    fi
}

function getPodRunningCount(){
    local response=`getDetails`
    if [[ "$response" != "" ]];
    then
        echo $response  | jq  --arg proxy "$ISTIO_PROXY_NAME" --arg self "$K8S_SELF_NAME" '[.status.containerStatuses[] | select(.name!=$proxy and .name!=$self) | (.state.terminated.exitCode // 1) ] | add';
    fi
}

while true;
do
    sleep $SLEEP_INTERVAL
    PODRUNNING=`getPodRunningCount`
    PROXYRUNNING=`getProxyRunningCount`
    echo "{\"message\": \"Checking for completion.\"}"
    if [[ "$PODRUNNING" == "" &&  "$PROXYRUNNING" == "" ]]; then
        echo "{\"message\": \"Pod not ready yet.\"}"
    else
        echo "{\"message\": \"Found ${PODRUNNING} out of 0 expected job containers running.\"}"
        echo "{\"message\": \"Found ${PROXYRUNNING} out of 1 istio proxy containers running.\"}"
    fi
    
    if [[ "$PODRUNNING" -eq "0" && "$PROXYRUNNING" -eq "1" ]]; then
        echo "{\"message\": \"Quitting conditions met, calling /quitquitquit on istio-proxy\"}"
        curl -sf -XPOST http://$ISTIO_ENDPOINT/quitquitquit &>/dev/null
        exit 0
    fi
    echo "{\"message\": \"Sleeping for ${SLEEP_INTERVAL}.\"}"
    
done
