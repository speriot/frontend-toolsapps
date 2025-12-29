import Card, { CardHeader, CardTitle, CardDescription, CardContent } from '../components/Card'

export default function About() {
  return (
    <div className="max-w-4xl mx-auto space-y-8">
      <div className="space-y-2">
        <h1 className="text-3xl font-bold tracking-tight">À propos de ToolsApps</h1>
        <p className="text-lg text-muted-foreground">
          Un projet de démonstration d'architecture moderne
        </p>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Objectif du projet</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <p>
            ToolsApps est une application de démonstration conçue pour illustrer les meilleures
            pratiques du développement web moderne et du déploiement cloud-native.
          </p>
          <p>
            Ce projet combine des technologies de pointe pour créer une infrastructure professionnelle,
            scalable et maintenable.
          </p>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Architecture</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="space-y-2">
            <h3 className="font-semibold">Frontend</h3>
            <ul className="list-disc list-inside space-y-1 text-sm text-muted-foreground">
              <li>React 18 avec Vite pour un développement rapide</li>
              <li>TailwindCSS pour un design moderne et responsive</li>
              <li>React Router pour la navigation</li>
              <li>Composants réutilisables inspirés de shadcn/ui</li>
            </ul>
          </div>

          <div className="space-y-2">
            <h3 className="font-semibold">Backend</h3>
            <ul className="list-disc list-inside space-y-1 text-sm text-muted-foreground">
              <li>API REST sur api.toolsapps.eu</li>
              <li>Conteneurisé avec Docker</li>
              <li>Déployé sur Kubernetes (K3s)</li>
            </ul>
          </div>

          <div className="space-y-2">
            <h3 className="font-semibold">Infrastructure</h3>
            <ul className="list-disc list-inside space-y-1 text-sm text-muted-foreground">
              <li>Kubernetes (K3s) sur VPS Hostinger</li>
              <li>Traefik comme Ingress Controller et Reverse Proxy</li>
              <li>Cert-Manager pour les certificats SSL Let's Encrypt</li>
              <li>MetalLB pour le LoadBalancing</li>
              <li>Helm Charts pour la gestion de configuration</li>
              <li>DNS géré via Cloudflare</li>
            </ul>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Informations techniques</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid gap-4 text-sm">
            <div className="flex justify-between py-2 border-b">
              <span className="text-muted-foreground">Domaine Frontend</span>
              <span className="font-mono">front.toolsapps.eu</span>
            </div>
            <div className="flex justify-between py-2 border-b">
              <span className="text-muted-foreground">Domaine API</span>
              <span className="font-mono">api.toolsapps.eu</span>
            </div>
            <div className="flex justify-between py-2 border-b">
              <span className="text-muted-foreground">Hébergement</span>
              <span className="font-mono">Hostinger VPS KVM 2</span>
            </div>
            <div className="flex justify-between py-2 border-b">
              <span className="text-muted-foreground">IP Publique</span>
              <span className="font-mono">72.62.16.206</span>
            </div>
            <div className="flex justify-between py-2 border-b">
              <span className="text-muted-foreground">Kubernetes</span>
              <span className="font-mono">K3s</span>
            </div>
            <div className="flex justify-between py-2">
              <span className="text-muted-foreground">Certificat SSL</span>
              <span className="font-mono">Let's Encrypt (automatique)</span>
            </div>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Contact</CardTitle>
        </CardHeader>
        <CardContent>
          <p className="text-sm text-muted-foreground">
            Email: <a href="mailto:stephane.periot@gmail.com" className="text-primary hover:underline">
              stephane.periot@gmail.com
            </a>
          </p>
        </CardContent>
      </Card>
    </div>
  )
}

