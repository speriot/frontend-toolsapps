Voici **le guide de débogage Traefik / cert‑manager** que tu voulais — structuré, clair, opérationnel, et pensé pour « Stéphane du futur » qui veut aller droit au but quand quelque chose casse.

---

# 🛠️ Guide de Debug Traefik / cert‑manager
*Pour clusters k3s / Traefik / Let’s Encrypt*

---

# 🧭 1. Déboguer Traefik (Ingress)

## 🔍 1.1. Vérifier que l’Ingress est bien pris en charge par Traefik
Traefik ne gère l’Ingress **que si** :

- `ingressClassName: traefik` est présent
- OU annotation : `kubernetes.io/ingress.class: traefik`

### Commande :
```bash
kubectl get ingress -A
```

Vérifie la colonne `CLASS`.

Si vide → Traefik ignore l’Ingress.

---

## 🔍 1.2. Vérifier que Traefik a bien créé la route
```bash
kubectl -n kube-system get ingressroute
kubectl -n kube-system get traefikservice
```

Si rien n’apparaît → Traefik n’a pas pris l’Ingress.

---

## 🔍 1.3. Vérifier les logs de Traefik
```bash
kubectl -n kube-system logs -l app=traefik
```

Cherche :

- `level=error`
- `service not found`
- `no route match`
- `certificate not found`

---

## 🔍 1.4. Vérifier que le Service pointe vers le bon port
C’est **la cause la plus fréquente** des 404.

```bash
kubectl get svc my-api -o yaml
```

Vérifie :

- `port: 80`
- `targetPort: 3000` (ou ton port réel)

Puis vérifie le Deployment :

```bash
kubectl get deploy my-api -o yaml
```

Le container doit exposer le même port.

---

## 🔍 1.5. Vérifier que le Pod répond bien en interne
```bash
kubectl exec -it deploy/my-api -- wget -qO- http://localhost:3000/health
```

Si ça ne répond pas → problème dans l’application, pas dans Traefik.

---

## 🔍 1.6. Vérifier le DNS
```bash
dig +short api.mondomaine.fr
```

Doit renvoyer l’IP publique du VPS.

---

## 🔍 1.7. Vérifier que Traefik écoute bien sur 80/443
Sur k3s :

```bash
kubectl -n kube-system get svc traefik
```

Tu dois voir :

- port 80 → HTTP
- port 443 → HTTPS

---

# 🔐 2. Déboguer cert‑manager (Let’s Encrypt)

## 🔍 2.1. Vérifier les ClusterIssuers
```bash
kubectl get clusterissuer
kubectl describe clusterissuer letsencrypt-prod
```

Cherche :

- `Ready: True`
- Pas d’erreurs ACME

---

## 🔍 2.2. Vérifier les Certificates
```bash
kubectl get certificate -A
kubectl describe certificate api-tls -n <namespace>
```

Points à vérifier :

- `Ready: True`
- `Not After` → date d’expiration
- `Events` → erreurs ACME

---

## 🔍 2.3. Vérifier les Orders (ACME)
```bash
kubectl get orders -A
kubectl describe order <order-name>
```

Erreurs fréquentes :

- `DNS problem: NXDOMAIN`
- `Timeout during connect`
- `Connection refused`
- `No TXT record found` (DNS-01)

---

## 🔍 2.4. Vérifier les Challenges
```bash
kubectl get challenge -A
kubectl describe challenge <challenge-name>
```

Erreurs typiques :

### ❌ HTTP-01 : 404
→ Traefik ne route pas `/.well-known/acme-challenge/`

### ❌ HTTP-01 : timeout
→ Port 80 bloqué par firewall

### ❌ DNS-01 : record manquant
→ DNS mal configuré

---

## 🔍 2.5. Vérifier les logs de cert‑manager
```bash
kubectl logs -n cert-manager deploy/cert-manager
```

Cherche :

- `Failed to create order`
- `Error presenting challenge`
- `Error cleaning up`
- `rateLimited`

---

# 🧪 3. Tests rapides pour isoler le problème

## 🧪 3.1. Tester l’Ingress sans TLS
Modifie temporairement l’Ingress :

```yaml
tls: []
```

Si ça marche → problème cert‑manager.

---

## 🧪 3.2. Tester le Service directement
```bash
kubectl port-forward svc/my-api 8080:80
curl http://localhost:8080/health
```

Si ça marche → problème Traefik.

---

## 🧪 3.3. Tester le Pod directement
```bash
kubectl exec -it deploy/my-api -- wget -qO- http://localhost:3000
```

Si ça marche → problème Service/Ingress.

---

# 🧹 4. Problèmes fréquents et solutions

## ❌ 404 Traefik
✔️ Vérifie `targetPort`  
✔️ Vérifie `ingressClassName`  
✔️ Vérifie que le Pod répond  
✔️ Vérifie que le DNS pointe au bon endroit

---

## ❌ Certificat ne se génère pas
✔️ Vérifie que le port 80 est ouvert  
✔️ Vérifie que le DNS pointe vers ton VPS  
✔️ Vérifie les Challenges  
✔️ Vérifie les logs cert‑manager  
✔️ Vérifie que l’Ingress expose bien `/.well-known/acme-challenge/`

---

## ❌ Erreur ACME rate limit
✔️ Passe en `letsencrypt-staging`  
✔️ Attends 1h  
✔️ Regénère le certificat

---

# 🧭 5. Checklist finale (rapide)

### Traefik
- [ ] Ingress class OK
- [ ] Service → Deployment ports OK
- [ ] Pod répond
- [ ] DNS OK
- [ ] Traefik logs OK

### cert‑manager
- [ ] ClusterIssuer Ready
- [ ] Certificate Ready
- [ ] Order OK
- [ ] Challenge OK
- [ ] Ports 80/443 ouverts

---

