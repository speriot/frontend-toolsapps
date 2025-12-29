# 🔧 CORRECTION DU PROBLÈME 404

## 📋 Diagnostic
- ✅ Les pods répondent correctement (200 OK)
- ❌ Le service Kubernetes ne peut pas joindre les pods
- 🔍 Cause: **Incompatibilité entre les labels des pods et les selectors du service**

## 🚀 SOLUTION - Commandes à exécuter sur le VPS

### 1️⃣ Récupérer les dernières modifications depuis GitHub

```bash
cd ~/frontend-toolsapps
git pull origin main
```

### 2️⃣ Rendre le script exécutable

```bash
chmod +x helm/fix-service-selector.sh
```

### 3️⃣ Exécuter le script de correction

```bash
./helm/fix-service-selector.sh
```

---

## 🎯 Ce que fait le script :

1. **Affiche** les labels actuels des pods
2. **Affiche** les selectors du service
3. **Patch** le deployment pour ajouter les labels manquants :
   - `app.kubernetes.io/name: frontend-toolsapps`
   - `app.kubernetes.io/instance: frontend-toolsapps`
4. **Attend** le redéploiement des pods
5. **Teste** le service en interne
6. **Teste** l'accès externe via Ingress

---

## ✅ Après l'exécution

Vous devriez voir :
- ✅ Deployment patché avec succès
- ✅ Pods redémarrés avec les bons labels
- ✅ Service accessible (code HTTP: 200)
- ✅ Ingress accessible (code HTTP: 200)

**Testez dans votre navigateur :**
- http://front.toolsapps.eu
- https://front.toolsapps.eu (avec certificat staging Let's Encrypt)

---

## 🔄 Si le patch échoue

Le script essaiera automatiquement une alternative :
- Redéploiement complet via Helm
- Avec la bonne configuration des labels

---

## 📝 Commande alternative manuelle

Si vous préférez le faire manuellement :

```bash
cd ~/frontend-toolsapps

helm upgrade --install frontend-toolsapps ./helm/frontend-toolsapps \
  --namespace production \
  --set image.repository=docker.io/st3ph31/frontend-toolsapps \
  --set image.tag=v1.0.0 \
  --set ingress.hosts[0].host=front.toolsapps.eu \
  --set ingress.hosts[0].paths[0].path=/ \
  --set ingress.hosts[0].paths[0].pathType=Prefix \
  --set ingress.tls[0].secretName=frontend-toolsapps-tls \
  --set ingress.tls[0].hosts[0]=front.toolsapps.eu \
  --wait
```

---

## 🔍 Vérifications post-correction

### Vérifier que les pods ont les bons labels :
```bash
kubectl get pods -n production -o json | jq '.items[0].metadata.labels'
```

### Vérifier que le service peut trouver les pods :
```bash
kubectl get endpoints -n production frontend-toolsapps
```

Vous devriez voir 3 IPs (une par pod).

### Test final :
```bash
curl -I http://front.toolsapps.eu
```

Devrait retourner : **HTTP/1.1 200 OK**

---

**🎉 Une fois corrigé, votre application sera enfin accessible !**

