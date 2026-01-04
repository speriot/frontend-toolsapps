# Résolution du problème 502 Bad Gateway

**Date:** 3 janvier 2026  
**Application:** front.toolsapps.eu  
**Problème:** 502 Bad Gateway malgré tous les composants fonctionnels

## ❌ Le Problème

Après avoir déployé la v1.1.0, le site retournait **502 Bad Gateway** alors que :
- ✅ Les pods étaient en cours d'exécution (3 replicas)
- ✅ Le service répondait via port-forward
- ✅ Le certificat SSL était valide
- ✅ L'Ingress était correctement configuré
- ✅ Traefik voyait l'Ingress

## 🔍 Diagnostic

### Test clé qui a révélé le problème :
```bash
kubectl run curl-test --image=curlimages/curl --rm -it --restart=Never -- \
  curl -I http://frontend-toolsapps.production.svc.cluster.local
# Résultat: Connection refused
```

**Les pods ne répondaient même pas depuis l'intérieur du cluster !**

### Cause racine : NetworkPolicy incorrecte

```bash
kubectl get networkpolicy -n production
# Une NetworkPolicy existait !
```

La NetworkPolicy était configurée pour **bloquer tout le trafic** sauf celui provenant de namespaces ayant le label `name: ingress-nginx` :

```yaml
spec:
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress-nginx  # ❌ PROBLÈME ICI
    ports:
    - port: 80
```

**Mais notre ingress controller est Traefik (pas nginx) dans le namespace `traefik`** qui n'a PAS ce label !

```bash
kubectl get namespace traefik --show-labels
# LABELS: kubernetes.io/metadata.name=traefik
# ❌ Pas de label "name: ingress-nginx"
```

## ✅ Solution

Suppression de la NetworkPolicy inadaptée :

```bash
kubectl delete networkpolicy frontend-toolsapps -n production
```

**Résultat immédiat :** Le site fonctionne ! ✨

## 📋 Leçons apprises

1. **NetworkPolicy = pare-feu Kubernetes** : Peut bloquer silencieusement le trafic
2. **Tester le Service directement** : `kubectl run curl-test` révèle les problèmes de connectivité
3. **Vérifier TOUTES les ressources** : `kubectl get networkpolicy -A`
4. **Adapter la config à l'ingress controller utilisé** : nginx ≠ traefik

## 🛠️ Pour éviter ce problème à l'avenir

### Option 1 : Pas de NetworkPolicy (simple)
Ne pas créer de NetworkPolicy si vous n'avez pas de besoins de sécurité spécifiques.

### Option 2 : NetworkPolicy adaptée à Traefik
Si vous avez besoin d'une NetworkPolicy, utilisez :

```yaml
spec:
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: traefik  # ✅ Correct pour Traefik
    ports:
    - port: 80
      protocol: TCP
```

### Option 3 : NetworkPolicy permissive
Autoriser tout le trafic interne au cluster :

```yaml
spec:
  ingress:
  - from:
    - namespaceSelector: {}  # ✅ Autorise tous les namespaces
    ports:
    - port: 80
```

## 📊 Chronologie de la résolution

1. **Problème initial** : 502 Bad Gateway via HTTPS
2. **Vérifications** : Pods ✅, Service via port-forward ✅, Ingress ✅, SSL ✅
3. **Test crucial** : curl depuis l'intérieur du cluster → **Connection refused** ❌
4. **Découverte** : NetworkPolicy présente et bloquante
5. **Analyse** : Label namespace incorrect (`ingress-nginx` au lieu de `traefik`)
6. **Solution** : Suppression de la NetworkPolicy
7. **Résultat** : ✅ Site fonctionnel immédiatement

## 🎯 Commandes de diagnostic utiles

```bash
# Vérifier les NetworkPolicies
kubectl get networkpolicy -A

# Tester la connectivité interne
kubectl run curl-test --image=curlimages/curl --rm -it --restart=Never -- \
  curl -I http://SERVICE.NAMESPACE.svc.cluster.local

# Vérifier les labels d'un namespace
kubectl get namespace NAMESPACE --show-labels

# Vérifier qu'un port écoute dans un pod
kubectl exec -n NAMESPACE POD_NAME -- ss -tlnp
```

---

**Temps de résolution:** ~2 heures  
**Tokens Copilot consommés:** Beaucoup trop ! 😅  
**Complexité Kubernetes:** Confirmée ! 🤯
