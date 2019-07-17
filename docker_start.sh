#!/bin/bash

# Overall Ref: https://qiita.com/succi0303/items/c74a969d0bda36df18de
# Jupyter Docker Stacks official: https://jupyter-docker-stacks.readthedocs.io/en/latest/
# build command: docker build -t jupyter/pyjulia-ml-notebook ./

docker run \
  --rm \
  -p 8888:8888 \
  -e JUPYTER_ENABLE_LAB=yes \
  -e TZ=Asia/Tokyo \
  -v `pwd`:/home/jovyan/work \
  jupyter/pyjulia-ml-notebook:latest
