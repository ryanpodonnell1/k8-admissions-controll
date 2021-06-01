#!/bin/bash
docker build . -t 611181293678.dkr.ecr.us-east-1.amazonaws.com/ryantest:validator
docker push 611181293678.dkr.ecr.us-east-1.amazonaws.com/ryantest:validator
kubectl delete -f validatingwebhook.yml
kubectl delete pods --all -n tgrccloudsecurity
sleep 5
kubectl apply -f validatingwebhook.yml
kubectl run testpod --image=nginx -n tgrccloudsecurity
kubectl get pods -n tgrccloudsecurity

