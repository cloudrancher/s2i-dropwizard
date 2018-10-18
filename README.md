
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

### Use the runtime image
Since one of the main points of Dropwizard is to provide a lean deployment, you probably don't want the image that comes out of the s2i process.  That image contains not only the Dropwizard fat jar, but also the entire maven jar cache.

To fix this, we will provide a different image for the runtime.
```
s2i build https://github.com/egeorge-nolab/dropwiz-hello egeorge/s2i-dropwizard-builder:latest dropwiz-hello:latest --runtime-image egeorge/dropwizard-runtime:latest -a /opt/app-root/src/target/dropwiz-hello-0.0.1-SNAPSHOT.jar -a /opt/app-root/src/dropwiz-hello.yaml -a /opt/app-root/src/config.yml
```
There is a lot in that long command, but the main additions are specifying the runtime image with this parameter ```--runtime-image egeorge/dropwizard-runtime``` and adding a ```-a``` parameter for each artifact we want included in the runtime image.

(**Note**: This is a little bit clumsy because we have to know the exact name of the jar ahead of time.  This is a limitation of the runtime image functionality in s2i. Going forward, OpenShift recommends using [Build Chaing](https://docs.openshift.com/container-platform/latest/dev_guide/builds/advanced_build_operations.html#dev-guide-chaining-builds) instead)

## OpenShift Usage
If you are running OpenShift, you do not need to use the ```s2i``` tool directly. You can create a BuildConfig in your project and run your build there.

There is an OpenShift build template included in the ```openshift/templates``` directory.  To create a new OpenShift build for your project, use this command.

(**Note**: There are two *required* parameters: the APP_NAME and the GIT_REPO)
```
oc process -f openshift/templates/dropwizard-build-template.yaml -p APP_NAME=dropwiz-hello GIT_REPO=https://github.com/egeorge-nolab/dropwiz-hello | oc create -f -
```
After the build exists, you can run it using:
```
oc start-build --follow dropwiz-hello
```
If the build is successful, you should see a new image in the imagestream.
```
$ oc get istag
~/work/cloudrancher/s2i-dropwizard 🍌 oc get istag
NAME                            DOCKER REF                                                                                                                     UPDATED
dropwiz-hello:latest            172.30.1.1:5000/dropwiz-hello/dropwiz-hello@sha256:5d1f2c5a95cb0765d6b219748fb7c1a598933e04f0245ba2e59f36a9b8db260f            A few seconds ago
$ _
```
With that, you can create a DeploymentConfig using the ```new-app``` command.
```
$ oc new-app --image-stream=dropwiz-hello
--> Found image 5ec79ec (About an hour old) in image stream "dropwiz-hello/dropwiz-hello" under tag "latest" for "dropwiz-hello"

    temp.builder.openshift.io/dropwiz-hello/dropwiz-hello-2:39953629
    ----------------------------------------------------------------
    Platform for building Dropwizard apps

    Tags: builder, dropwizard

    * This image will be deployed in deployment config "dropwiz-hello"
    * Port 8080/tcp will be load balanced by service "dropwiz-hello"
      * Other containers can access this service through the hostname "dropwiz-hello"

--> Creating resources ...
    deploymentconfig "dropwiz-hello" created
    service "dropwiz-hello" created
--> Success
    Application is not exposed. You can expose services to the outside world by executing one or more of the commands below:
     'oc expose svc/dropwiz-hello'
    Run 'oc status' to view your app.
$ _
```
And then expose it with a route, and find out what hostname has been assigned.
```
$ oc expose service dropwiz-hello --port=8080
route "dropwiz-hello" exposed
$ oc get route dropwiz-hello
NAME            HOST/PORT                                          PATH      SERVICES        PORT      TERMINATION   WILDCARD
dropwiz-hello   dropwiz-hello-dropwiz-hello.192.168.64.18.nip.io             dropwiz-hello   8080                    None
$ _
```
Your new, running service can now be tested:
```
$ curl http://dropwiz-hello-dropwiz-hello.192.168.64.18.nip.io/hello-world
{"id":2,"content":"Good Day, Eric!"}
$ _
```

## Environment Variables
Regardless of which context in which this builder is used, There are some environment variables you can override.

| Variable    |                                         | Default | Overridable |
| ----------- | --------------------------------------- | ------- | ----------- |
| DEPLOY_DIR  | The deploy location for the jar and config files | /opt/app-root/dist | false |
| DW_ACT      | The Dropwizard action (server or check) | server  | build or runtime |
| DW_CONFIG   | The location of the config file         | ${DEPLOY_DIR}/config.yml | build or runtime |
| JAR_NAME    | The name of the jarfile                 | maven artifact name | build or runtime |
| JAVA_OPTS   | Java Flags (-D) to pass to maven or the app | empty | build or runtime |

## Building these images
You may not want or be able to use the [builder images on DockerHub](https://hub.docker.com/r/egeorge/s2i-dropwizard-builder/), or you may want to customize these images in some way.  If so, then you can create the builder image locally with these steps.

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
