FROM nginx:alpine

# Copy custom index.html
COPY index.html /usr/share/nginx/html/index.html

# Copy custom nginx configuration if needed
# COPY nginx.conf /etc/nginx/nginx.conf

# Expose port 80
EXPOSE 80

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]
