IMAGE_NAME := quotes-scrapper
IMAGE_TAG  := latest
OUT_DIR    := out

.PHONY: build run clean ci

build:
	docker build -t $(IMAGE_NAME):$(IMAGE_TAG) .

run:
	mkdir -p $(OUT_DIR)
	docker run --rm -v "$(PWD)/$(OUT_DIR):/app/out" $(IMAGE_NAME):$(IMAGE_TAG)

clean:
	-docker rmi -f $(IMAGE_NAME):$(IMAGE_TAG)
	rm -rf $(OUT_DIR)
	git status --short

ci: build run
	@echo "CI passed"