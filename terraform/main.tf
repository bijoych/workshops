terraform {
  required_providers {
    tls = {
      source  = "hashicorp/tls"
      version = "4.0.5"
    }
    local = {
      source = "hashicorp/local"
      version = "2.5.1"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# Generate a new private key using the TLS provider
resource "tls_private_key" "rsa_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create the key pair in AWS using the public key from the generated key
resource "aws_key_pair" "generated_key" {
  key_name   = "my-tf-generated-key"
  public_key = tls_private_key.rsa_key.public_key_openssh
}

# Save the generated private key to a local file
resource "local_file" "private_key_pem" {
  content  = tls_private_key.rsa_key.private_key_pem
  filename = "${path.module}/my-tf-key.pem"
  file_permission = "0400" # Set correct permissions
}

resource "aws_security_group" "kafka_sg" {
  name        = "kafka-sg"
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

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
}

output "instance_public_ip" {
  description = "The public IP address of the EC2 instance."
  value       = aws_instance.kafka_ec2.public_ip
}

resource "aws_instance" "kafka_ec2" {
  ami                    = "ami-05ffe3c48a9991133" # Amazon Linux 2 AMI
  instance_type          = "t2.medium"
  key_name               = aws_key_pair.generated_key.key_name
  vpc_security_group_ids = [aws_security_group.kafka_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              wget https://corretto.aws/downloads/latest/amazon-corretto-17-x64-linux-jdk.rpm
              sudo yum localinstall -y amazon-corretto-17-x64-linux-jdk.rpm

              cd /opt
              curl -O https://downloads.apache.org/kafka/3.9.0/kafka_2.13-3.9.0.tgz
              tar -xzf kafka_2.13-3.9.0.tgz
              mv kafka_2.13-3.9.0 kafka

              # Update Kafka config
              sed -i 's|^log.dirs=.*|log.dirs=/tmp/kafka-logs|' /opt/kafka/config/server.properties
              sed -i 's|^#listeners=.*|listeners=PLAINTEXT://:9092|' /opt/kafka/config/server.properties
              sed -i "s|^#advertised.listeners=.*|advertised.listeners=PLAINTEXT://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):9092|" /opt/kafka/config/server.properties

              # Start Zookeeper
              nohup /opt/kafka/bin/zookeeper-server-start.sh /opt/kafka/config/zookeeper.properties > /tmp/zookeeper.log 2>&1 &

              # Give Zookeeper time to start
              sleep 10

              # Start Kafka
              nohup /opt/kafka/bin/kafka-server-start.sh /opt/kafka/config/server.properties > /tmp/kafka.log 2>&1 &

              # Set the PATH in .bash_profile file
              echo 'export PATH="$PATH:/opt/kafka/bin/"' >> /home/ec2-user/.bash_profile
              source /home/ec2-user/.bash_profile

              # Install Confluent CLI
              curl -sL --http1.1 https://cnfl.io/cli | sh -s --
              sudo mv ./bin/confluent /usr/local/bin/

              EOF

    tags = {
    Name = "Kafka_EC2"
    }
}
