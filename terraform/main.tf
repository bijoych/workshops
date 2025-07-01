provider "aws" {
  region = "us-east-1"
}

resource "aws_key_pair" "kafka_key" {
  key_name   = "kafka-key"
  public_key = file("/Users/bijoychoudhury/.ssh/id_rsa.pub") # Path to your public SSH key
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

resource "aws_instance" "kafka_ec2" {
  ami                    = "ami-0c02fb55956c7d316" # Amazon Linux 2 AMI
  instance_type          = "t2.medium"
  key_name               = aws_key_pair.kafka_key.key_name
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
              EOF

  tags = {
    Name = "KafkaEC2"
  }
}
