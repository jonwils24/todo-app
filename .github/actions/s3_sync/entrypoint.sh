#!/bin/bash

set -e

aws s3 sync --acl public-read site s3://$BUCKET_NAME --delete
aws cloudfront create-invalidation --distribution-id $DISTRIBUTION_ID --paths "/*"
