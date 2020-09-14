Docker images for hybris-mobian [![Build Status](https://travis-ci.com/hybris-mobian-releng/docker-images.svg?branch=master)](https://travis-ci.com/hybris-mobian-releng/docker-images)
==================================

This repository contains the required source files to build Docker images
for various release engineering tasks (package building, hardware adaptation building, rootfs building, etc...).

These are built in Travis CI and, for the 'master' branch, the build artifacts are pushed automatically
into Docker Hub, at the [hybrismobian organization](https://hub.docker.com/orgs/hybrismobian/repositories).

Currently built images
----------------------

* build-essential (amd64 and arm64)

Adding a new image template
---------------------------

Image templates must be stored in the root directory of this repository, and must be named as `Dockerfile.@template@.in`,
where `@template@` is the template name.

The following strings are replaced:

| String            | Description                            | Example (for `arm64/hybrismobian/build-essential:bullseye`) |
|-------------------|----------------------------------------|-------------------------------------------------------------|
| `%(target_name)s` | Sanitized slug of the full target name | `arm64_hybrismobian_build_essential_bullseye`               |
| `%(arch)s`        | Architecture                           | `arm64`                                                     |
| `%(namespace)s`   | Docker namespace                       | `hybrismobian`                                              |
| `%(template)s`    | Template name                          | `build-essential`                                           |
| `%(tag)s`         | Image tag                              | `bullseye`                                                  |

Once a template has been made, you must add the desired docker images ("full target name") to the build matrix into the
`.travis.yml` file:

	  # AMD64 (x86_64) image containing toolchains and essential build
	  # tools
	  - name: amd64/hybrismobian/build-essential:bullseye
	    arch: amd64
	    <<: *docker_build_template
	  # ARM64 (AArch64) image containing toolchains and essential build
	  # tools
	  - name: arm64/hybrismobian/build-essential:bullseye
	    arch: arm64-graviton2
	    virt: vm # required to route the job to arm64-graviton2 
	    group: edge # required to route the job to arm64-graviton2
	    <<: *docker_build_template

In this example, the same template (`build-essential`) has now specified for both amd64 and arm64 builds.  
**Be extra sure to include the `<<: *docker_build_template` part!**

Once the build matrix has been updated, build the target Dockerfiles with

	make refresh-images

(a recent-ish python interpreter and `pyyaml` are required).
