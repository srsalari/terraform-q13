# main.tf

resource "aws_kms_key" "exam_key" {
  description             = "KMS key for S3 bucket encryption"
  deletion_window_in_days = 10
}

output "kms_arn" {
  value = aws_kms_key.exam_key.arn
}

resource "random_id" "bucket_id" {
  byte_length = 8
}

resource "aws_s3_bucket" "exam_bucket" {
  bucket = "exam-bucket-${random_id.bucket_id.hex}"
  acl    = "private"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = "aws:kms"
        kms_master_key_id = aws_kms_key.exam_key.arn
      }
    }
  }

  versioning {
    enabled = true
  }
}

resource "aws_vpc" "exam_vpc" {
  cidr_block = var.vpc_cidr
}

resource "aws_internet_gateway" "exam_igw" {
  vpc_id = aws_vpc.exam_vpc.id
}

resource "aws_route_table" "exam_route_table" {
  vpc_id = aws_vpc.exam_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.exam_igw.id
  }
}

resource "aws_subnet" "exam_subnet" {
  vpc_id     = aws_vpc.exam_vpc.id
  cidr_block = var.subnet_cidr
}

resource "aws_route_table_association" "exam_rta" {
  subnet_id      = aws_subnet.exam_subnet.id
  route_table_id = aws_route_table.exam_route_table.id
}

resource "aws_security_group" "exam_sg" {
  name        = "exam-sg"
  description = "Security group for exam EC2 instance"
  vpc_id      = aws_vpc.exam_vpc.id

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

resource "aws_instance" "exam_ec2" {
  ami             = "ami-0d9236b8cf2c8fb6c"
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.exam_subnet.id
  security_groups = [aws_security_group.exam_sg.id]

  tags = {
    Name = "exam-ec2"
  }
}

output "ec2_public_ip" {
  value = aws_instance.exam_ec2.public_ip
}
