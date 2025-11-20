FROM node:22-alpine
WORKDIR /app
# Install dependencies
COPY package.json ./
RUN npm ci  # or `npm install`

# Copy source code
COPY . .

# (optional) Build if needed (e.g., Next.js)
RUN npm run build

# Expose port
EXPOSE 3000

# Run the app
CMD ["npm", "start"]
