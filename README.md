# tf-ecs-anywhere

This is an example project to show ECS Anywhere.
It creates an ECS Cluster, a task definition and service, EC2 instance I use to "mock" the external resources.

## Usage
- set up your own backend or keep it locally
- Docker image
  - use the files in the folder flask-demo-app to create your own test docker image and upload it to ECR
  - you will have to alter the data block searching for the Docker image saved in ECR

  or 

  - change the task definition for any other Docker image and pull from other registries
