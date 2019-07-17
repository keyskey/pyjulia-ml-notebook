#!/bin/bash

docker run \
  --rm \
  -p 8888:8888 \
  -e JUPYTER_ENABLE_LAB=yes \
  -e TZ=Asia/Tokyo \
  -v `pwd`:/home/jovyan/work \
  jupyter/pyjulia-ml-notebook:latest
