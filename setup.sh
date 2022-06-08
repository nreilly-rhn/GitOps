#!/bin/env bash

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
echo -n ""
until oc wait --for=jsonpath='{.status.server}'=Running argocd/openshift-gitops -n openshift-gitops; do
  echo -n "Waiting for default ArgoCD Instance to start"
  sleep 5
done

oc create -f argocd/applications/OpenShift-ServiceMesh/config.yaml