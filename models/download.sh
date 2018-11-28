#!/bin/bash -x

mkdir -p model
cd model
wget -nc http://data.statmt.org/romang/gec-naacl18/models.tgz
tar zxvf models.tgz
cd ..
