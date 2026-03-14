# Istanza EC2 Bastion Host
resource "aws_instance" "bastion_host" {
  ami                         = "ami-0830343497187bc74"
  instance_type               = var.bastion_host_instance_class
  key_name                    = aws_key_pair.bastion_host_ssh_key.id
  subnet_id                   = var.public_subnet_a_id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.bastion_host_security_group.id]

  root_block_device {
    encrypted = true
  }

  tags = {
    Name        = "${var.project_name}-bastion-host-${var.env}"
    Environment = var.env
  }

}

# Elastic Ip
resource "aws_eip" "bastion_host_eip" {
  domain = "vpc"

  tags = {
    Name        = "${var.project_name}-bastion-host-elastic-ip-${var.env}"
    Environment = var.env
  }
}

# Associazione elastic ip con il bastion host
resource "aws_eip_association" "bastion_host_eip_association" {
  instance_id   = aws_instance.bastion_host.id
  allocation_id = aws_eip.bastion_host_eip.id
}

resource "tls_private_key" "bastion_host_private_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Creazione delle key pair per l'istanza in bastion host, dove gli associamo la chiave pubblica
resource "aws_key_pair" "bastion_host_ssh_key" {
  key_name   = "${var.project_name}-bastion-host-ssh-pair-${var.env}"
  public_key = tls_private_key.bastion_host_private_key.public_key_openssh
}

# Salvataggio della chiava privata in locale
resource "local_sensitive_file" "bastion_host_private_key_output" {
  content  = tls_private_key.bastion_host_private_key.private_key_pem
  filename = "bastion_host_private_key_${var.env}.pem"
}

# Security Group per Bastion Host
resource "aws_security_group" "bastion_host_security_group" {
  name   = "${var.project_name}-bastion-host-sg-${var.env}"
  vpc_id = var.vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-bastion-host-sg-${var.env}"
    Environment = var.env
  }
}

# ALB
resource "aws_alb" "application_load_balancer" {
  name               = "${var.project_name}-alb-${var.env}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.application_load_balancer_sg.id]
  subnets            = [var.public_subnet_a_id, var.public_subnet_b_id]
}

# SECURITY GROUP PER ALB
resource "aws_security_group" "application_load_balancer_sg" {
  name   = "${var.project_name}-alb-sg-${var.env}"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# TARGET GROUP
resource "aws_lb_target_group" "application_load_balancer_tg" {
  name        = "${var.project_name}-alb-tg-${var.env}"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = "/actuator/health"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  # gestire la disconnessione delle istanze (di default è già impostato a 300 secondi)
  deregistration_delay = 300
}

# ALB LISTENER
resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_alb.application_load_balancer.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.application_load_balancer_tg.arn
  }
}
