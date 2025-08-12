# Define a variable for your EC2 key pair name
variable "key_name" {
  description = "The name of your AWS EC2 key pair for SSH access."
  type        = string
  default     = "my-tf-generated-key"
}

resource "aws_security_group" "schema_registry_sg" {
  name        = "schema_registry_sg"
  description = "Allow Kafka and SSH access"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Kafka Port"
    from_port   = 9092
    to_port     = 9092
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Zookeeper Port"
    from_port   = 2181
    to_port     = 2181
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Schema Registry Port"
    from_port   = 8081
    to_port     = 8081
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

output "schema_registry_public_ip" {
  description = "The public IP address of the EC2 instance."
  value       = aws_instance.schema_registry_ec2.public_ip
}

resource "aws_instance" "schema_registry_ec2" {
  ami                    = "ami-05ffe3c48a9991133" # Amazon Linux 2 AMI
  instance_type          = "t2.medium"
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.schema_registry_sg.id]

  # This block customizes the root (/) volume
  root_block_device {
    volume_size = 50      # Size in GiB
    volume_type = "gp3"   # General Purpose SSD (recommended)
    delete_on_termination = true # The volume will be deleted when the instance is terminated
  }

  user_data = <<-EOF
              #!/bin/bash
              
              # Update the system
              sudo dnf update -y

              # Install Docker
              sudo dnf install -y docker
              sudo systemctl start docker
              sudo systemctl enable docker
              sudo usermod -aG docker ec2-user

              # Install Docker Compose Plugin
              sudo mkdir -p /usr/libexec/docker/cli-plugins
              sudo curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-$(uname -m) -o /usr/libexec/docker/cli-plugins/docker-compose
              sudo chmod +x /usr/libexec/docker/cli-plugins/docker-compose

              # Extract the public IP of EC2 instance
              export EC2_PUBLIC_IP=$(curl -s ifconfig.me)


              # Create the Docker Compose file in the ec2-user's home directory
              cat <<EOT > /home/ec2-user/compose.yml
              services:
                zookeeper:
                  image: confluentinc/cp-zookeeper:7.6.0
                  environment:
                    ZOOKEEPER_CLIENT_PORT: 2181
                kafka:
                  image: confluentinc/cp-kafka:7.6.0
                  depends_on:
                    - zookeeper
                  ports:
                    - "9092:9092"
                  environment:
                    KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
                    KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://$${EC2_PUBLIC_IP}:9092
                    KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
                schema-registry:
                  image: confluentinc/cp-schema-registry:7.6.0
                  depends_on:
                    - kafka
                  ports:
                    - "8081:8081"
                  environment:
                    SCHEMA_REGISTRY_KAFKASTORE_BOOTSTRAP_SERVERS: PLAINTEXT://$${EC2_PUBLIC_IP}:9092
                    SCHEMA_REGISTRY_LISTENERS: http://0.0.0.0:8081
                    SCHEMA_REGISTRY_HOST_NAME: 0.0.0.0
              EOT
              
              # Set correct ownership for the compose file
              chown ec2-user:ec2-user /home/ec2-user/compose.yml

              # Run Docker Compose 
              sudo docker compose -f /home/ec2-user/compose.yml up -d

              EOF
    tags = {
    Name = "Schema_Registry_EC2"
    }
}
