#! /bin/bash

docker build --tag nexryai/astrust-repo-server:latest --file Dockerfile .
docker-compose up
