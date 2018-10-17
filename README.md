
# Dropwizard fat-jar S2I builder and runtime
This repository contains Dockerfiles and [Source to Image](https://github.com/openshift/source-to-image) scripts for building self-contained docker images to run Dropwizard fat-jars.  If you are not familiar with Source to Image (s2i), you can read more in the OpenShift documentation [Builds and Image Stream](https://docs.okd.io/latest/architecture/core_concepts/builds_and_image_streams.html#source-build).

We will use a simple Dropwizard [hello world web app](https://github.com/egeorge-nolab/dropwiz-hello) as an example throughout.

## Plain Docker Usage
If you have the s2i tool installed, you can build a runnable image from the command line.  
```
s2i build https://github.com/egeorge-nolab/dropwiz-hello egeorge/s2i-dropwizard-builder:latest dropwiz-hello:latest
```
At the conclusion of this, you will have a runnable image at the tag ```dropwiz-hello:latest```.  To run it:
```
docker run -it --rm -p 8080:8080 dropwiz-hello:latest
```

### Create runtime image
Since one of the main points of Dropwizard is to provide a lean deployment, you probably don't want the image that comes out of the s2i process.  That image contains not only the Dropwizard fat jar, but also the entire maven jar cache.

To fix this, we will provide a different image for the runtime.
```
s2i build https://github.com/egeorge-nolab/dropwiz-hello egeorge/s2i-dropwizard-builder:latest dropwiz-hello:latest --runtime-image egeorge/dropwizard-runtime:latest -a /opt/app-root/src/target/dropwiz-hello-0.0.1-SNAPSHOT.jar -a /opt/app-root/src/dropwiz-hello.yaml -a /opt/app-root/src/config.yml
```
There is a lot in that long command, but the main additions are specifying the runtime image ```--runtime-image egeorge/dropwizard-runtime``` and adding a ```-a``` parameter for each artifact we want included in the runtime image.

(**Note***: This is a little bit clumsy because we have to know the exact name of the jar ahead of time.  This is a limitation of the runtime image functionality in s2i. Going forward, OpenShift recommends using [Build Chaing](https://docs.openshift.com/container-platform/latest/dev_guide/builds/advanced_build_operations.html#dev-guide-chaining-builds) instead)

## OpenShift Usage

## Environment Variables

## Building these images
You may not want or be able to use the [builder images on DockerHub](https://hub.docker.com/r/egeorge/s2i-dropwizard-builder/). Or you may want to customize this image in some way.  If so, then you can create the builder image locally with these steps.

First, clone this repository.
### Docker

Build the builder image.
```
docker build -t s2i-dropwizard-builder:latest .
```
Build the runtime image.
```
docker build -t dropwizard-runtime:latest -f Dockerfile.runtime .
```
### OpenShift
There is an BuildConfig template included in the ```openshift/templates``` directory.  To use it for creating a new OpenShift build and ImageStream, use this command.
Build the builder image.
```
oc process -f openshift/templates/s2i-dropwizard-builder-template.yaml | oc create -f -
```
Build the runtime image.
```
oc process -f openshift/templates/dropwizard-runtime-template.yaml | oc create -f -
```
