# 🚀 COMMANDES RAPIDES - VPS

## 📋 Commandes essentielles pour gérer votre application

### 🔍 Vérification et Monitoring

#### Statut complet de l'application
```bash
cd ~/frontend-toolsapps
./helm/verify-deployment.sh
```

#### Voir les pods
```bash
kubectl get pods -n production
kubectl get pods -n production -o wide  # avec IPs
kubectl get pods -n production -w       # en temps réel
```

#### Voir les logs
```bash
# Logs de tous les pods
kubectl logs -n production -l app.kubernetes.io/name=frontend-toolsapps --tail=100

# Logs d'un pod spécifique
kubectl logs -n production <nom-du-pod>

# Logs en temps réel
kubectl logs -n production -l app.kubernetes.io/name=frontend-toolsapps -f
```

#### Vérifier le service et endpoints
```bash
kubectl get svc -n production
kubectl get endpoints -n production
```

#### Vérifier l'Ingress et le certificat SSL
```bash
kubectl get ingress -n production
kubectl get certificate -n production
kubectl describe certificate -n production frontend-toolsapps-tls
```

---

### 🔄 Redémarrage et Mise à jour

#### Redémarrer l'application (sans interruption)
```bash
kubectl rollout restart deployment/frontend-toolsapps -n production
```

#### Mettre à jour l'image Docker
```bash
helm upgrade frontend-toolsapps ./helm/frontend-toolsapps \
  --namespace production \
  --set image.tag=v1.0.1 \
  --wait
```

#### Redéployer complètement
```bash
cd ~/frontend-toolsapps
git pull origin main

helm upgrade --install frontend-toolsapps ./helm/frontend-toolsapps \
  --namespace production \
  --set image.repository=docker.io/st3ph31/frontend-toolsapps \
  --set image.tag=v1.0.0 \
  --set ingress.hosts[0].host=front.toolsapps.eu \
  --wait
```

---

### 🛠️ Diagnostic et Dépannage

#### Diagnostic 404
```bash
cd ~/frontend-toolsapps
./helm/diagnose-404.sh
```

#### Diagnostic SSL
```bash
cd ~/frontend-toolsapps
./helm/diagnose-ssl.sh
```

#### Vérifier les événements
```bash
kubectl get events -n production --sort-by='.lastTimestamp'
```

#### Se connecter dans un pod
```bash
POD=$(kubectl get pods -n production -l app.kubernetes.io/name=frontend-toolsapps -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it -n production $POD -- /bin/sh
```

#### Test HTTP depuis l'intérieur du cluster
```bash
kubectl run test-pod --rm -i --restart=Never --image=curlimages/curl -n production -- curl -v http://frontend-toolsapps:80
```

---

### 🔐 Gestion SSL/TLS

#### Voir l'état du certificat
```bash
kubectl get certificate -n production
kubectl describe certificate -n production frontend-toolsapps-tls
```

#### Voir les logs de cert-manager
```bash
kubectl logs -n cert-manager -l app=cert-manager --tail=50
```

#### Forcer le renouvellement du certificat
```bash
kubectl delete certificate frontend-toolsapps-tls -n production
kubectl delete secret frontend-toolsapps-tls -n production
# Le certificat sera automatiquement recréé
```

#### Passer en production SSL (après le 31/12)
```bash
cd ~/frontend-toolsapps
./helm/switch-to-production.sh
```

---

### 📊 Scaling et Performance

#### Voir l'état de l'autoscaling
```bash
kubectl get hpa -n production
```

#### Scaler manuellement
```bash
# Augmenter à 5 réplicas
kubectl scale deployment frontend-toolsapps -n production --replicas=5

# Revenir à 3 réplicas
kubectl scale deployment frontend-toolsapps -n production --replicas=3
```

#### Voir les métriques
```bash
kubectl top nodes
kubectl top pods -n production
```

---

### 🧹 Nettoyage et Maintenance

#### Supprimer l'application
```bash
helm uninstall frontend-toolsapps -n production
```

#### Nettoyer tous les objets
```bash
kubectl delete all -n production -l app.kubernetes.io/name=frontend-toolsapps
kubectl delete ingress frontend-toolsapps -n production
kubectl delete certificate frontend-toolsapps-tls -n production
kubectl delete secret frontend-toolsapps-tls -n production
```

#### Supprimer le namespace complet
```bash
kubectl delete namespace production
```

---

### 🔄 Git et Docker

#### Mettre à jour depuis GitHub
```bash
cd ~/frontend-toolsapps
git pull origin main
```

#### Voir les images Docker locales
```bash
docker images | grep frontend-toolsapps
```

#### Nettoyer les anciennes images
```bash
docker image prune -a
```

---

### 📝 Tests

#### Test HTTP externe
```bash
curl -I http://front.toolsapps.eu
curl http://front.toolsapps.eu
```

#### Test HTTPS externe
```bash
curl -I https://front.toolsapps.eu
curl -k https://front.toolsapps.eu  # avec certificat staging
```

#### Test avec verbose
```bash
curl -v http://front.toolsapps.eu
```

#### Test depuis un navigateur en ligne de commande
```bash
wget -O- http://front.toolsapps.eu
```

---

### 🆘 En cas de problème

#### L'application ne démarre pas
```bash
# Voir les logs du pod qui ne démarre pas
kubectl logs -n production <nom-du-pod>

# Voir les événements du pod
kubectl describe pod -n production <nom-du-pod>
```

#### Erreur 404
```bash
# Vérifier que le service trouve les pods
kubectl get endpoints -n production frontend-toolsapps

# Si pas d'endpoints, vérifier les labels
kubectl get pods -n production --show-labels
```

#### Problème SSL
```bash
# Vérifier l'état du certificat
kubectl describe certificate -n production frontend-toolsapps-tls

# Voir les challenges
kubectl get challenges -n production
kubectl describe challenges -n production

# Vérifier les orders
kubectl get orders -n production
kubectl describe orders -n production
```

#### Ingress ne fonctionne pas
```bash
# Vérifier l'Ingress Controller
kubectl get pods -n kube-system | grep ingress
kubectl logs -n kube-system <ingress-controller-pod>

# Vérifier la configuration de l'Ingress
kubectl describe ingress -n production frontend-toolsapps
```

---

### 📦 Helm

#### Lister les déploiements Helm
```bash
helm list -n production
```

#### Voir l'historique des déploiements
```bash
helm history frontend-toolsapps -n production
```

#### Rollback à une version précédente
```bash
helm rollback frontend-toolsapps -n production
```

#### Voir les valeurs actuelles
```bash
helm get values frontend-toolsapps -n production
```

#### Voir le manifest complet
```bash
helm get manifest frontend-toolsapps -n production
```

#### Tester le chart (dry-run)
```bash
helm install frontend-toolsapps ./helm/frontend-toolsapps \
  --namespace production \
  --dry-run --debug
```

---

### 🔒 Sécurité

#### Voir les NetworkPolicies
```bash
kubectl get networkpolicies -n production
kubectl describe networkpolicy -n production
```

#### Voir les ServiceAccounts
```bash
kubectl get serviceaccounts -n production
```

#### Voir les secrets
```bash
kubectl get secrets -n production
```

---

### 💾 Backup

#### Backup de la configuration Helm
```bash
helm get values frontend-toolsapps -n production > backup-values.yaml
helm get manifest frontend-toolsapps -n production > backup-manifest.yaml
```

#### Export de tous les objets
```bash
kubectl get all -n production -o yaml > backup-all.yaml
```

---

## 🎯 Workflow complet de mise à jour

### Sur votre machine locale

1. **Modifier le code**
2. **Builder l'image**
   ```powershell
   cd C:\dev\frontend-app
   .\deploy-docker.ps1 -Registry "docker.io/st3ph31" -Tag "v1.0.1"
   ```
3. **Commit et push**
   ```powershell
   git add .
   git commit -m "feat: New feature"
   git push
   ```

### Sur le VPS

4. **Récupérer les changements**
   ```bash
   cd ~/frontend-toolsapps
   git pull origin main
   ```

5. **Déployer la nouvelle version**
   ```bash
   helm upgrade frontend-toolsapps ./helm/frontend-toolsapps \
     --namespace production \
     --set image.tag=v1.0.1 \
     --wait
   ```

6. **Vérifier**
   ```bash
   kubectl get pods -n production -w
   curl http://front.toolsapps.eu
   ```

---

**📚 Plus d'infos : Consultez `DEPLOIEMENT-SUCCESS.md` et `FELICITATIONS.md`**

