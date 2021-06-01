#!/bin/bash
docker build . -t <account_id>.dkr.ecr.us-east-1.amazonaws.com/ryantest:validator
docker push <account_id>.dkr.ecr.us-east-1.amazonaws.com/ryantest:validator
kubectl delete -f validatingwebhook.yml
kubectl delete pods --all -n $NAMESPACE
sleep 5
kubectl apply -f validatingwebhook.yml
kubectl run testpod --image=nginx -n $NAMESPACE
kubectl get pods -n $NAMESPACE

