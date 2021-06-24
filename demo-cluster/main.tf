
data "aws_iam_policy_document" "ecs-anywhere-task-assume-policy" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs-anywhere-test-task-role" {
  assume_role_policy = data.aws_iam_policy_document.ecs-anywhere-task-assume-policy.json
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",
  ]
  name_prefix = "ecs-anywhere-"
}

resource "aws_ecs_cluster" "ecs-anywhere-test" {
  name = "ecs-anywhere-test"
}

### Task definition, service, image pull

data "aws_ecr_image" "service_image" {
  repository_name = "flask-demo-app"
  image_tag       = "latest"
}


resource "aws_ecs_task_definition" "ecs-anywhere-test-task" {
  container_definitions = jsonencode(
    [
      {
        cpu       = 256
        essential = true
        image     = "596305347017.dkr.ecr.eu-central-1.amazonaws.com/flask-demo-app:latest"
        memory    = 256
        name      = "flask-demo-app"
        portMappings = [
          {
            containerPort = 5000
            hostPort      = 80
          },
        ]
      },
    ]
  )
  family                   = "test-task-def"
  requires_compatibilities = ["EXTERNAL", ]
  task_role_arn            = aws_iam_role.ecs-anywhere-test-task-role.arn
}

resource "aws_ecs_service" "flask-demo" {
  name            = "flask-demo"
  cluster         = "ecs-anywhere-test"
  task_definition = aws_ecs_task_definition.ecs-anywhere-test-task.arn
  desired_count   = 2
  launch_type     = "EXTERNAL"
}

######## "EXTERNAL" resources #########

data "aws_ami" "aws_ami_linux2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}
resource "aws_vpc" "ecs-anywhere-vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "ecs-anywhere-vpc"
  }
}

resource "aws_subnet" "public-anywhere-subnet" {
  vpc_id     = aws_vpc.ecs-anywhere-vpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "ecs-anywhere-public-subnet"
  }
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.ecs-anywhere-vpc.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.ecs-anywhere-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }
}

resource "aws_route_table_association" "route_table_association" {
  subnet_id      = aws_subnet.public-anywhere-subnet.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "external-resource-sg" {
  name        = "external_resource_sg"
  description = "Allow ssh access"
  vpc_id      = aws_vpc.ecs-anywhere-vpc.id

  ingress {
    description = "anywhere"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "external-resource-sg"
  }
}

resource "aws_iam_role" "instance_ssm_role" {
  name = "test_role"
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ]
  assume_role_policy = file("ssm_role.json")
}


resource "aws_ssm_activation" "activation" {
  name               = "instance_ssm_activation"
  description        = "SSM ECS Anywhere"
  iam_role           = aws_iam_role.instance_ssm_role.id
  registration_limit = var.worker
}

resource "aws_instance" "EXTERNAL-resource" {
  count                       = var.worker
  ami                         = data.aws_ami.aws_ami_linux2.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public-anywhere-subnet.id
  key_name                    = var.key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.external-resource-sg.id]
  user_data = templatefile("install-ecs-anywhere.sh.tpl", {
    TF_ACT_ID       = aws_ssm_activation.activation.id,
    TF_ACT_CODE     = aws_ssm_activation.activation.activation_code,
    TF_CLUSTER_NAME = aws_ecs_cluster.ecs-anywhere-test.id
  })

  root_block_device {
    volume_type = "gp3"
    volume_size = "8"
    encrypted   = true
  }

  tags = {
    Name = format("EXTERNAL-resource-%s", count.index)
  }

  lifecycle {
    ignore_changes = [
      ami
    ]
  }
}
