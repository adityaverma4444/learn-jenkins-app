# ============================================================
# CUSTOM DOCKERFILE FOR JENKINS PIPELINE
# ============================================================
# This creates a custom Docker image called "my-playwright"
# Based on: Microsoft's Playwright image (has browsers pre-installed)
# Adds: netlify-cli, node-jq, serve (tools we need for CI/CD)
# ============================================================
# WHY?
# Instead of running "npm install netlify-cli serve" in EVERY stage,
# we install them ONCE in this image = FASTER pipeline!
# ============================================================

FROM mcr.microsoft.com/playwright:v1.39.0-jammy

# Install global tools:
# - netlify-cli: Deploy to Netlify from command line
# - node-jq: Parse JSON files (extracts staging URL after deploy)
# - serve: Simple static file server (serves our React build locally)
RUN npm install -g netlify-cli node-jq serve
