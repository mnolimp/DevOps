IMAGE_NAME := quotes-scrapper
IMAGE_TAG  := latest
OUT_DIR    := out
INFRA_DIR  := infra
DOCKER     := sudo docker
COMPOSE    := $(DOCKER) compose
TF         := terraform

.PHONY: build provision deploy run clean destroy ci

build:
	$(DOCKER) build -t $(IMAGE_NAME):$(IMAGE_TAG) .

run:
	mkdir -p $(OUT_DIR)
	$(DOCKER) run --rm -v "$(PWD)/$(OUT_DIR):/app/out" $(IMAGE_NAME):$(IMAGE_TAG)

provision:
	$(COMPOSE) up -d
	@echo "Waiting for Floci to become healthy..."
	@for i in $$(seq 1 30); do \
		if curl -sf http://localhost:4566/_localstack/health > /dev/null; then \
			echo "Floci is up"; break; \
		fi; \
		sleep 1; \
	done
	cd $(INFRA_DIR) && $(TF) init -input=false && $(TF) apply -auto-approve -input=false

destroy:
	cd $(INFRA_DIR) && $(TF) destroy -auto-approve -input=false
	$(COMPOSE) down

clean:
	-$(DOCKER) rmi -f $(IMAGE_NAME):$(IMAGE_TAG)
	rm -rf $(OUT_DIR)
	git status --short

ci: build run
	@test -s $(OUT_DIR)/result.json || (echo "result.json empty or missing" && exit 1)
	@node -e "JSON.parse(require('fs').readFileSync('$(OUT_DIR)/result.json')); console.log('JSON valid')" 2>/dev/null || (echo "result.json is not valid JSON" && exit 1)
	@echo "CI passed"