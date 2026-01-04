# Stage 1: Build
FROM node:22-alpine AS builder

WORKDIR /app

# Copier les fichiers de dépendances
COPY package*.json ./

# Installer les dépendances
RUN npm ci

# Copier le code source
COPY . .

# Argument de build pour la version (injecté depuis package.json)
ARG APP_VERSION
ENV VITE_APP_VERSION=${APP_VERSION}

# Build de l'application
RUN npm run build

# Stage 2: Production avec nginx
FROM nginx:alpine

# Copier le build depuis le stage précédent
COPY --from=builder /app/dist /usr/share/nginx/html

# Copier la configuration nginx
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Exposer le port 80
EXPOSE 80

# Démarrer nginx
CMD ["nginx", "-g", "daemon off;"]

