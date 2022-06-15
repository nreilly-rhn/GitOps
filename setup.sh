#!/bin/env bash

if oc get crd argocds.argoproj.io &> /dev/null; then
  echo "Operator already installed..."
else
  echo 'apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: openshift-gitops-operator
  namespace: openshift-operators
spec:
  channel: latest
  name: openshift-gitops-operator
  source: redhat-operators
  sourceNamespace: openshift-marketplace' |oc create -f -
  echo ""
fi
sleep 30

until oc patch argocd -n openshift-gitops openshift-gitops --type merge -p='{"spec": {"resourceCustomizations": "argoproj.io/Application:\n  health.lua: |\n    hs = {}\n    hs.status = \"Progressing\"\n    hs.message = \"\"\n    if obj.status ~= nil then\n      if obj.status.health ~= nil then\n        hs.status = obj.status.health.status\n        if obj.status.health.message ~= nil then\n          hs.message = obj.status.health.message\n        end\n      end\n    end\n    return hs\n" }}' &> /dev/null; do
  echo "Waiting for ArgoCD Instance patch"
  sleep 5
done

until oc wait --for=jsonpath='{.status.server}'=Running argocd/openshift-gitops -n openshift-gitops &> /dev/null; do
  echo "Waiting for default ArgoCD Instance to start"
  sleep 10
done

oc create -f ArgoCD/Infra/ServiceMesh/config.yaml

# # {"apiGroups": ["machine.openshift.io"], "resources": ["*"], "verbs":["*"]},
# 
# 
# apiVersion: rbac.authorization.k8s.io/v1
# kind: ClusterRole
# metadata:
#   labels:
#   name: openshift-gitops-openshift-gitops-argocd-application-controller-miastra
# rules:
# - apiGroups:
#   - 'miastra.io'
#   resources:
#   - '*'
#   verbs:
#   - '*'
# 
# 
# apiVersion: rbac.authorization.k8s.io/v1
# kind: ClusterRoleBinding
# metadata:
#   name: openshift-gitops-openshift-gitops-argocd-application-controller-miastra
# roleRef:
#   apiGroup: rbac.authorization.k8s.io
#   kind: ClusterRole
#   name: openshift-gitops-openshift-gitops-argocd-application-controller-miastra
# subjects:
# - kind: ServiceAccount
#   name: openshift-gitops-argocd-application-controller
#   namespace: openshift-gitops
