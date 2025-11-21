FROM sirishak83/web-tier:latest AS build-stage

# --- STAGE 2: Serve Static Files with NGINX ---
FROM nginx:latest

# REMOVE the default config so it does NOT conflict
RUN rm -f /etc/nginx/conf.d/default.conf

# Copy your custom nginx.conf
COPY nginx.conf /etc/nginx/nginx.conf

# Copy React build files
COPY --from=build-stage /app/build /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
