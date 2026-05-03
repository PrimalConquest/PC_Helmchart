#!/bin/bash
set -uo pipefail   # no -e so every step attempts even if previous fails

source "$(dirname "$0")/config.sh"

echo "========================================"
echo "  Primal Conquest — Full Clean"
echo "========================================"

# ── Helpers ───────────────────────────────────────────────────────

# Strip finalizers from every resource of a given type in a namespace
# so Kubernetes stops blocking their deletion.
strip_finalizers() {
  local resource=$1
  local namespace=$2
  echo "    Stripping finalizers from $resource in '$namespace'..."
  kubectl get "$resource" -n "$namespace" --kubeconfig "$KUBECONFIG" \
    -o name 2>/dev/null | while read -r name; do
      kubectl patch "$name" -n "$namespace" --kubeconfig "$KUBECONFIG" \
        --type=merge -p '{"metadata":{"finalizers":[]}}' 2>/dev/null || true
    done
}

# Strip finalizers from a namespace itself (prevents namespace getting stuck
# in Terminating state forever).
strip_namespace_finalizers() {
  local ns=$1
  echo "    Stripping finalizers from namespace '$ns'..."
  kubectl patch namespace "$ns" --kubeconfig "$KUBECONFIG" \
    --type=merge -p '{"metadata":{"finalizers":[]}}' 2>/dev/null || true
  # Also clear the spec.finalizers array used by namespace controllers
  kubectl get namespace "$ns" --kubeconfig "$KUBECONFIG" -o json 2>/dev/null \
    | sed 's/"finalizers": \[[^]]*\]/"finalizers": []/' \
    | kubectl replace --raw "/api/v1/namespaces/$ns/finalize" \
        --kubeconfig "$KUBECONFIG" -f - 2>/dev/null || true
}

# ── Strip finalizers before deletion ─────────────────────────────
echo ""
echo ">>> Stripping resource finalizers..."

strip_finalizers gameservers       "$NAMESPACE"
strip_finalizers gameserversets    "$NAMESPACE"
strip_finalizers fleets            "$NAMESPACE"
strip_finalizers fleetautoscalers  "$NAMESPACE"
strip_finalizers pods              "$NAMESPACE"
strip_finalizers pvc               "$NAMESPACE"

strip_finalizers gameservers    agones-system
strip_finalizers gameserversets agones-system
strip_finalizers pods           agones-system

# ── Delete all resources in the game namespace ────────────────────
echo ""
echo ">>> Deleting all resources in namespace '$NAMESPACE'..."
kubectl delete all --all -n "$NAMESPACE" --kubeconfig "$KUBECONFIG" 2>/dev/null || true

echo ">>> Deleting PersistentVolumeClaims..."
kubectl delete pvc --all -n "$NAMESPACE" --kubeconfig "$KUBECONFIG" 2>/dev/null || true

echo ">>> Deleting Secrets..."
kubectl delete secret --all -n "$NAMESPACE" --kubeconfig "$KUBECONFIG" 2>/dev/null || true

echo ">>> Deleting ConfigMaps..."
kubectl delete configmap --all -n "$NAMESPACE" --kubeconfig "$KUBECONFIG" 2>/dev/null || true

echo ">>> Deleting ServiceAccounts..."
kubectl delete serviceaccount --all -n "$NAMESPACE" --kubeconfig "$KUBECONFIG" 2>/dev/null || true

echo ">>> Deleting RBAC (Roles / RoleBindings)..."
kubectl delete role --all -n "$NAMESPACE" --kubeconfig "$KUBECONFIG" 2>/dev/null || true
kubectl delete rolebinding --all -n "$NAMESPACE" --kubeconfig "$KUBECONFIG" 2>/dev/null || true

echo ">>> Deleting Agones GameServers and Fleets..."
kubectl delete fleetautoscalers --all -n "$NAMESPACE" --kubeconfig "$KUBECONFIG" 2>/dev/null || true
kubectl delete fleets           --all -n "$NAMESPACE" --kubeconfig "$KUBECONFIG" 2>/dev/null || true
kubectl delete gameserversets   --all -n "$NAMESPACE" --kubeconfig "$KUBECONFIG" 2>/dev/null || true
kubectl delete gameservers      --all -n "$NAMESPACE" --kubeconfig "$KUBECONFIG" 2>/dev/null || true

# ── Wipe agones-system namespace resources ────────────────────────
echo ""
echo ">>> Deleting all resources in namespace 'agones-system'..."
kubectl delete all --all -n agones-system --kubeconfig "$KUBECONFIG" 2>/dev/null || true
kubectl delete secret --all -n agones-system --kubeconfig "$KUBECONFIG" 2>/dev/null || true
kubectl delete configmap --all -n agones-system --kubeconfig "$KUBECONFIG" 2>/dev/null || true
kubectl delete serviceaccount --all -n agones-system --kubeconfig "$KUBECONFIG" 2>/dev/null || true
kubectl delete role --all -n agones-system --kubeconfig "$KUBECONFIG" 2>/dev/null || true
kubectl delete rolebinding --all -n agones-system --kubeconfig "$KUBECONFIG" 2>/dev/null || true

# ── Delete cluster-scoped Agones resources ────────────────────────
echo ""
echo ">>> Deleting Agones PriorityClasses..."
kubectl delete priorityclass agones-system agones-sdk \
  --kubeconfig "$KUBECONFIG" 2>/dev/null || true

echo ">>> Deleting Agones CRDs..."
AGONES_CRDS=$(kubectl get crd --kubeconfig "$KUBECONFIG" 2>/dev/null \
  | grep agones.dev | awk '{print $1}')
if [ -n "$AGONES_CRDS" ]; then
  # Strip CRD finalizers first or they can block too
  for crd in $AGONES_CRDS; do
    kubectl patch crd "$crd" --kubeconfig "$KUBECONFIG" \
      --type=merge -p '{"metadata":{"finalizers":[]}}' 2>/dev/null || true
  done
  kubectl delete crd $AGONES_CRDS --kubeconfig "$KUBECONFIG" 2>/dev/null || true
else
  echo "    No Agones CRDs found."
fi

echo ">>> Deleting ClusterRoles / ClusterRoleBindings for Agones..."
kubectl get clusterrole --kubeconfig "$KUBECONFIG" 2>/dev/null \
  | grep agones | awk '{print $1}' \
  | xargs -r kubectl delete clusterrole --kubeconfig "$KUBECONFIG" 2>/dev/null || true

kubectl get clusterrolebinding --kubeconfig "$KUBECONFIG" 2>/dev/null \
  | grep agones | awk '{print $1}' \
  | xargs -r kubectl delete clusterrolebinding --kubeconfig "$KUBECONFIG" 2>/dev/null || true

# ── Uninstall Helm releases ───────────────────────────────────────
# --no-hooks skips pre/post-delete hooks so Helm doesn't wait on stuck resources.
# If it still fails we force-remove the release by deleting the Helm state secret.
echo ""
echo ">>> Uninstalling Helm release '$RELEASE_NAME'..."
sudo helm uninstall "$RELEASE_NAME" --kubeconfig "$KUBECONFIG" \
  --no-hooks --timeout 30s 2>/dev/null \
  && echo "    Done." \
  || {
    echo "    helm uninstall timed out — force-removing release record..."
    kubectl delete secret -n "$NAMESPACE" \
      -l "owner=helm,name=$RELEASE_NAME" \
      --kubeconfig "$KUBECONFIG" 2>/dev/null || true
    kubectl delete secret -n default \
      -l "owner=helm,name=$RELEASE_NAME" \
      --kubeconfig "$KUBECONFIG" 2>/dev/null || true
  }

echo ">>> Uninstalling Helm release 'agones'..."
sudo helm uninstall agones -n agones-system --kubeconfig "$KUBECONFIG" \
  --no-hooks --timeout 30s 2>/dev/null \
  && echo "    Done." \
  || {
    echo "    helm uninstall timed out — force-removing release record..."
    kubectl delete secret -n agones-system \
      -l "owner=helm,name=agones" \
      --kubeconfig "$KUBECONFIG" 2>/dev/null || true
  }

# ── Delete namespaces ─────────────────────────────────────────────
echo ""
strip_namespace_finalizers "$NAMESPACE"
echo ">>> Deleting namespace '$NAMESPACE'..."
kubectl delete namespace "$NAMESPACE" --kubeconfig "$KUBECONFIG" 2>/dev/null \
  && echo "    Done." || echo "    Not found, skipping."

strip_namespace_finalizers agones-system
echo ">>> Deleting namespace 'agones-system'..."
kubectl delete namespace agones-system --kubeconfig "$KUBECONFIG" 2>/dev/null \
  && echo "    Done." || echo "    Not found, skipping."

echo ""
echo "========================================"
echo "  Clean complete. Cluster is empty."
echo "========================================"
