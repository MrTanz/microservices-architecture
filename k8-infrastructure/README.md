# BUILD IMAGE IN MINIKUBE
eval $(minikube docker-env)
docker build -t <image-name>:<image-tag> .

# UPGRADE CHART
helm upgrade <release-name> . --atomic -f values.yaml

eval $(minikube docker-env)
docker build -t auth-service:latest .

eval $(minikube docker-env)
docker build -t user-service:latest .

eval $(minikube docker-env)
docker build -t api-gateway:latest .

helm upgrade local . -f values.yaml