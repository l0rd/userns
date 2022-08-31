#!/bin/bash

set -eof

docker build -t $1 .
docker push $1 
