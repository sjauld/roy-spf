# AGENTS.md

## Overview

Go AWS Lambda project (phishing simulation framework). Two lambda binaries (`sender`, `tracker`) plus shared packages, with Terraform infrastructure in `infra/`.

## Build

```sh
./build.sh          # builds and zips both lambdas (sender.zip, tracker.zip)
```

The build script runs `go build` from the repo root targeting `./src/sender/.` and `./src/tracker/.`. Binaries and zips are gitignored.

## Test

```sh
go test ./...
```

Tests exist only in `src/crypto/` and `src/mailer/`. No test runner config beyond standard `go test`.

## Project structure

- `src/sender/` — Lambda: sends phishing emails via Postmark (invoked directly via `aws lambda invoke`)
- `src/tracker/` — Lambda: API Gateway handler that catches victim clicks, decrypts identity, sends alert email
- `src/crypto/` — Shared encrypt/decrypt helpers used by both lambdas
- `src/mailer/` — Postmark client wrapper with mock for testing
- `src/helpers/` — SSM parameter fetching, Lambda response helpers, env loading
- `infra/` — Terraform module (AWS resources: Lambda, API Gateway, Route53, IAM, SSM)
- `infra/example/` — Example Terraform consumer of the module

## Conventions

- Go 1.16, no linter or formatter config — use standard `gofmt`
- Each lambda is a separate `package main` under `src/`; shared code uses the module path `github.com/sjauld/roy-spf/src/...`
- Environment variables are loaded in `env.go` `init()` functions within each lambda package
- Secrets (Postmark API tokens) are stored in AWS SSM Parameter Store, not in code
- No CI workflows in the repo
