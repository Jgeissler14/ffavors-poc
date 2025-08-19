#!/bin/bash

BUCKET_NAME="telerik-reports-poc-bucket-dev"
REGION="us-east-1"

echo "Emptying S3 bucket: $BUCKET_NAME"

# Create temporary files for processing
VERSIONS_FILE=$(mktemp)
DELETE_MARKERS_FILE=$(mktemp)

# Get all versions and delete markers
aws s3api list-object-versions --bucket "$BUCKET_NAME" --region "$REGION" > /tmp/bucket_contents.json

# Extract versions
jq -r '.Versions[]? | "\(.Key)\t\(.VersionId)"' /tmp/bucket_contents.json > "$VERSIONS_FILE"

# Extract delete markers  
jq -r '.DeleteMarkers[]? | "\(.Key)\t\(.VersionId)"' /tmp/bucket_contents.json > "$DELETE_MARKERS_FILE"

# Delete versions
echo "Deleting object versions..."
while IFS=$'\t' read -r key version_id; do
    if [ -n "$key" ] && [ -n "$version_id" ]; then
        echo "Deleting version: $key ($version_id)"
        aws s3api delete-object --bucket "$BUCKET_NAME" --region "$REGION" --key "$key" --version-id "$version_id"
    fi
done < "$VERSIONS_FILE"

# Delete delete markers
echo "Deleting delete markers..."
while IFS=$'\t' read -r key version_id; do
    if [ -n "$key" ] && [ -n "$version_id" ]; then
        echo "Deleting delete marker: $key ($version_id)"
        aws s3api delete-object --bucket "$BUCKET_NAME" --region "$REGION" --key "$key" --version-id "$version_id"
    fi
done < "$DELETE_MARKERS_FILE"

# Clean up temporary files
rm -f "$VERSIONS_FILE" "$DELETE_MARKERS_FILE" /tmp/bucket_contents.json

echo "Bucket emptied successfully!"
