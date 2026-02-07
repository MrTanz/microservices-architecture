# BUILD IMAGE IN MINIKUBE
eval $(minikube docker-env)
docker build -t <image-name>:<image-tag> .

# UPGRADE CHART
helm upgrade <release-name> . --atomic -f values.yaml

# METRICS CONFIG
minikube addons enable metrics-server
kubectl get pods -n kube-system | grep metrics-server

_if metrics-server in crash (TLS issues)_
kubectl rollout restart deployment metrics-server -n kube-system

# TEST AUTOSCALING
kubectl exec -it <pod-name> -- /bin/sh
while true; do :; done

eval $(minikube docker-env)
docker build -t auth-service:latest .

eval $(minikube docker-env)
docker build -t user-service:latest .

eval $(minikube docker-env)
docker build -t api-gateway:latest .

helm upgrade local . -f values.yaml