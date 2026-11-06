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
	@echo "Sending message to SQS..."
	AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=us-east-1 \
	aws --endpoint-url=http://localhost:4566 sqs send-message \
		--queue-url http://localhost:4566/000000000000/scraper-jobs \
		--message-body '{"task":"scrape"}'
	@echo "Running scraper..."
	$(DOCKER) run --rm \
		--add-host=host.docker.internal:host-gateway \
		-e AWS_ENDPOINT_URL=http://host.docker.internal:4566 \
		-e AWS_REGION=us-east-1 \
		-e AWS_ACCESS_KEY_ID=test \
		-e AWS_SECRET_ACCESS_KEY=test \
		-e SQS_QUEUE_URL=http://host.docker.internal:4566/000000000000/scraper-jobs \
		-e S3_BUCKET_NAME=scraper-results \
		$(IMAGE_NAME):$(IMAGE_TAG)

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