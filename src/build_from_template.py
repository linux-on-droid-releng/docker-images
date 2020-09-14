#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import yaml

import os

from collections import namedtuple

YAML_FILE = "./.travis.yml"
DOCKERFILE_PATH = "./Dockerfile.%s.in"
DOCKERFILE_TARGET = "./Dockerfile.%(target_name)s"

Target = namedtuple("Target", ["arch", "namespae", "template", "tag"])

if __name__ != "__main__":
	raise Exception("You shouldn't import this script")

if not os.path.exists(YAML_FILE):
	raise Exception("Unable to find %s" % YAML_FILE)

with open(YAML_FILE, "r") as f:
	content = yaml.load(f, Loader=yaml.FullLoader)

	templates_mapping = {}

	for job in content.get("jobs", {}).get("include", []):
		if job.get("stage", None) != "docker":
			continue

		target_name, arch, namespace, template, tag = [
			job["name"].replace("/", "_").replace(":", "_").replace(".", "_").replace("-","_"),
			*job["name"].replace(":", "/").split("/")
		]

		templates_mapping.setdefault(template, []).append(
			{
				"target_name" : target_name,
				"arch" : arch,
				"namespace" : namespace,
				"template" : template,
				"tag" : tag
			}
		)

	for template, targets in templates_mapping.items():
		# Load template
		with open(DOCKERFILE_PATH % template, "r") as t:
			template_content = t.read()

			for target in targets:
				with open(DOCKERFILE_TARGET % target, "w") as a:
					a.write(template_content % target)
