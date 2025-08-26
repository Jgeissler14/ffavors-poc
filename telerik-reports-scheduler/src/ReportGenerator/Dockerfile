# Stage 1: Build the application
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build-env
WORKDIR /app

# Copy the local NuGet packages into the Docker image
# Assuming the .nupkg files are in a 'nuget' subdirectory relative to the Dockerfile
COPY "nuget/packages/Telerik_Reporting_19.2.25.813_NuGet/" "./nuget_packages/"

# Create a nuget.config file inside the Docker image to point to the local packages
RUN cat <<EOF > NuGet.config
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <packageSources>
    <clear />
    <add key="nuget.org" value="https://api.nuget.org/v3/index.json" />
    <add key="telerik-local" value="./nuget_packages" />
  </packageSources>
</configuration>
EOF

# Copy csproj and restore as distinct layers
COPY "ReportGenerator.csproj" "ReportGenerator.csproj"
RUN dotnet restore --configfile NuGet.config

# Copy everything else and build
COPY . .
# Specify the runtime identifier for publishing
RUN dotnet publish -c Release -o out --runtime linux-x64 --self-contained false

# Stage 2: Create the final runtime image
FROM public.ecr.aws/lambda/dotnet:8
WORKDIR /var/task

# Copy the published output from the build stage
COPY --from=build-env /app/out .

# Install system dependencies for SkiaSharp
# These commands are for Amazon Linux 2 based images
RUN dnf update -y && \
    dnf install -y fontconfig freetype urw-base35-fonts-legacy

# Create a writable font cache directory
RUN mkdir -p /tmp/font-cache && chmod 777 /tmp/font-cache
ENV XDG_CACHE_HOME=/tmp/font-cache


# Set the entrypoint for the Lambda function
CMD ["ReportGenerator::ReportGenerator.SqsFunction::FunctionHandler"]