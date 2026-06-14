#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
WORKFLOW="$ROOT_DIR/.github/workflows/docker-image.yml"
DOCKERIGNORE="$ROOT_DIR/.dockerignore"

require_file() {
    local path="$1"
    if [[ ! -f "$path" ]]; then
        echo "missing required file: ${path#$ROOT_DIR/}"
        exit 1
    fi
}

require_contains() {
    local path="$1"
    local pattern="$2"
    local description="$3"

    if ! grep -Fq "$pattern" "$path"; then
        echo "missing ${description}: ${pattern}"
        exit 1
    fi
}

require_file "$WORKFLOW"
require_file "$DOCKERIGNORE"

require_contains "$WORKFLOW" "packages: write" "GHCR package write permission"
require_contains "$WORKFLOW" "actions/setup-node@" "Node setup step"
require_contains "$WORKFLOW" "working-directory: web" "frontend working directory"
require_contains "$WORKFLOW" "npm ci" "frontend dependency install"
require_contains "$WORKFLOW" "npm run build" "frontend build"
require_contains "$WORKFLOW" "docker/setup-buildx-action@" "Docker Buildx setup"
require_contains "$WORKFLOW" "docker/login-action@" "GHCR login step"
require_contains "$WORKFLOW" "registry: ghcr.io" "GHCR registry"
require_contains "$WORKFLOW" "docker/metadata-action@" "Docker metadata step"
require_contains "$WORKFLOW" "docker/build-push-action@" "Docker build/push step"
require_contains "$WORKFLOW" "push: \${{ github.event_name != 'pull_request' }}" "PR build-only push guard"
require_contains "$WORKFLOW" "type=raw,value=latest,enable={{is_default_branch}}" "latest tag on default branch"
require_contains "$WORKFLOW" "type=ref,event=tag" "version tag metadata"
require_contains "$WORKFLOW" "type=sha,prefix=sha-" "sha tag metadata"

require_contains "$DOCKERIGNORE" ".git" "git metadata exclusion"
require_contains "$DOCKERIGNORE" "web/node_modules" "frontend dependency exclusion"
require_contains "$DOCKERIGNORE" "dist" "release artifact exclusion"

if command -v actionlint >/dev/null 2>&1; then
    actionlint "$WORKFLOW"
fi

echo "Docker workflow checks passed"
