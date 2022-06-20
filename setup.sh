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

until oc patch argocd -n openshift-gitops openshift-gitops --type merge -p='{"spec":{"resourceCustomizations":"argoproj.io/Application:\n  health.lua: |\n    hs = {}\n    hs.status = \"Progressing\"\n    hs.message = \"\"\n    if obj.status ~= nil then\n      if obj.status.health ~= nil then\n        hs.status = obj.status.health.status\n        hs.message = obj.status.health.message\n      end\n    end\n    return hs\noperators.coreos.com/Subscription:\n  health.lua: |\n    hs = {}\n    if obj.status ~= nil then\n      if obj.status.currentCSV ~= nil and (obj.status.state == \"AtLatestKnown\" or obj.status.state == \"UpgradeAvailable\" or obj.status.state == \"UpgradePending\") then\n        hs.status = \"Healthy\"\n        hs.message = \"Subcription installed\"\n        return hs\n      end\n    end\n    hs.status = \"Progressing\"\n    hs.message = \"Waiting for Subscription to complete.\"\n    return hs\nplatform.stackrox.io/Central:\n  health.lua: |\n    hs = {}\n    if obj.status ~= nil and obj.status.conditions ~= nil then\n        for i, condition in ipairs(obj.status.conditions) do\n          if condition.status == \"True\" or condition.reason == \"InstallSuccessful\" or condition.reason == \"UpgradeSuccessful\" then\n              hs.status = \"Healthy\"\n              hs.message = \"Install Successful\"\n              return hs\n          end\n        end\n    end\n    hs.status = \"Progressing\"\n    hs.message = \"Waiting for Central to deploy.\"\n    return hs\nroute.openshift.io/Route:\n  ignoreDifferences: |\n    jsonPointers:\n    - /status/ingress\nintegreatly.org/GrafanaDataSource:\n  ignoreDifferences: |\n    jsonPointers:\n    - /spec/datasources/0/secureJsonData/httpHeaderValue1\nPersistentVolumeClaim:\n  health.lua: |\n    hs = {}\n    if obj.status ~= nil then\n      if obj.status.phase ~= nil then\n        if obj.status.phase == \"Pending\" then\n          hs.status = \"Healthy\"\n          hs.message = obj.status.phase\n          return hs\n        end\n        if obj.status.phase == \"Bound\" then\n          hs.status = \"Healthy\"\n          hs.message = obj.status.phase\n          return hs\n        end\n      end\n    end\n    hs.status = \"Progressing\"\n    hs.message = \"Waiting for certificate\"\n    return hs"}}' &> /dev/null; do
  printf "\rWaiting for ArgoCD Instance patch"
  sleep 2
done

until oc wait --for=jsonpath='{.status.server}'=Running argocd/openshift-gitops -n openshift-gitops &> /dev/null; do
  printf "\rWaiting for default ArgoCD Instance to start"
  sleep 2
done

#oc create -f ArgoCD/Infra/ServiceMesh/config.yaml

# # {"apiGroups": ["machine.openshift.io"], "resources": ["*"], "verbs":["*"]},
# 
# 

