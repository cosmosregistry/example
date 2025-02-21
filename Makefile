#!/usr/bin/make -f

#################
###   Build   ###
#################

test:
	@echo "--> Running tests"
	go test -v ./...

test-integration:
	@echo "--> Running integration tests"
	cd integration; go test -v ./...

.PHONY: test test-integration

##################
###  Protobuf  ###
##################

GOLANG_PROTOBUF_VERSION=1.28.1
GRPC_GATEWAY_VERSION=1.16.0
GRPC_GATEWAY_PROTOC_GEN_OPENAPIV2_VERSION=2.20.0

proto-all: proto-deps proto-format proto-lint proto-gen

proto-deps:
	@echo "Installing proto deps"
	@go install github.com/bufbuild/buf/cmd/buf@v1.50.0
	@go install github.com/cosmos/gogoproto/protoc-gen-gogo@latest
	@go install github.com/cosmos/cosmos-proto/cmd/protoc-gen-go-pulsar@latest
	@go install google.golang.org/protobuf/cmd/protoc-gen-go@v$(GOLANG_PROTOBUF_VERSION)
	@go install github.com/grpc-ecosystem/grpc-gateway/protoc-gen-grpc-gateway@v$(GRPC_GATEWAY_VERSION)
	@go install github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-openapiv2@v$(GRPC_GATEWAY_PROTOC_GEN_OPENAPIV2_VERSION)
	@go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest

proto-gen: proto-deps
	@echo "Generating protobuf files..."
	@sh ./scripts/protocgen.sh
	@go mod tidy

proto-format: proto-deps
	@find ./ -name "*.proto" -exec clang-format -i {} \;

proto-lint: proto-deps
	@buf lint proto/ --error-format=json

.PHONY: proto-all proto-gen proto-format proto-lint proto-deps

#################
###  Linting  ###
#################

golangci_lint_cmd=golangci-lint
golangci_version=v1.64.5

lint:
	@echo "--> Running linter"
	@go install github.com/golangci/golangci-lint/cmd/golangci-lint@$(golangci_version)
	@$(golangci_lint_cmd) run ./... --timeout 15m

lint-fix:
	@echo "--> Running linter and fixing issues"
	@go install github.com/golangci/golangci-lint/cmd/golangci-lint@$(golangci_version)
	@$(golangci_lint_cmd) run ./... --fix --timeout 15m

.PHONY: lint lint-fix