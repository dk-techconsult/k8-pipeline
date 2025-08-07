# Use a lightweight web server (nginx) to serve static files, assuming basic static site
FROM nginx:alpine

# Copy your app’s files to nginx html directory
COPY . /usr/share/nginx/html

# Expose port 80
EXPOSE 80

# Nginx starts by default, no CMD needed
