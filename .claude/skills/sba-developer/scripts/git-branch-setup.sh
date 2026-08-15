#!/usr/bin/env bash
# =============================================================================
# git-branch-setup.sh
# Reusable branch setup script for skill workflows.
#
# USAGE:
#   ./git-branch-setup.sh <issue-key> [base-branch] [short-slug]
#
# ARGUMENTS:
#   issue-key     Required. Ticket/issue identifier, e.g. SCRUM-23
#   base-branch   Optional. Branch to base the feature off. Defaults to: main
#   short-slug    Optional. Short kebab-case label appended to branch name.
#                 e.g. "dark-mode-toggle" → feature/scrum-23-dark-mode-toggle
#
# EXAMPLES:
#   ./git-branch-setup.sh SCRUM-23
#   ./git-branch-setup.sh SCRUM-23 develop
#   ./git-branch-setup.sh SCRUM-23 develop dark-mode-toggle
#
# EXIT CODES:
#   0  Success — feature branch is checked out and ready
#   1  User input required — script stopped and printed a clear message
#   2  Git operation failed (fetch, pull, checkout)
# =============================================================================

set -euo pipefail

# ── Colour helpers ────────────────────────────────────────────────────────────
RED='\033[0;31m'
YEL='\033[1;33m'
GRN='\033[0;32m'
CYN='\033[0;36m'
BLD='\033[1m'
RST='\033[0m'

info()  { echo -e "${CYN}[INFO]${RST}  $*"; }
ok()    { echo -e "${GRN}[OK]${RST}    $*"; }
warn()  { echo -e "${YEL}[WARN]${RST}  $*"; }
error() { echo -e "${RED}[ERROR]${RST} $*" >&2; }
ask()   { echo -e "${BLD}[ACTION NEEDED]${RST} $*"; }

# ── Argument parsing ──────────────────────────────────────────────────────────
if [[ $# -lt 1 ]]; then
  error "Missing required argument: <issue-key>"
  echo ""
  echo "  Usage: $0 <issue-key> [base-branch] [short-slug]"
  echo "  Example: $0 SCRUM-23 develop dark-mode-toggle"
  exit 1
fi

ISSUE_KEY="${1}"
BASE_BRANCH="${2:-main}"
SHORT_SLUG="${3:-}"

# Normalise: lowercase issue key, build feature branch name
ISSUE_KEY_LOWER="$(echo "${ISSUE_KEY}" | tr '[:upper:]' '[:lower:]')"
if [[ -n "${SHORT_SLUG}" ]]; then
  FEATURE_BRANCH="feature/${ISSUE_KEY_LOWER}-${SHORT_SLUG}"
else
  FEATURE_BRANCH="feature/${ISSUE_KEY_LOWER}"
fi

echo ""
info "─────────────────────────────────────────────────"
info "  Issue key   : ${ISSUE_KEY}"
info "  Base branch : ${BASE_BRANCH}"
info "  Feature     : ${FEATURE_BRANCH}"
info "─────────────────────────────────────────────────"
echo ""

# ── Prerequisite: must be inside a git repo ───────────────────────────────────
if ! git rev-parse --git-dir > /dev/null 2>&1; then
  error "Not inside a git repository. cd into your project first."
  exit 2
fi

# ── Step 1: Check for uncommitted local changes ───────────────────────────────
info "Step 1/4 — Checking for uncommitted local changes..."

DIRTY="$(git status --porcelain)"
if [[ -n "${DIRTY}" ]]; then
  warn "Uncommitted changes detected in the working tree:"
  echo ""
  git status --short
  echo ""
  ask "These changes are unrelated to this story."
  ask "Please choose how to handle them, then re-run this script:"
  echo ""
  echo "  a) Stash them      →  git stash push -m 'WIP before ${FEATURE_BRANCH}'"
  echo "  b) Commit them     →  git add -A && git commit -m 'WIP: <your message>'"
  echo "  c) Discard them    →  git checkout -- .  (CAUTION: irreversible)"
  echo ""
  exit 1
fi

ok "Working tree is clean."

# ── Step 2: Fetch the base branch from origin ─────────────────────────────────
info "Step 2/4 — Fetching '${BASE_BRANCH}' from origin..."

if ! git fetch origin "${BASE_BRANCH}" 2>/dev/null; then
  error "Branch '${BASE_BRANCH}' does not exist on origin."
  echo ""
  ask "The base branch '${BASE_BRANCH}' was not found on the remote."
  ask "Please verify the branch name and push it to origin first, then re-run."
  echo ""
  echo "  Available remote branches:"
  git branch -r | sed 's|origin/||' | grep -v HEAD | sort | sed 's/^/    /'
  echo ""
  exit 1
fi

ok "Fetch complete."

# ── Step 3: Ensure base branch exists locally and is up-to-date ───────────────
info "Step 3/4 — Setting up local '${BASE_BRANCH}'..."

LOCAL_EXISTS="$(git branch --list "${BASE_BRANCH}")"

if [[ -z "${LOCAL_EXISTS}" ]]; then
  # No local ref — create one tracking origin
  info "  No local '${BASE_BRANCH}' found. Creating tracking branch..."
  git checkout -b "${BASE_BRANCH}" "origin/${BASE_BRANCH}"
  ok "  Created local '${BASE_BRANCH}' tracking origin/${BASE_BRANCH}."
else
  # Local ref exists — fast-forward it
  info "  Local '${BASE_BRANCH}' exists. Fast-forwarding from origin..."
  CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"

  if [[ "${CURRENT_BRANCH}" != "${BASE_BRANCH}" ]]; then
    git checkout "${BASE_BRANCH}"
  fi

  if ! git pull --ff-only origin "${BASE_BRANCH}"; then
    error "Fast-forward failed for '${BASE_BRANCH}'."
    echo ""
    ask "Your local '${BASE_BRANCH}' has diverged from origin/${BASE_BRANCH}."
    ask "Please resolve manually:"
    echo ""
    echo "  Option 1 (preferred): git reset --hard origin/${BASE_BRANCH}"
    echo "  Option 2:             git merge origin/${BASE_BRANCH}"
    echo ""
    exit 2
  fi

  ok "  '${BASE_BRANCH}' is up-to-date."
fi

# ── Step 4: Create the feature branch ─────────────────────────────────────────
info "Step 4/4 — Creating feature branch '${FEATURE_BRANCH}'..."

FEATURE_EXISTS="$(git branch --list "${FEATURE_BRANCH}")"

if [[ -n "${FEATURE_EXISTS}" ]]; then
  warn "Branch '${FEATURE_BRANCH}' already exists locally."
  echo ""
  ask "This may mean earlier work on this story is in progress."
  ask "Choose one of the following, then re-run or act manually:"
  echo ""
  echo "  a) Reuse it (resume earlier work):"
  echo "       git checkout ${FEATURE_BRANCH}"
  echo ""
  echo "  b) Pick a different name:"
  echo "       $0 ${ISSUE_KEY} ${BASE_BRANCH} <new-slug>"
  echo ""
  echo "  c) Delete and recreate (WARNING: loses existing commits on that branch):"
  echo "       git branch -D ${FEATURE_BRANCH}"
  echo "       $0 ${ISSUE_KEY} ${BASE_BRANCH} ${SHORT_SLUG:-}"
  echo ""
  exit 1
fi

git checkout -b "${FEATURE_BRANCH}" "${BASE_BRANCH}"

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
ok "═══════════════════════════════════════════════════"
ok "  Branch ready: ${FEATURE_BRANCH}"
ok "  Based on:     ${BASE_BRANCH} (origin synced)"
ok "═══════════════════════════════════════════════════"
echo ""
info "You are now on '${FEATURE_BRANCH}'. Start implementing."
echo ""/