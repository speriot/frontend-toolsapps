import { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import {
  ShoppingCart, Heart, Star, Search, SlidersHorizontal,
  ChevronDown, Plus, Minus, X, Package, Truck, Shield,
  ChevronLeft, ChevronRight, Sparkles
} from 'lucide-react'

const products = [
  {
    id: 1,
    name: 'Casque Audio Premium',
    description: 'Son haute définition avec réduction de bruit active',
    price: 299,
    originalPrice: 399,
    rating: 4.8,
    reviews: 1247,
    image: 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=400&h=400&fit=crop',
    colors: ['#1a1a1a', '#f5f5dc', '#c0c0c0'],
    badge: 'Bestseller',
    inStock: true
  },
  {
    id: 2,
    name: 'Montre Connectée Elite',
    description: 'Suivi fitness avancé et notifications intelligentes',
    price: 449,
    originalPrice: null,
    rating: 4.9,
    reviews: 892,
    image: 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=400&h=400&fit=crop',
    colors: ['#1a1a1a', '#ffd700', '#c0c0c0'],
    badge: 'Nouveau',
    inStock: true
  },
  {
    id: 3,
    name: 'Enceinte Portable 360°',
    description: 'Son immersif 360° et autonomie 24 heures',
    price: 179,
    originalPrice: 229,
    rating: 4.6,
    reviews: 567,
    image: 'https://images.unsplash.com/photo-1608043152269-423dbba4e7e1?w=400&h=400&fit=crop',
    colors: ['#1a1a1a', '#4a90d9', '#e74c3c'],
    badge: '-22%',
    inStock: true
  },
  {
    id: 4,
    name: 'Clavier Mécanique RGB',
    description: 'Switches Cherry MX et rétroéclairage personnalisable',
    price: 159,
    originalPrice: null,
    rating: 4.7,
    reviews: 2341,
    image: 'https://images.unsplash.com/photo-1587829741301-dc798b83add3?w=400&h=400&fit=crop',
    colors: ['#1a1a1a', '#ffffff'],
    badge: null,
    inStock: false
  },
]

const categories = ['Tous', 'Audio', 'Wearables', 'Accessoires', 'Gaming']

function ProductCard({ product, onAddToCart, onAddToWishlist }) {
  const [selectedColor, setSelectedColor] = useState(0)
  const [isHovered, setIsHovered] = useState(false)
  const [isWishlisted, setIsWishlisted] = useState(false)

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      whileHover={{ y: -5 }}
      onHoverStart={() => setIsHovered(true)}
      onHoverEnd={() => setIsHovered(false)}
      className="group bg-card rounded-2xl border shadow-sm overflow-hidden"
    >
      {/* Image */}
      <div className="relative aspect-square bg-gradient-to-br from-muted/50 to-muted overflow-hidden">
        <motion.img
          src={product.image}
          alt={product.name}
          className="w-full h-full object-cover"
          animate={{ scale: isHovered ? 1.1 : 1 }}
          transition={{ duration: 0.4 }}
        />

        {/* Badge */}
        {product.badge && (
          <div className={`absolute top-3 left-3 px-2 py-1 rounded-lg text-xs font-semibold ${
            product.badge === 'Nouveau' 
              ? 'bg-primary text-primary-foreground' 
              : product.badge === 'Bestseller'
                ? 'bg-yellow-500 text-black'
                : 'bg-red-500 text-white'
          }`}>
            {product.badge}
          </div>
        )}

        {/* Wishlist button */}
        <motion.button
          initial={{ opacity: 0 }}
          animate={{ opacity: isHovered || isWishlisted ? 1 : 0 }}
          whileTap={{ scale: 0.9 }}
          onClick={() => setIsWishlisted(!isWishlisted)}
          className="absolute top-3 right-3 w-10 h-10 rounded-full bg-background/80 backdrop-blur flex items-center justify-center shadow-lg"
        >
          <Heart className={`w-5 h-5 transition-colors ${isWishlisted ? 'fill-red-500 text-red-500' : ''}`} />
        </motion.button>

        {/* Quick add button */}
        <AnimatePresence>
          {isHovered && product.inStock && (
            <motion.button
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: 20 }}
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.98 }}
              onClick={() => onAddToCart(product)}
              className="absolute bottom-3 left-3 right-3 py-3 rounded-xl bg-primary text-primary-foreground font-semibold shadow-lg flex items-center justify-center gap-2"
            >
              <ShoppingCart className="w-5 h-5" />
              Ajouter au panier
            </motion.button>
          )}
        </AnimatePresence>

        {!product.inStock && (
          <div className="absolute inset-0 bg-background/50 backdrop-blur-sm flex items-center justify-center">
            <span className="px-4 py-2 bg-background rounded-lg font-semibold">Rupture de stock</span>
          </div>
        )}
      </div>

      {/* Info */}
      <div className="p-4 space-y-3">
        <div>
          <h3 className="font-semibold truncate">{product.name}</h3>
          <p className="text-sm text-muted-foreground line-clamp-1">{product.description}</p>
        </div>

        {/* Rating */}
        <div className="flex items-center gap-2">
          <div className="flex items-center gap-1">
            <Star className="w-4 h-4 fill-yellow-400 text-yellow-400" />
            <span className="text-sm font-medium">{product.rating}</span>
          </div>
          <span className="text-sm text-muted-foreground">({product.reviews} avis)</span>
        </div>

        {/* Colors */}
        <div className="flex items-center gap-2">
          {product.colors.map((color, i) => (
            <button
              key={i}
              onClick={() => setSelectedColor(i)}
              className={`w-6 h-6 rounded-full border-2 transition-all ${
                selectedColor === i ? 'border-primary scale-110' : 'border-transparent'
              }`}
              style={{ backgroundColor: color }}
            />
          ))}
        </div>

        {/* Price */}
        <div className="flex items-center gap-2">
          <span className="text-xl font-bold">{product.price}€</span>
          {product.originalPrice && (
            <span className="text-sm text-muted-foreground line-through">{product.originalPrice}€</span>
          )}
        </div>
      </div>
    </motion.div>
  )
}

function CartItem({ item, onUpdateQuantity, onRemove }) {
  return (
    <motion.div
      layout
      initial={{ opacity: 0, x: 20 }}
      animate={{ opacity: 1, x: 0 }}
      exit={{ opacity: 0, x: -20 }}
      className="flex gap-4 p-4 bg-muted/50 rounded-xl"
    >
      <img
        src={item.image}
        alt={item.name}
        className="w-20 h-20 object-cover rounded-lg"
      />
      <div className="flex-1 min-w-0">
        <h4 className="font-medium truncate">{item.name}</h4>
        <p className="text-sm text-muted-foreground">{item.price}€</p>

        <div className="flex items-center gap-2 mt-2">
          <button
            onClick={() => onUpdateQuantity(item.id, item.quantity - 1)}
            className="w-7 h-7 rounded-lg border flex items-center justify-center hover:bg-muted"
          >
            <Minus className="w-4 h-4" />
          </button>
          <span className="w-8 text-center font-medium">{item.quantity}</span>
          <button
            onClick={() => onUpdateQuantity(item.id, item.quantity + 1)}
            className="w-7 h-7 rounded-lg border flex items-center justify-center hover:bg-muted"
          >
            <Plus className="w-4 h-4" />
          </button>
        </div>
      </div>
      <div className="flex flex-col items-end justify-between">
        <button
          onClick={() => onRemove(item.id)}
          className="p-1 text-muted-foreground hover:text-foreground"
        >
          <X className="w-4 h-4" />
        </button>
        <span className="font-semibold">{item.price * item.quantity}€</span>
      </div>
    </motion.div>
  )
}

function ShoppingCartPanel({ items, isOpen, onClose, onUpdateQuantity, onRemove }) {
  const total = items.reduce((sum, item) => sum + item.price * item.quantity, 0)

  return (
    <AnimatePresence>
      {isOpen && (
        <>
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={onClose}
            className="fixed inset-0 bg-background/80 backdrop-blur-sm z-40"
          />
          <motion.div
            initial={{ x: '100%' }}
            animate={{ x: 0 }}
            exit={{ x: '100%' }}
            transition={{ type: 'spring', damping: 30 }}
            className="fixed top-0 right-0 bottom-0 w-full max-w-md bg-card border-l shadow-2xl z-50 flex flex-col"
          >
            {/* Header */}
            <div className="flex items-center justify-between p-4 border-b">
              <div className="flex items-center gap-2">
                <ShoppingCart className="w-5 h-5" />
                <h2 className="font-semibold">Panier ({items.length})</h2>
              </div>
              <button onClick={onClose} className="p-2 hover:bg-muted rounded-lg">
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* Items */}
            <div className="flex-1 overflow-y-auto p-4 space-y-3">
              <AnimatePresence>
                {items.length > 0 ? (
                  items.map(item => (
                    <CartItem
                      key={item.id}
                      item={item}
                      onUpdateQuantity={onUpdateQuantity}
                      onRemove={onRemove}
                    />
                  ))
                ) : (
                  <motion.div
                    initial={{ opacity: 0 }}
                    animate={{ opacity: 1 }}
                    className="flex flex-col items-center justify-center py-12 text-center"
                  >
                    <ShoppingCart className="w-12 h-12 text-muted-foreground mb-4" />
                    <p className="font-medium">Votre panier est vide</p>
                    <p className="text-sm text-muted-foreground">Ajoutez des produits pour commencer</p>
                  </motion.div>
                )}
              </AnimatePresence>
            </div>

            {/* Footer */}
            {items.length > 0 && (
              <div className="p-4 border-t space-y-4">
                <div className="flex items-center justify-between font-semibold">
                  <span>Total</span>
                  <span className="text-xl">{total}€</span>
                </div>

                <div className="space-y-2 text-sm text-muted-foreground">
                  <div className="flex items-center gap-2">
                    <Truck className="w-4 h-4" />
                    Livraison gratuite à partir de 50€
                  </div>
                  <div className="flex items-center gap-2">
                    <Shield className="w-4 h-4" />
                    Paiement sécurisé
                  </div>
                </div>

                <motion.button
                  whileHover={{ scale: 1.02 }}
                  whileTap={{ scale: 0.98 }}
                  className="w-full py-3 rounded-xl bg-primary text-primary-foreground font-semibold"
                >
                  Commander · {total}€
                </motion.button>
              </div>
            )}
          </motion.div>
        </>
      )}
    </AnimatePresence>
  )
}

export default function EcommerceDemo() {
  const [cart, setCart] = useState([])
  const [cartOpen, setCartOpen] = useState(false)
  const [selectedCategory, setSelectedCategory] = useState('Tous')
  const [searchQuery, setSearchQuery] = useState('')

  const addToCart = (product) => {
    setCart(prev => {
      const existing = prev.find(item => item.id === product.id)
      if (existing) {
        return prev.map(item =>
          item.id === product.id
            ? { ...item, quantity: item.quantity + 1 }
            : item
        )
      }
      return [...prev, { ...product, quantity: 1 }]
    })
    setCartOpen(true)
  }

  const updateQuantity = (id, quantity) => {
    if (quantity <= 0) {
      setCart(prev => prev.filter(item => item.id !== id))
    } else {
      setCart(prev => prev.map(item =>
        item.id === id ? { ...item, quantity } : item
      ))
    }
  }

  const removeFromCart = (id) => {
    setCart(prev => prev.filter(item => item.id !== id))
  }

  const cartCount = cart.reduce((sum, item) => sum + item.quantity, 0)

  return (
    <div className="space-y-8">
      {/* Header */}
      <motion.div
        initial={{ opacity: 0, y: -20 }}
        animate={{ opacity: 1, y: 0 }}
        className="flex flex-col md:flex-row md:items-center justify-between gap-4"
      >
        <div>
          <h1 className="text-3xl font-bold flex items-center gap-2">
            <Sparkles className="w-8 h-8 text-primary" />
            Boutique
          </h1>
          <p className="text-muted-foreground">Découvrez notre sélection premium</p>
        </div>

        <div className="flex items-center gap-3">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
            <input
              type="text"
              placeholder="Rechercher..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="pl-10 pr-4 py-2 rounded-lg border bg-background focus:ring-2 focus:ring-primary/20 outline-none w-48 md:w-64"
            />
          </div>

          <motion.button
            whileHover={{ scale: 1.05 }}
            whileTap={{ scale: 0.95 }}
            onClick={() => setCartOpen(true)}
            className="relative p-3 rounded-xl border hover:bg-muted transition-colors"
          >
            <ShoppingCart className="w-5 h-5" />
            {cartCount > 0 && (
              <motion.span
                initial={{ scale: 0 }}
                animate={{ scale: 1 }}
                className="absolute -top-1 -right-1 w-5 h-5 bg-primary text-primary-foreground rounded-full text-xs flex items-center justify-center font-medium"
              >
                {cartCount}
              </motion.span>
            )}
          </motion.button>
        </div>
      </motion.div>

      {/* Features */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.1 }}
        className="grid grid-cols-3 gap-4"
      >
        {[
          { icon: Truck, text: 'Livraison gratuite dès 50€' },
          { icon: Package, text: 'Retours gratuits 30 jours' },
          { icon: Shield, text: 'Paiement 100% sécurisé' },
        ].map((feature, i) => (
          <div key={i} className="flex items-center justify-center gap-2 p-3 rounded-xl bg-muted/50 text-sm">
            <feature.icon className="w-4 h-4 text-primary" />
            <span className="hidden md:inline">{feature.text}</span>
          </div>
        ))}
      </motion.div>

      {/* Categories */}
      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 0.2 }}
        className="flex gap-2 overflow-x-auto pb-2"
      >
        {categories.map((category) => (
          <button
            key={category}
            onClick={() => setSelectedCategory(category)}
            className={`px-4 py-2 rounded-full text-sm font-medium whitespace-nowrap transition-colors ${
              selectedCategory === category
                ? 'bg-primary text-primary-foreground'
                : 'bg-muted hover:bg-muted/80'
            }`}
          >
            {category}
          </button>
        ))}
      </motion.div>

      {/* Products Grid */}
      <div className="grid sm:grid-cols-2 lg:grid-cols-4 gap-6">
        {products.map((product) => (
          <ProductCard
            key={product.id}
            product={product}
            onAddToCart={addToCart}
          />
        ))}
      </div>

      {/* Cart Panel */}
      <ShoppingCartPanel
        items={cart}
        isOpen={cartOpen}
        onClose={() => setCartOpen(false)}
        onUpdateQuantity={updateQuantity}
        onRemove={removeFromCart}
      />
    </div>
  )
}

