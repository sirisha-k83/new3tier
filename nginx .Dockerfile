FROM sirishak83/web-tier:latest AS build-stage

FROM nginx:latest

# The default config should be removed or overwritten to prevent conflicts.
# The `default.conf` file is what Nginx uses from the conf.d directory.
# Since you're using `rm -f /etc/nginx/conf.d/default.conf` below,
# you should copy your custom config there.

# Copy your custom nginx configuration to the expected conf.d directory
# and name it default.conf to replace the removed file.
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy static files (This step is correct)
COPY --from=build-stage /app/build /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
