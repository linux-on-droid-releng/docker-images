#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import yaml

import os

import subprocess

YAML_FILE = "./.travis.yml"

if __name__ != "__main__":
	raise Exception("You shouldn't import this script")

if not os.path.exists(YAML_FILE):
	raise Exception("Unable to find %s" % YAML_FILE)

# Allow experimental commands on the environment
subprocess_env = {
	**{
		x:y
		for x,y in os.environ.items()
		if not x in [
			"DOCKER_USERNAME",
			"DOCKER_PASSWORD"
		]
	},
	**{
		"DOCKER_CLI_EXPERIMENTAL" : "enabled"
	}
}

with open(YAML_FILE, "r") as f:
	content = yaml.load(f, Loader=yaml.FullLoader)

	aliases_mapping = {}

	for job in content.get("jobs", {}).get("include", []):
		if job.get("stage", None) != "docker":
			continue

		target_name, arch, namespace, template, tag = [
			job["name"].replace("/", "_").replace(":", "_").replace(".", "_").replace("-","_"),
			*job["name"].replace(":", "/").split("/")
		]

		alias = "%s/%s:%s" % (namespace, template, tag)
		underlying_image = "%s-%s" % (alias, arch)
		aliases_mapping.setdefault(alias, []).append(underlying_image)

	# Login to docker
	subprocess.run(
		[
			"docker",
			"login",
			"-u",
			os.environ["DOCKER_USERNAME"],
			"--password-stdin",
			"quay.io"
		],
		input=os.environ["DOCKER_PASSWORD"],
		check=True,
		universal_newlines=True,
		env=subprocess_env
	)

	# Push manifests
	for alias, images in aliases_mapping.items():
		subprocess.run(
			[
				"docker",
				"manifest",
				"create",
				"--amend",
				alias,
				*images
			],
			check=True,
			env=subprocess_env
		)
		subprocess.run(
			[
				"docker",
				"manifest",
				"push",
				"--purge",
				"%s/%s" % ("quay.io", alias)
			],
			check=True,
			env=subprocess_env
		)
