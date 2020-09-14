all: refresh-images

refresh-images:
	./src/build_from_template.py

.PHONY: all refresh-images
