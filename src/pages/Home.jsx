import Card, { CardHeader, CardTitle, CardDescription, CardContent } from '../components/Card'
import Button from '../components/Button'

export default function Home() {
  return (
    <div className="space-y-8">
      {/* Hero Section */}
      <div className="text-center space-y-4 py-12">
        <h1 className="text-4xl font-bold tracking-tight sm:text-5xl md:text-6xl">
          Bienvenue sur <span className="text-primary">ToolsApps</span>
        </h1>
        <p className="text-xl text-muted-foreground max-w-2xl mx-auto">
          Une application moderne construite avec React, Vite, TailwindCSS et déployée sur Kubernetes
        </p>
        <div className="flex gap-4 justify-center pt-4">
          <Button size="lg">
            Commencer
          </Button>
          <Button variant="outline" size="lg">
            En savoir plus
          </Button>
        </div>
      </div>

      {/* Features Grid */}
      <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
        <Card>
          <CardHeader>
            <CardTitle className="text-xl">⚡ Performant</CardTitle>
            <CardDescription>
              Construit avec Vite pour un développement ultra-rapide
            </CardDescription>
          </CardHeader>
          <CardContent>
            <p className="text-sm">
              Hot Module Replacement instantané et build optimisé pour la production.
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="text-xl">🎨 Design Moderne</CardTitle>
            <CardDescription>
              Interface élégante avec TailwindCSS
            </CardDescription>
          </CardHeader>
          <CardContent>
            <p className="text-sm">
              Design system cohérent avec des composants réutilisables.
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="text-xl">☸️ Kubernetes</CardTitle>
            <CardDescription>
              Déployé sur K3s avec Helm Charts
            </CardDescription>
          </CardHeader>
          <CardContent>
            <p className="text-sm">
              Infrastructure professionnelle avec SSL automatique via Let's Encrypt.
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="text-xl">🔐 Sécurisé</CardTitle>
            <CardDescription>
              HTTPS par défaut avec Traefik
            </CardDescription>
          </CardHeader>
          <CardContent>
            <p className="text-sm">
              Certificats SSL automatiques et renouvellement transparent.
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="text-xl">🚀 Scalable</CardTitle>
            <CardDescription>
              Architecture cloud-native
            </CardDescription>
          </CardHeader>
          <CardContent>
            <p className="text-sm">
              Prêt pour passer à l'échelle avec des réplicas Kubernetes.
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="text-xl">📦 Helm Charts</CardTitle>
            <CardDescription>
              Déploiement professionnel SRE
            </CardDescription>
          </CardHeader>
          <CardContent>
            <p className="text-sm">
              Gestion de configuration avec values.yaml et ConfigMaps.
            </p>
          </CardContent>
        </Card>
      </div>

      {/* Tech Stack */}
      <Card>
        <CardHeader>
          <CardTitle>Stack Technologique</CardTitle>
          <CardDescription>
            Technologies modernes utilisées dans ce projet
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            <div className="text-center p-4 border rounded-lg">
              <div className="text-3xl mb-2">⚛️</div>
              <div className="font-semibold">React 18</div>
              <div className="text-xs text-muted-foreground">UI Library</div>
            </div>
            <div className="text-center p-4 border rounded-lg">
              <div className="text-3xl mb-2">⚡</div>
              <div className="font-semibold">Vite 5</div>
              <div className="text-xs text-muted-foreground">Build Tool</div>
            </div>
            <div className="text-center p-4 border rounded-lg">
              <div className="text-3xl mb-2">🎨</div>
              <div className="font-semibold">TailwindCSS</div>
              <div className="text-xs text-muted-foreground">Styling</div>
            </div>
            <div className="text-center p-4 border rounded-lg">
              <div className="text-3xl mb-2">☸️</div>
              <div className="font-semibold">Kubernetes</div>
              <div className="text-xs text-muted-foreground">Orchestration</div>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  )
}

