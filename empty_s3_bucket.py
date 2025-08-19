#!/usr/bin/env python3
import boto3
import json

def empty_versioned_bucket(bucket_name, region='us-east-1'):
    s3 = boto3.client('s3', region_name=region)
    
    print(f"Emptying versioned bucket: {bucket_name}")
    
    # Get all object versions and delete markers
    paginator = s3.get_paginator('list_object_versions')
    pages = paginator.paginate(Bucket=bucket_name)
    
    delete_requests = []
    
    for page in pages:
        # Process object versions
        if 'Versions' in page:
            for version in page['Versions']:
                delete_requests.append({
                    'Key': version['Key'],
                    'VersionId': version['VersionId']
                })
        
        # Process delete markers
        if 'DeleteMarkers' in page:
            for marker in page['DeleteMarkers']:
                delete_requests.append({
                    'Key': marker['Key'],
                    'VersionId': marker['VersionId']
                })
    
    print(f"Found {len(delete_requests)} objects/markers to delete")
    
    # Delete in batches of 1000 (AWS limit)
    batch_size = 1000
    for i in range(0, len(delete_requests), batch_size):
        batch = delete_requests[i:i + batch_size]
        
        if batch:
            print(f"Deleting batch {i//batch_size + 1}: {len(batch)} items")
            response = s3.delete_objects(
                Bucket=bucket_name,
                Delete={
                    'Objects': batch,
                    'Quiet': False
                }
            )
            
            if 'Errors' in response and response['Errors']:
                print(f"Errors occurred: {response['Errors']}")
            else:
                print(f"Successfully deleted {len(batch)} items")
    
    print("Bucket emptied successfully!")

if __name__ == "__main__":
    empty_versioned_bucket("telerik-reports-poc-bucket-dev")
