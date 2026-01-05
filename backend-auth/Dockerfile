FROM node:18-alpine

WORKDIR /app

# Copier package.json et installer les dépendances
COPY package*.json ./
RUN npm install --production

# Copier le code
COPY server.js ./

# Créer le répertoire pour les secrets
RUN mkdir -p /app/secrets

# Exposer le port
EXPOSE 3001

# Démarrer l'application
CMD ["node", "server.js"]
