# CONCEPT: multi-stage build
# Stage 1 (builder) — could compile assets if needed (e.g. npm run build for React)
# Stage 2 (runtime) — tiny final image with just Nginx + static files
# This keeps the image small: no build tools in production.

# ── Stage 1: builder ──────────────────────────────────────────────────────────
FROM node:20-alpine AS builder

WORKDIR /build

# For a plain static site there's nothing to compile,
# but this stage shows where you'd run: npm ci && npm run build
COPY . .

# ── Stage 2: runtime ──────────────────────────────────────────────────────────
FROM nginx:1.25-alpine

# Remove default Nginx page
RUN rm -rf /usr/share/nginx/html/*

# Copy static files from builder stage
COPY --from=builder /build /usr/share/nginx/html

# Custom Nginx config — serves static files with correct caching headers
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Nginx listens on 80
EXPOSE 80

# Run Nginx in foreground (required for containers — no systemd)
CMD ["nginx", "-g", "daemon off;"]
