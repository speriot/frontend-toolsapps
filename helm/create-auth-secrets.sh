#!/bin/bash

# Script pour créer et gérer les secrets utilisateurs dans Kubernetes

# Namespace par défaut
NAMESPACE="${1:-default}"

echo "🔐 Création des secrets utilisateurs pour ToolsApps"
echo "📦 Namespace: $NAMESPACE"
echo ""

# Fonction pour générer un hash de mot de passe
# Nécessite Node.js installé
generate_password_hash() {
    local password="$1"
    node -e "const bcrypt = require('bcryptjs'); bcrypt.hash('$password', 10, (err, hash) => { if(err) { console.error(err); process.exit(1); } console.log(hash); });"
}

# Créer le fichier users.json
echo "📝 Création du fichier users.json..."

# Demander les informations pour l'utilisateur admin
read -p "Email admin (défaut: admin@toolsapps.eu): " ADMIN_EMAIL
ADMIN_EMAIL=${ADMIN_EMAIL:-admin@toolsapps.eu}

read -sp "Mot de passe admin (défaut: admin123): " ADMIN_PASSWORD
echo
ADMIN_PASSWORD=${ADMIN_PASSWORD:-admin123}

read -p "Nom admin (défaut: Admin): " ADMIN_NAME
ADMIN_NAME=${ADMIN_NAME:-Admin}

# Générer le hash du mot de passe
echo "🔄 Génération du hash de mot de passe..."
ADMIN_HASH=$(generate_password_hash "$ADMIN_PASSWORD")

# Créer le fichier JSON
cat > users.json << EOF
[
  {
    "email": "$ADMIN_EMAIL",
    "passwordHash": "$ADMIN_HASH",
    "name": "$ADMIN_NAME",
    "role": "admin"
  }
]
EOF

echo "✅ Fichier users.json créé"
echo ""

# Créer le secret Kubernetes
echo "🚀 Création du secret Kubernetes..."
kubectl create secret generic auth-users \
  --from-file=users.json=users.json \
  --namespace=$NAMESPACE \
  --dry-run=client -o yaml | kubectl apply -f -

if [ $? -eq 0 ]; then
    echo "✅ Secret 'auth-users' créé/mis à jour dans le namespace '$NAMESPACE'"
else
    echo "❌ Erreur lors de la création du secret"
    exit 1
fi

# Créer le secret JWT
JWT_SECRET=$(openssl rand -base64 32)
kubectl create secret generic auth-jwt \
  --from-literal=jwt-secret="$JWT_SECRET" \
  --namespace=$NAMESPACE \
  --dry-run=client -o yaml | kubectl apply -f -

if [ $? -eq 0 ]; then
    echo "✅ Secret 'auth-jwt' créé/mis à jour dans le namespace '$NAMESPACE'"
else
    echo "❌ Erreur lors de la création du secret JWT"
    exit 1
fi

echo ""
echo "🎉 Configuration terminée !"
echo ""
echo "📋 Informations de connexion:"
echo "   Email: $ADMIN_EMAIL"
echo "   Mot de passe: $ADMIN_PASSWORD"
echo ""
echo "⚠️  N'oubliez pas de supprimer le fichier users.json après vérification:"
echo "   rm users.json"
echo ""
echo "📦 Secrets créés:"
echo "   - auth-users (contient users.json)"
echo "   - auth-jwt (contient le secret JWT)"
