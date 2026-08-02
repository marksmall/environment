# Personal kubectl/AKS aliases and functions for Oh My Zsh, loaded after (and
# in one case overriding) the built-in `kubectl` plugin — `kge` here adds -A
# (all namespaces) to the built-in's version. Named "-local" to make that
# override explicit rather than an invisible last-source-wins accident.

function ksdv() {
  kubectl get secret $1 -o yaml | grep $2 | awk '{print $2}' | base64 --decode
}

function kas() {
  kubectl get secret $1 -o json | jq '.data | with_entries(.value |= @base64d)'
}

function kph() {
  kubectl describe pods -l app=$1,instance=$2 | grep -A 5 Conditions
}

# Attach a netshoot debug container to a pod found by label selector.
# Usage: kdebug <namespace> <label-selector> [target-container]
# e.g.:  kdebug dsp-nginx app=dsp-nginx-app
#
# Don't know the labels for a given deployment? List them:
#   kubectl get pods -n <namespace> --show-labels | grep <deployment-name>
# e.g.:
#   kubectl get pods -n dsp-nginx --show-labels | grep dsp-nginx-app
function kdebug() {
  local namespace="$1"
  local selector="$2"
  local target="$3"

  if [[ -z "$namespace" || -z "$selector" ]]; then
    echo "Usage: kdebug <namespace> <label-selector> [target-container]" >&2
    return 1
  fi

  local pods
  pods=($(kubectl get pods -n "$namespace" -l "$selector" -o jsonpath='{.items[*].metadata.name}'))

  if [[ ${#pods[@]} -eq 0 ]]; then
    echo "No pods found in namespace '$namespace' matching selector '$selector'" >&2
    return 1
  elif [[ ${#pods[@]} -gt 1 ]]; then
    echo "Multiple pods match — using the first (${pods[1]}). Others: ${pods[*]:1}" >&2
  fi

  local pod="${pods[1]}"

  if [[ -z "$target" ]]; then
    target=$(kubectl get pod "$pod" -n "$namespace" -o jsonpath='{.spec.containers[0].name}')
  fi

  echo "Attaching netshoot to pod '$pod' (target container: '$target') in namespace '$namespace'..." >&2
  kubectl debug -it "$pod" -n "$namespace" --image=nicolaka/netshoot --target="$target" -- /bin/bash
}

alias kgpbp='kubectl get pods -A --no-headers | awk "\$4 != \"Running\" && \$4 != \"Completed\""'

# Get all pods in Terminated / Evicted State
alias epods='kubectl get pods -n default | egrep -i "Terminated|Evicted" | awk "{print $1 }"'
alias depods='kubectl get pods -n default | egrep -i "Terminated|Evicted" | cut -d " " -f 1 | xargs kubectl delete pod --force=true --wait=false --grace-period=0'

KUBE_POD_COLUMNS='NS:.metadata.namespace,NAME:.metadata.name,STATUS:.status.phase,RESTARTS:.status.containerStatuses[*].restartCount,NODE:.spec.nodeName'

# Show broken pods
alias kgpb='kubectl get pods -A --field-selector-status.phase!=Running'
# Show broken pods and show node
alias kgpbn='kubectl get pods -A -o custom-columns="${KUBE_POD_COLUMNS}" | egrep "Error|CrashLoopBackOff|IIIImagePullBackOff|Pending"'
# Get pods on a node
alias kgpnode='kubectl get pods -A -o custom-columns="${KUBE_POD_COLUMNS}" | grep'
# Get pods that keep restarting
alias kgpr='kubectl get pods -A --sort-by=.status.containerStatuses[0].restartCount'
# NOTE You can combine this with `--watch` to see live events, or `| tail -<n>` to see only
#      the most recent
alias kge='kubectl get events -A --sort-by=.lastTimestamp'
# Get pods on bad node (node name as argument)
alias kgpbn='kubectl get pods -A -o custom-columns="${KUBE_POD_COLUMNS}" --field-selector spec.nodeName='
# Drain a node
alias kdn='kubectl drain --ignore-daemonsets --delete-emptydir-data'
# Get pods distributed across nodes
alias kgpns='kubectl get pods -A -o wide | awk "{print \$8}" | sort | uniq -c'
alias kgpaw='kubectl get pods -A -o custom-columns=${KUBE_POD_COLUMNS}"'

function dcsec {
  local secret=${1:?"Secret to decode must be specified as first parameter"}
  local namespace=${2:="default"}

  kubectl get secret -n ${namespace} ${secret} -o json | jq '.data | map_values(@base64d)'
}

# If no output, node fully drained
kgpc () {
  kubectl get pods -A -o json | \
  jq -r --arg NODE "$1" \
  '.items[] |
   select(.spec.nodeName==$NODE) |
   select(.metadata.ownerReferences[0].kind!="DaemonSet") |
   .metadata.namespace + "/" + .metadata.name'
}

# Safe AKS Node Replacement (node-name only)
# Usage: knr <node-name>
#
# This function performs a safe replacement of a Kubernetes node in an AKS cluster. It:
# 1. Discover nodepool metadata — reads the agentpool label from the node to find the pool name, resource group, and cluster name via az aks nodepool list
# 2. Record autoscaler settings — captures current minCount, maxCount, and count so they can be restored later
# 3. Disable the cluster autoscaler — prevents it interfering with the manual scaling steps
# 4. Scale the nodepool up by 1 — provisions a replacement node before evicting anything
# 5. Wait for the new node to be Ready — polls until CURRENT + 1 nodes are Ready in the pool
# 6. Drain the bad node — evicts all non-daemonset pods (--ignore-daemonsets --delete-emptydir-data)
# 7. Verify the drain — checks no non-daemonset pods remain on the node
# 8. Wait for pods to reschedule — polls until no non-daemonset pods are still assigned to the node
# 9. Delete the node — removes it from Kubernetes (triggers AKS to terminate the underlying VM)
# 10. Scale the nodepool back to original count — returns to pre-operation node count
# 11. Restore the autoscaler — re-enables it with the original min/max settings
#
knr() {
  if [[ -z "$1" ]]; then
    echo "Usage: knr <node-name>"
    return 1
  fi

  (
  set -e
  NODE="$1"
  fail() { echo "❌ ERROR: $1"; exit 1; }

  echo "=== Step 0: Discover nodepool, cluster, and resource group ==="
  POOL=$(kubectl get node "$NODE" -o jsonpath='{.metadata.labels.agentpool}') || fail "Could not detect node pool for $NODE"
  [[ -z "$POOL" ]] && fail "Node $NODE has no agentpool label"
  echo "Node pool detected: $POOL"

  RG=$(az aks nodepool list --query "[?name=='$POOL'].resourceGroup" -o tsv | head -n1) || fail "Could not detect resource group"
  CLUSTER=$(az aks nodepool list --query "[?name=='$POOL'].name" -o tsv | head -n1) || fail "Could not detect cluster"
  [[ -z "$RG" || -z "$CLUSTER" ]] && fail "Resource group or cluster not found for nodepool $POOL"
  echo "Cluster: $CLUSTER, Resource Group: $RG"

  echo "=== Step 1: Record autoscaler and node count ==="
  MIN=$(az aks nodepool show -g "$RG" -n "$POOL" --cluster-name "$CLUSTER" --query minCount -o tsv) || fail "Failed to get minCount"
  MAX=$(az aks nodepool show -g "$RG" -n "$POOL" --cluster-name "$CLUSTER" --query maxCount -o tsv) || fail "Failed to get maxCount"
  CURRENT=$(az aks nodepool show -g "$RG" -n "$POOL" --cluster-name "$CLUSTER" --query count -o tsv) || fail "Failed to get current count"
  echo "Current count=$CURRENT, min=$MIN, max=$MAX"

  echo "=== Step 2: Disable autoscaler ==="
  az aks nodepool update -g "$RG" -n "$POOL" --cluster-name "$CLUSTER" --disable-cluster-autoscaler || fail "Failed to disable autoscaler"

  echo "=== Step 3: Scale nodepool up by 1 ==="
  az aks nodepool scale -g "$RG" -n "$POOL" --cluster-name "$CLUSTER" --node-count $((CURRENT + 1)) || fail "Failed to scale up nodepool"

  echo "=== Step 4: Wait for new node to be Ready ==="
  echo "Waiting for new node to be Ready..."
  while true; do
    READY_COUNT=$(kubectl get nodes --selector="agentpool=$POOL" --no-headers | grep -c ' Ready')
    if [[ "$READY_COUNT" -ge $((CURRENT + 1)) ]]; then
      echo "All nodes Ready"
      break
    fi
    sleep 5
  done

  echo "=== Step 5: Drain node $NODE ==="
  kubectl drain "$NODE" --ignore-daemonsets --delete-emptydir-data || fail "Failed to drain node $NODE"

  echo "=== Step 6: Verify node drained ==="
  kubectl get nodes | grep "$NODE" || fail "Node $NODE not found"
  REMAINING_PODS=$(kubectl get pods -A -o json | jq -r --arg NODE "$NODE" '.items[] | select(.spec.nodeName==$NODE) | select(.metadata.ownerReferences[0].kind!="DaemonSet") | .metadata.namespace + "/" + .metadata.name')
  if [[ -n "$REMAINING_PODS" ]]; then
    fail "Non-daemonset pods still on node:\n$REMAINING_PODS"
  fi
  echo "Node $NODE drained successfully (only DaemonSets remain)"

  echo "=== Step 7: Wait for pods to be rescheduled on other nodes ==="
  echo "Waiting for all pods that were on $NODE to move..."
  while true; do
    PODS_ON_NODE=$(kubectl get pods -A -o json | jq -r --arg NODE "$NODE" '.items[] | select(.spec.nodeName==$NODE) | select(.metadata.ownerReferences[0].kind!="DaemonSet") | .metadata.name')
    if [[ -z "$PODS_ON_NODE" ]]; then
      echo "All pods rescheduled off $NODE"
      break
    fi
    sleep 5
  done

  echo "=== Step 8: Delete bad node ==="
  kubectl delete node "$NODE" || fail "Failed to delete node $NODE"

  echo "=== Step 9: Scale nodepool back to original count ($CURRENT) ==="
  az aks nodepool scale -g "$RG" -n "$POOL" --cluster-name "$CLUSTER" --node-count "$CURRENT" || fail "Failed to scale back down"

  echo "=== Step 10: Restore autoscaler ==="
  az aks nodepool update -g "$RG" -n "$POOL" --cluster-name "$CLUSTER" \
    --enable-cluster-autoscaler --min-count "$MIN" --max-count "$MAX" || fail "Failed to restore autoscaler"

  echo "✅ Node replacement workflow completed successfully"
  )
}

k-top-node() {
  local node="$1"

  if [ -z "$node" ]; then
    echo "Usage: k-top-node <node-name>"
    return 1
  fi

  echo "🔍 Pods on node: $node"
  echo "----------------------------------------"

  kubectl get pods -A -o wide \
    | awk -v node="$node" '$8 == node {print $1, $2}' \
    | while read -r ns pod; do
        kubectl top pod -n "$ns" "$pod" --no-headers 2>/dev/null \
          | awk -v ns="$ns" -v pod="$pod" '{print ns, pod, $2, $3}'
      done \
    | sort -k3 -nr \
    | awk 'BEGIN {printf "%-15s %-50s %-10s %-10s\n", "NAMESPACE", "POD", "CPU", "MEMORY"}
           {printf "%-15s %-50s %-10s %-10s\n", $1, $2, $3, $4}'
}
