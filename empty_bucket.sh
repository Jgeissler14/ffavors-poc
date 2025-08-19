#!/bin/bash

BUCKET_NAME="telerik-reports-poc-bucket-dev"
REGION="us-east-1"

echo "Emptying S3 bucket: $BUCKET_NAME"

# Delete all object versions
echo "Deleting object versions..."
aws s3api list-object-versions --bucket "$BUCKET_NAME" --region "$REGION" --query 'Versions[].{Key:Key,VersionId:VersionId}' --output json | \
jq -r '.[] | "--key \(.Key) --version-id \(.VersionId)"' | \
while read -r args; do
    if [ -n "$args" ]; then
        echo "Deleting version: $args"
        aws s3api delete-object --bucket "$BUCKET_NAME" --region "$REGION" $args
    fi
done

# Delete all delete markers
echo "Deleting delete markers..."
aws s3api list-object-versions --bucket "$BUCKET_NAME" --region "$REGION" --query 'DeleteMarkers[].{Key:Key,VersionId:VersionId}' --output json | \
jq -r '.[] | "--key \(.Key) --version-id \(.VersionId)"' | \
while read -r args; do
    if [ -n "$args" ]; then
        echo "Deleting delete marker: $args"
        aws s3api delete-object --bucket "$BUCKET_NAME" --region "$REGION" $args
    fi
done

echo "Bucket emptied successfully!"
