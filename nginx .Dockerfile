FROM sirishak83/web-tier:latest AS build-stage

# --- STAGE 2: Serve the Static Files with NGINX ---
FROM nginx:latest

# Copy your nginx config
COPY nginx.conf /etc/nginx/nginx.conf

# Copy the already-built React static files
COPY --from=build-stage /app/build /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
