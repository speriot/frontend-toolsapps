#!/bin/bash

# Script pour créer le secret MQTT Kubernetes
# Usage: ./create-mqtt-secret.sh [namespace]

NAMESPACE=${1:-default}

echo "🔐 Création du secret MQTT pour Kubernetes"
echo "=========================================="
echo ""

# Vérifier que kubectl est installé
if ! command -v kubectl &> /dev/null; then
    echo "❌ Erreur: kubectl n'est pas installé"
    exit 1
fi

# Vérifier si le secret existe déjà
if kubectl get secret mqtt-credentials -n $NAMESPACE &>/dev/null; then
    echo "⚠️  Le secret 'mqtt-credentials' existe déjà dans le namespace '$NAMESPACE'"
    read -p "Voulez-vous le remplacer? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Opération annulée"
        exit 0
    fi
    echo "🗑️  Suppression de l'ancien secret..."
    kubectl delete secret mqtt-credentials -n $NAMESPACE
fi

# Demander les credentials
echo "📝 Entrez les credentials MQTT:"
echo ""

read -p "Username MQTT (ex: portal569): " username
if [ -z "$username" ]; then
    echo "❌ Le username ne peut pas être vide"
    exit 1
fi

read -s -p "Password MQTT: " password
echo
if [ -z "$password" ]; then
    echo "❌ Le password ne peut pas être vide"
    exit 1
fi

echo ""
echo "🔨 Création du secret..."

# Créer le secret
kubectl create secret generic mqtt-credentials \
    --from-literal=username="$username" \
    --from-literal=password="$password" \
    --namespace $NAMESPACE

if [ $? -ne 0 ]; then
    echo "❌ Erreur lors de la création du secret"
    exit 1
fi

echo ""
echo "✅ Secret créé avec succès!"
echo ""
echo "📋 Informations:"
echo "  • Nom du secret: mqtt-credentials"
echo "  • Namespace: $NAMESPACE"
echo "  • Username: $username"
echo "  • Password: ********"
echo ""
echo "🔍 Vérification:"
kubectl get secret mqtt-credentials -n $NAMESPACE

echo ""
echo "✨ Configuration terminée!"
echo "Vous pouvez maintenant déployer l'application avec:"
echo "  ./deploy-mqtt-sse.sh"
