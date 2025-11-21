FROM sirishak83/web-tier:latest AS build-stage

FROM nginx:latest

# REMOVE the default Nginx config so only your nginx.conf is used
RUN rm -f /etc/nginx/conf.d/default.conf

# Copy your custom nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Copy static files
COPY --from=build-stage /app/build /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
