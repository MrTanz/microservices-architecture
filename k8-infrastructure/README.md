# BUILD IMAGE IN MINIKUBE
eval $(minikube docker-env)
docker build -t <image-name>:<image-tag> .

eval $(minikube docker-env)
docker build -t auth-service:latest .