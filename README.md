# certbot-on-lambda

Create wildcard SSL certificate of your Route53 zone by Certbot on lambda.

## Steps

### 1. terraform apply (first)

Make a `terraform.tfvars` file based on the `variable.tf`.

```
$ cd infra
$ terraform init
$ terroform apply
```

Since the image has not been pushed yet, `apply` will error out.

### 2. Register image to ECR

Get certification for ECR and push the image to the repository.

[AWS documentation](https://docs.aws.amazon.com/AmazonECR/latest/userguide/docker-push-ecr-image.html) 

```
$ aws ecr get-login
$ docker login -u AWS ...
$ cd image
$ docker build -t [your repo]:latest .
$ docker push [your repo]:latest
```

### 3. terraform apply (second)
```
$ cd infra
$ terroform apply
```
