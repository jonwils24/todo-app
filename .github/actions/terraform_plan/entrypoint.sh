#!/bin/bash

set -e

cd terraform/
terraform init -input=false
terraform plan -input=false