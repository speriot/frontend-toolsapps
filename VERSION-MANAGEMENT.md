# 🎯 Gestion de Version ToolsApps

## Architecture de versioning

**Source unique de vérité** : `package.json`

La version est synchronisée entre :
- `package.json` → version applicative
- `Dockerfile` → injectée au build via ARG
- `helm/frontend-toolsapps/values-prod.yaml` → tag de l'image Docker
- Application React → affichée via `import.meta.env.VITE_APP_VERSION`

## 🔧 Outils disponibles

### 1. Vérifier la synchronisation
```powershell
.\sync-version.ps1
```

### 2. Mettre à jour la version
```powershell
.\sync-version.ps1 -NewVersion 1.2.0
```

### 3. Build Docker avec version
```powershell
.\build-with-version.ps1
```

## 📦 Workflow de release

### Version locale (dev)
```powershell
npm run dev
# Version affichée : "1.1.0-dev" (depuis .env)
```

### Version production

1. **Mettre à jour la version**
   ```powershell
   .\sync-version.ps1 -NewVersion 1.2.0
   ```

2. **Construire l'image Docker**
   ```powershell
   .\build-with-version.ps1
   ```

3. **Pousser l'image**
   ```powershell
   docker tag frontend-toolsapps:v1.2.0 your-registry/frontend-toolsapps:v1.2.0
   docker push your-registry/frontend-toolsapps:v1.2.0
   ```

4. **Déployer sur Kubernetes**
   ```powershell
   helm upgrade frontend-toolsapps ./helm/frontend-toolsapps `
     -f ./helm/frontend-toolsapps/values-prod.yaml `
     --set image.tag=v1.2.0
   ```

## 🤖 CI/CD (recommandé)

Pour GitHub Actions ou GitLab CI :

```yaml
# .github/workflows/release.yml
name: Release

on:
  push:
    tags:
      - 'v*'

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Get version from package.json
        id: package-version
        run: echo "version=$(node -p "require('./package.json').version")" >> $GITHUB_OUTPUT
      
      - name: Build Docker image
        run: |
          docker build \
            --build-arg APP_VERSION=${{ steps.package-version.outputs.version }} \
            -t your-registry/frontend-toolsapps:v${{ steps.package-version.outputs.version }} \
            .
      
      - name: Push to registry
        run: docker push your-registry/frontend-toolsapps:v${{ steps.package-version.outputs.version }}
      
      - name: Deploy to Kubernetes
        run: |
          helm upgrade frontend-toolsapps ./helm/frontend-toolsapps \
            -f ./helm/frontend-toolsapps/values-prod.yaml \
            --set image.tag=v${{ steps.package-version.outputs.version }}
```

## 📋 Checklist avant release

- [ ] Tests passent : `npm test`
- [ ] Build local OK : `npm run build`
- [ ] Version synchronisée : `.\sync-version.ps1`
- [ ] Image Docker construite : `.\build-with-version.ps1`
- [ ] Changelog mis à jour
- [ ] Tag Git créé : `git tag v1.2.0 && git push --tags`

## 🎨 Affichage de la version

La version est affichée sur :
- **HomePage** : Badge avec point vert animé sous le titre
- **Footer** (optionnel) : À ajouter si besoin

Dans le code :
```jsx
const APP_VERSION = import.meta.env.VITE_APP_VERSION || 'dev'
```

## 🔄 Variables d'environnement

### Development (`.env`)
```env
VITE_APP_VERSION=1.1.0-dev
```

### Production (Dockerfile)
```dockerfile
ARG APP_VERSION
ENV VITE_APP_VERSION=${APP_VERSION}
```

### Kubernetes (values-prod.yaml)
Pas besoin d'ajouter VITE_APP_VERSION en env car elle est injectée au build time.

## 🎯 État de l'art - Résumé

✅ **Ce qui est fait :**
- Version unique dans package.json
- Injection au build Docker
- Scripts de synchronisation
- Affichage dans l'UI

✅ **Avantages :**
- Une seule source de vérité
- Pas de duplication manuelle
- Version visible par les utilisateurs
- Compatible CI/CD

✅ **Conforme aux best practices :**
- Semantic Versioning (SemVer)
- Build-time injection (pas de runtime)
- Automatisation possible
- Traçabilité complète
