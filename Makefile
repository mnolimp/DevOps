IMAGE_NAME := quotes-scrapper
IMAGE_TAG  := latest
OUT_DIR    := out
SUDO 	   :=

.PHONY: build run clean ci

build:
	$(SUDO) docker build -t $(IMAGE_NAME):$(IMAGE_TAG) .

run:
	mkdir -p $(OUT_DIR)
	$(SUDO) docker run --rm -v "$(PWD)/$(OUT_DIR):/app/out" $(IMAGE_NAME):$(IMAGE_TAG)

clean:
	-$(SUDO) docker rmi -f $(IMAGE_NAME):$(IMAGE_TAG)
	rm -rf $(OUT_DIR)
	git status --short

ci: build run
	@test -s $(OUT_DIR)/result.json || (echo "result.json empty or missing" && exit 1)
	@node -e "JSON.parse(require('fs').readFileSync('$(OUT_DIR)/result.json')); console.log('JSON valid')" 2>/dev/null || (echo "result.json is not valid JSON" && exit 1)
	@echo "CI passed"