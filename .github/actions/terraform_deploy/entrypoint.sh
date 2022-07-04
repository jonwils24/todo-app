#!/bin/bash

set -e

cd terraform/
terraform init -input=false
terraform apply -input=false -auto-approve
BUCKET=$(terraform output website_bucket_name)
DISTRIBUTION_ID=$(terraform output cloudfront_id)
echo "::set-output name=BUCKET::${BUCKET}"
echo "::set-output name=DISTRIBUTION_ID::${DISTRIBUTION_ID}"
