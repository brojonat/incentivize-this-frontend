# Use a lightweight nginx image
FROM nginx:stable-alpine

# Remove default nginx website
RUN rm -rf /usr/share/nginx/html/*

# Copy the built Flutter web app files from the build context
# Assumes you run the docker build command from the workspace root
COPY app/build/web /usr/share/nginx/html

# Expose port 80
EXPOSE 80

# Start nginx when the container launches
CMD ["nginx", "-g", "daemon off;"]
