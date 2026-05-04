#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

usage() {
  cat <<'USAGE'
Usage:
  scripts/bump-version.sh <major|minor|patch>
USAGE
}

die() {
  echo "$*" >&2
  exit 1
}

assert_clean_worktree() {
  if [[ -n "$(git -C "${ROOT_DIR}" status --porcelain)" ]]; then
    die "Working tree is not clean. Commit or stash changes first."
  fi
}

require_command() {
  local cmd="${1:-}"
  command -v "${cmd}" >/dev/null 2>&1 || die "Required command not found: ${cmd}"
}

main() {
  if [[ "$#" -ne 1 ]]; then
    usage
    exit 1
  fi

  local bump_type="${1}"
  case "${bump_type}" in
    major|minor|patch)
      ;;
    *)
      usage
      exit 1
      ;;
  esac

  require_command git
  require_command gh

  assert_clean_worktree

  local current_branch
  current_branch="$(git -C "${ROOT_DIR}" branch --show-current)"
  if [[ "${current_branch}" != "main" ]]; then
    die "Run this script on main branch. Current branch: ${current_branch}"
  fi

  local next_version
  next_version="$("${SCRIPT_DIR}/version.sh" next "${bump_type}")"

  "${SCRIPT_DIR}/version.sh" write "${next_version}"
  "${SCRIPT_DIR}/version.sh" sync-swift "${next_version}"
  "${SCRIPT_DIR}/version.sh" assert-consistent

  local branch_name
  branch_name="release/v${next_version}"

  if git -C "${ROOT_DIR}" show-ref --verify --quiet "refs/heads/${branch_name}"; then
    die "Branch already exists locally: ${branch_name}"
  fi

  git -C "${ROOT_DIR}" switch -c "${branch_name}"

  git -C "${ROOT_DIR}" add VERSION
  git -C "${ROOT_DIR}" add Sources/pbshow/Version.swift
  git -C "${ROOT_DIR}" commit -m "chore: bump version to v${next_version}"
  git -C "${ROOT_DIR}" push -u origin "${branch_name}"

  gh pr create \
    --base main \
    --head "${branch_name}" \
    --title "chore: bump version to v${next_version}" \
    --body "## Summary
- bump version to v${next_version}
- sync VERSION and PBShowVersion.current

## Verification
- ./scripts/version.sh assert-consistent"
}

main "$@"
