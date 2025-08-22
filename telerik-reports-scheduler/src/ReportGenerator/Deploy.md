docker build --platform linux/amd64 -t telerik-report-generator . --provenance false

docker tag telerik-report-generator:latest 858946449855.dkr.ecr.us-east-1.amazonaws.com/telerik-report-generator-dev:latest

docker push 858946449855.dkr.ecr.us-east-1.amazonaws.com/telerik-report-generator-dev:latest