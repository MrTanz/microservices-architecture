<!-- IMPORTANTE -->
Viene creato di default uno user con ruolo ADMIN. Altri utenti possono essere creati con la /sign-up
  username: admin@email.it
  password: admin1234

<!-- ATTENZIONE -->
1. Una volta creata l'infrastruttura vanno creati manualmente gli schema su RDS e pushate le immagini docker su ECR
2. Mancano le logiche per gestire le seguenti casistiche:
  - utente che esegue più login: deve essere valido solo l'ultimo token
  - utente che viene cancellato: il token deve essere revocato
  - se l'utente che effettua la chiamata di modifica ed elimina profilo ha solo permessi di USER allora deve poter effettuare
    tali operazioni limitatamente alla sua utenza
3. Manca certificato per traffico HTTPS verso l'ALB

<!-- NEXT STEPS -->
1. sqs_handler_sg deve instradare il traffico solo verso l'ecs task dell'auth-service
2. application_load_balancer_sg deve instradare il traffico solo verso l'ecs task dell'api-gateway
3. aws_ecr_repository_policy aggiungere nei Principal solo l'arn del ruolo di ecs
4. [BUG] ssm parameter database_url non deve essere sovrascritto dal modulo ssm una volta popolato dal modulo rds nei successivi deploy

<!-- PLAN -->
terraform plan --var-file="env.tfvars"

<!-- APPLY -->
terraform apply --var-file="env.tfvars"

<!-- DESTROY -->
terraform destroy --var-file="env.tfvars"

<!-- PORT FORWARDING BASTION HOST -->
ssh -i bastion_host_private_key_demo.pem -L 5432:microservices-db-demo.cxqey8soi410.eu-west-1.rds.amazonaws.com:5432 ec2-user@79.125.101.247
ssh -i bastion_host_private_key_<env>.pem -L <database-port-locale>:microservices-db-demo.cxqey8soi410.eu-west-1.rds.amazonaws.com:<database-port-rds> ec2-user@<public-ip-bastion-host>

<!-- DOCKER PUSH ON ECR -->
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t <account-id>.dkr.ecr.<region>.amazonaws.com/<repo>:<tag> \
  --push .