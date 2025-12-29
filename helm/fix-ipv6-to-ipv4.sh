#!/bin/bash
# Script de correction pour remplacer IPv6 par IPv4 dans le Ingress Controller
# Usage: bash fix-ipv6-to-ipv4.sh

set -e

echo "🔧 Correction IPv6 → IPv4 pour NGINX Ingress Controller"
echo "=========================================================="
echo ""

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Vérifier si root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}❌ Ce script doit être exécuté en tant que root${NC}"
  exit 1
fi

# Détecter IPv4
echo -e "${YELLOW}📡 Détection de l'IPv4 publique...${NC}"

# Méthode 1: curl avec force IPv4
PUBLIC_IP=$(curl -4 -s ifconfig.me 2>/dev/null)

# Méthode 2: api.ipify.org (uniquement IPv4)
if [[ -z $PUBLIC_IP ]]; then
  PUBLIC_IP=$(curl -s api.ipify.org 2>/dev/null)
fi

# Méthode 3: ip addr (interface réseau)
if [[ -z $PUBLIC_IP ]]; then
  PUBLIC_IP=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | head -n 1)
fi

# Vérifier si c'est une IPv4 valide
if [[ ! $PUBLIC_IP =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
  echo -e "${RED}❌ Impossible de détecter automatiquement l'IPv4${NC}"
  echo ""
  echo -e "${YELLOW}Vous pouvez trouver votre IPv4 publique:${NC}"
  echo "  • Dans votre panel Hostinger"
  echo "  • Avec: curl -4 ifconfig.me"
  echo "  • Avec: curl api.ipify.org"
  echo ""
  read -p "Entrez manuellement votre IPv4 publique: " PUBLIC_IP

  # Vérifier à nouveau
  if [[ ! $PUBLIC_IP =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    echo -e "${RED}❌ IPv4 invalide: $PUBLIC_IP${NC}"
    exit 1
  fi
fi

echo -e "${GREEN}✅ IPv4 détectée: $PUBLIC_IP${NC}"
echo ""

# Vérifier si l'ingress controller existe
if ! helm list -n ingress-nginx | grep -q ingress-nginx; then
  echo -e "${RED}❌ NGINX Ingress Controller n'est pas installé${NC}"
  echo -e "${YELLOW}   Installez-le d'abord avec ./setup-vps.sh${NC}"
  exit 1
fi

echo -e "${YELLOW}🔄 Mise à jour de NGINX Ingress Controller avec IPv4...${NC}"

# Mettre à jour l'Ingress Controller avec la bonne IPv4
helm upgrade ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --reuse-values \
  --set controller.service.externalIPs[0]=$PUBLIC_IP

if [ $? -eq 0 ]; then
  echo -e "${GREEN}✅ NGINX Ingress Controller mis à jour avec IPv4: $PUBLIC_IP${NC}"
else
  echo -e "${RED}❌ Erreur lors de la mise à jour${NC}"
  exit 1
fi

# Attendre que le pod se redémarre
echo ""
echo -e "${YELLOW}⏳ Attente du redémarrage des pods...${NC}"
sleep 5

kubectl rollout status deployment/ingress-nginx-controller -n ingress-nginx --timeout=120s

# Vérifier la configuration
echo ""
echo -e "${GREEN}📋 Vérification de la configuration:${NC}"
kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.spec.externalIPs[0]}'
echo ""

echo ""
echo -e "${GREEN}✅ Correction terminée!${NC}"
echo ""
echo -e "${YELLOW}📝 Prochaines étapes:${NC}"
echo "  1. Configurer votre DNS: front.toolsapps.eu → $PUBLIC_IP"
echo "  2. Vérifier que l'ingress fonctionne:"
echo "     kubectl get ingress -n production"
echo ""

