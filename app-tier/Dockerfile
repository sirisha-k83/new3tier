FROM node:NodeJS 22.0.0 

WORKDIR /app

# Install dependencies
COPY package*.json ./  # this folder only has package.json files
RUN npm ci  # or `npm install`

# Copy source code
COPY . .

# (optional) Build if needed (e.g., Next.js)
RUN npm run build

# Expose port
EXPOSE 3000

# Run the app
CMD ["npm", "start"]
