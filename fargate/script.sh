#!/bin/bash

docker build -t mon-image-python .

aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 977173048896.dkr.ecr.us-east-1.amazonaws.com

aws ecr create-repository --repository-name my-repository --image-scanning-configuration scanOnPush=true --region us-east-1

docker tag mon-image-python:latest my-repository.dkr.ecr.us-east-1.amazonaws.com/mon-image-python:latest

docker push my-repository.dkr.ecr.us-east-1.amazonaws.com/mon-image-python:latest

docker logout my-repository.dkr.ecr.us-east-1.amazonaws.com
