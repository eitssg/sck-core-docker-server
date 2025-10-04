# Copilot Instructions (Submodule: sck-core-docker-server)

## Plan → Approval → Execute (Mandatory)
Dockerfile or compose changes, server code edits, or security hardening steps must be planned and approved prior to execution.

- Tech: Docker server images.
- Precedence: Local first; then root `../../.github/...`.
- Conventions: Multi-stage builds, minimal images, healthchecks and sensible defaults.

## Contradiction Detection
- Cross-check against base image and server hardening guidelines.
- If conflict, warn + options + example.
- Example: "Running as root conflicts with hardening; use non-root user and least privilege."

## Standalone clone note
If cloned standalone, see:
- Root Copilot guidance: https://github.com/eitssg/simple-cloud-kit/blob/develop/.github/copilot-instructions.md
 
