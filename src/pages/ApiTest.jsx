import { useState } from 'react'
import axios from 'axios'
import Card, { CardHeader, CardTitle, CardDescription, CardContent } from '../components/Card'
import Button from '../components/Button'

// Configuration de l'URL de l'API
const API_URL = import.meta.env.VITE_API_URL || 'https://api.toolsapps.eu'

export default function ApiTest() {
  const [loading, setLoading] = useState(false)
  const [response, setResponse] = useState(null)
  const [error, setError] = useState(null)

  const testApi = async () => {
    setLoading(true)
    setError(null)
    setResponse(null)

    try {
      const res = await axios.get(API_URL)
      setResponse(res.data)
    } catch (err) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="max-w-4xl mx-auto space-y-8">
      <div className="space-y-2">
        <h1 className="text-3xl font-bold tracking-tight">Test de l'API</h1>
        <p className="text-lg text-muted-foreground">
          Testez la connexion à l'API backend
        </p>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Configuration API</CardTitle>
          <CardDescription>
            L'API est accessible sur {API_URL}
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="flex gap-4">
            <Button
              onClick={testApi}
              disabled={loading}
            >
              {loading ? 'Chargement...' : 'Tester l\'API'}
            </Button>
          </div>

          {error && (
            <div className="p-4 border border-red-200 bg-red-50 rounded-lg">
              <p className="text-sm font-semibold text-red-800">Erreur</p>
              <p className="text-sm text-red-600 mt-1">{error}</p>
            </div>
          )}

          {response && (
            <div className="space-y-2">
              <p className="text-sm font-semibold text-green-600">✓ Réponse reçue</p>
              <pre className="p-4 bg-muted rounded-lg overflow-x-auto text-sm">
                {typeof response === 'string'
                  ? response
                  : JSON.stringify(response, null, 2)
                }
              </pre>
            </div>
          )}
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>À propos de cette page</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <p className="text-sm">
            Cette page de test vous permet de vérifier la connectivité entre le frontend
            (front.toolsapps.eu) et le backend (api.toolsapps.eu).
          </p>
          <div className="space-y-2">
            <h3 className="font-semibold text-sm">Comment ça fonctionne ?</h3>
            <ol className="list-decimal list-inside space-y-1 text-sm text-muted-foreground">
              <li>Le frontend envoie une requête GET à l'API</li>
              <li>La requête passe par Traefik (reverse proxy)</li>
              <li>Traefik route vers le service backend approprié</li>
              <li>La réponse est retournée et affichée ci-dessus</li>
            </ol>
          </div>
          <div className="p-4 bg-blue-50 border border-blue-200 rounded-lg">
            <p className="text-sm text-blue-800">
              💡 <strong>Astuce :</strong> L'URL de l'API peut être configurée via la
              variable d'environnement <code className="px-1 py-0.5 bg-blue-100 rounded">VITE_API_URL</code>
              ou via une ConfigMap Kubernetes.
            </p>
          </div>
        </CardContent>
      </Card>
    </div>
  )
}

