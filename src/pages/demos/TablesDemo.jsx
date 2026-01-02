import { useState, useMemo } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import {
  Search, ChevronDown, ChevronUp, ChevronLeft, ChevronRight,
  MoreHorizontal, Edit, Trash2, Eye, Download, Filter,
  ArrowUpDown, Check, X, Users, Mail, Phone, MapPin,
  TrendingUp, TrendingDown, Minus, Star, Package
} from 'lucide-react'

// Sample data
const usersData = [
  { id: 1, name: 'Marie Dupont', email: 'marie@example.com', role: 'Admin', status: 'active', avatar: 'MD', joined: '2024-01-15' },
  { id: 2, name: 'Pierre Martin', email: 'pierre@example.com', role: 'User', status: 'active', avatar: 'PM', joined: '2024-02-20' },
  { id: 3, name: 'Sophie Bernard', email: 'sophie@example.com', role: 'Editor', status: 'inactive', avatar: 'SB', joined: '2024-03-10' },
  { id: 4, name: 'Lucas Petit', email: 'lucas@example.com', role: 'User', status: 'active', avatar: 'LP', joined: '2024-04-05' },
  { id: 5, name: 'Emma Richard', email: 'emma@example.com', role: 'Admin', status: 'pending', avatar: 'ER', joined: '2024-05-12' },
  { id: 6, name: 'Thomas Dubois', email: 'thomas@example.com', role: 'User', status: 'active', avatar: 'TD', joined: '2024-06-18' },
  { id: 7, name: 'Léa Bernard', email: 'lea@example.com', role: 'Editor', status: 'active', avatar: 'LB', joined: '2024-07-22' },
  { id: 8, name: 'Hugo Moreau', email: 'hugo@example.com', role: 'User', status: 'inactive', avatar: 'HM', joined: '2024-08-30' },
]

const productsData = [
  { id: 1, name: 'MacBook Pro 16"', category: 'Laptop', price: 2499, stock: 45, trend: 'up', rating: 4.8 },
  { id: 2, name: 'iPhone 15 Pro', category: 'Phone', price: 1199, stock: 120, trend: 'up', rating: 4.9 },
  { id: 3, name: 'AirPods Pro', category: 'Audio', price: 279, stock: 200, trend: 'stable', rating: 4.7 },
  { id: 4, name: 'iPad Air', category: 'Tablet', price: 799, stock: 80, trend: 'down', rating: 4.6 },
  { id: 5, name: 'Apple Watch', category: 'Wearable', price: 449, stock: 150, trend: 'up', rating: 4.5 },
  { id: 6, name: 'Magic Keyboard', category: 'Accessory', price: 299, stock: 30, trend: 'down', rating: 4.3 },
]

const salesData = [
  { month: 'Janvier', revenue: 45000, orders: 234, growth: 12.5 },
  { month: 'Février', revenue: 52000, orders: 287, growth: 15.6 },
  { month: 'Mars', revenue: 48000, orders: 256, growth: -7.7 },
  { month: 'Avril', revenue: 61000, orders: 312, growth: 27.1 },
  { month: 'Mai', revenue: 55000, orders: 298, growth: -9.8 },
  { month: 'Juin', revenue: 67000, orders: 345, growth: 21.8 },
]

// 1. Basic Table with Sorting
function BasicTable() {
  const [sortConfig, setSortConfig] = useState({ key: null, direction: 'asc' })

  const sortedUsers = useMemo(() => {
    if (!sortConfig.key) return usersData

    return [...usersData].sort((a, b) => {
      if (a[sortConfig.key] < b[sortConfig.key]) {
        return sortConfig.direction === 'asc' ? -1 : 1
      }
      if (a[sortConfig.key] > b[sortConfig.key]) {
        return sortConfig.direction === 'asc' ? 1 : -1
      }
      return 0
    })
  }, [sortConfig])

  const handleSort = (key) => {
    setSortConfig(prev => ({
      key,
      direction: prev.key === key && prev.direction === 'asc' ? 'desc' : 'asc'
    }))
  }

  const SortIcon = ({ column }) => {
    if (sortConfig.key !== column) return <ArrowUpDown className="w-4 h-4 text-muted-foreground" />
    return sortConfig.direction === 'asc'
      ? <ChevronUp className="w-4 h-4 text-primary" />
      : <ChevronDown className="w-4 h-4 text-primary" />
  }

  return (
    <div className="border rounded-xl overflow-hidden">
      <div className="overflow-x-auto">
        <table className="w-full">
          <thead className="bg-muted/50">
            <tr>
              {['name', 'email', 'role', 'status', 'joined'].map((col) => (
                <th
                  key={col}
                  onClick={() => handleSort(col)}
                  className="px-4 py-3 text-left text-sm font-medium cursor-pointer hover:bg-muted transition-colors"
                >
                  <div className="flex items-center gap-2">
                    {col.charAt(0).toUpperCase() + col.slice(1)}
                    <SortIcon column={col} />
                  </div>
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {sortedUsers.map((user, i) => (
              <motion.tr
                key={user.id}
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                transition={{ delay: i * 0.05 }}
                className="border-t hover:bg-muted/30 transition-colors"
              >
                <td className="px-4 py-3">
                  <div className="flex items-center gap-3">
                    <div className="w-8 h-8 rounded-full bg-gradient-to-br from-primary to-purple-600 flex items-center justify-center text-white text-xs font-medium">
                      {user.avatar}
                    </div>
                    <span className="font-medium">{user.name}</span>
                  </div>
                </td>
                <td className="px-4 py-3 text-muted-foreground">{user.email}</td>
                <td className="px-4 py-3">
                  <span className="px-2 py-1 text-xs rounded-full bg-primary/10 text-primary">
                    {user.role}
                  </span>
                </td>
                <td className="px-4 py-3">
                  <span className={`px-2 py-1 text-xs rounded-full ${
                    user.status === 'active' ? 'bg-green-500/10 text-green-600' :
                    user.status === 'inactive' ? 'bg-red-500/10 text-red-600' :
                    'bg-yellow-500/10 text-yellow-600'
                  }`}>
                    {user.status}
                  </span>
                </td>
                <td className="px-4 py-3 text-muted-foreground">{user.joined}</td>
              </motion.tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )
}

// 2. Table with Selection & Actions
function SelectableTable() {
  const [selected, setSelected] = useState([])
  const [searchQuery, setSearchQuery] = useState('')

  const filteredUsers = usersData.filter(user =>
    user.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
    user.email.toLowerCase().includes(searchQuery.toLowerCase())
  )

  const toggleSelect = (id) => {
    setSelected(prev =>
      prev.includes(id) ? prev.filter(i => i !== id) : [...prev, id]
    )
  }

  const toggleSelectAll = () => {
    setSelected(prev =>
      prev.length === filteredUsers.length ? [] : filteredUsers.map(u => u.id)
    )
  }

  return (
    <div className="space-y-4">
      {/* Toolbar */}
      <div className="flex items-center justify-between gap-4">
        <div className="relative flex-1 max-w-xs">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
          <input
            type="text"
            placeholder="Rechercher..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full pl-10 pr-4 py-2 rounded-lg border bg-background focus:ring-2 focus:ring-primary/20 outline-none"
          />
        </div>

        <AnimatePresence>
          {selected.length > 0 && (
            <motion.div
              initial={{ opacity: 0, scale: 0.9 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.9 }}
              className="flex items-center gap-2"
            >
              <span className="text-sm text-muted-foreground">
                {selected.length} sélectionné(s)
              </span>
              <button className="p-2 rounded-lg hover:bg-red-500/10 text-red-500 transition-colors">
                <Trash2 className="w-4 h-4" />
              </button>
              <button className="p-2 rounded-lg hover:bg-muted transition-colors">
                <Download className="w-4 h-4" />
              </button>
            </motion.div>
          )}
        </AnimatePresence>
      </div>

      {/* Table */}
      <div className="border rounded-xl overflow-hidden">
        <table className="w-full">
          <thead className="bg-muted/50">
            <tr>
              <th className="px-4 py-3 w-12">
                <input
                  type="checkbox"
                  checked={selected.length === filteredUsers.length && filteredUsers.length > 0}
                  onChange={toggleSelectAll}
                  className="rounded border-muted"
                />
              </th>
              <th className="px-4 py-3 text-left text-sm font-medium">Utilisateur</th>
              <th className="px-4 py-3 text-left text-sm font-medium">Rôle</th>
              <th className="px-4 py-3 text-left text-sm font-medium">Statut</th>
              <th className="px-4 py-3 text-right text-sm font-medium">Actions</th>
            </tr>
          </thead>
          <tbody>
            {filteredUsers.map((user) => (
              <tr
                key={user.id}
                className={`border-t transition-colors ${
                  selected.includes(user.id) ? 'bg-primary/5' : 'hover:bg-muted/30'
                }`}
              >
                <td className="px-4 py-3">
                  <input
                    type="checkbox"
                    checked={selected.includes(user.id)}
                    onChange={() => toggleSelect(user.id)}
                    className="rounded border-muted"
                  />
                </td>
                <td className="px-4 py-3">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 rounded-full bg-gradient-to-br from-primary to-purple-600 flex items-center justify-center text-white text-sm font-medium">
                      {user.avatar}
                    </div>
                    <div>
                      <p className="font-medium">{user.name}</p>
                      <p className="text-sm text-muted-foreground">{user.email}</p>
                    </div>
                  </div>
                </td>
                <td className="px-4 py-3">
                  <span className="px-2 py-1 text-xs rounded-full bg-primary/10 text-primary">
                    {user.role}
                  </span>
                </td>
                <td className="px-4 py-3">
                  <div className="flex items-center gap-2">
                    <div className={`w-2 h-2 rounded-full ${
                      user.status === 'active' ? 'bg-green-500' :
                      user.status === 'inactive' ? 'bg-red-500' : 'bg-yellow-500'
                    }`} />
                    <span className="text-sm capitalize">{user.status}</span>
                  </div>
                </td>
                <td className="px-4 py-3">
                  <div className="flex items-center justify-end gap-1">
                    <button className="p-2 rounded-lg hover:bg-muted transition-colors">
                      <Eye className="w-4 h-4 text-muted-foreground" />
                    </button>
                    <button className="p-2 rounded-lg hover:bg-muted transition-colors">
                      <Edit className="w-4 h-4 text-muted-foreground" />
                    </button>
                    <button className="p-2 rounded-lg hover:bg-red-500/10 transition-colors">
                      <Trash2 className="w-4 h-4 text-red-500" />
                    </button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )
}

// 3. Product Table with Visual Elements
function ProductTable() {
  const getTrendIcon = (trend) => {
    if (trend === 'up') return <TrendingUp className="w-4 h-4 text-green-500" />
    if (trend === 'down') return <TrendingDown className="w-4 h-4 text-red-500" />
    return <Minus className="w-4 h-4 text-muted-foreground" />
  }

  const getStockStatus = (stock) => {
    if (stock > 100) return { label: 'En stock', color: 'bg-green-500/10 text-green-600' }
    if (stock > 30) return { label: 'Stock limité', color: 'bg-yellow-500/10 text-yellow-600' }
    return { label: 'Stock faible', color: 'bg-red-500/10 text-red-600' }
  }

  return (
    <div className="border rounded-xl overflow-hidden">
      <table className="w-full">
        <thead className="bg-muted/50">
          <tr>
            <th className="px-4 py-3 text-left text-sm font-medium">Produit</th>
            <th className="px-4 py-3 text-left text-sm font-medium">Catégorie</th>
            <th className="px-4 py-3 text-right text-sm font-medium">Prix</th>
            <th className="px-4 py-3 text-center text-sm font-medium">Stock</th>
            <th className="px-4 py-3 text-center text-sm font-medium">Tendance</th>
            <th className="px-4 py-3 text-center text-sm font-medium">Note</th>
          </tr>
        </thead>
        <tbody>
          {productsData.map((product, i) => {
            const stockStatus = getStockStatus(product.stock)
            return (
              <motion.tr
                key={product.id}
                initial={{ opacity: 0, x: -20 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ delay: i * 0.1 }}
                className="border-t hover:bg-muted/30 transition-colors"
              >
                <td className="px-4 py-4">
                  <div className="flex items-center gap-3">
                    <div className="w-12 h-12 rounded-lg bg-gradient-to-br from-muted to-muted/50 flex items-center justify-center">
                      <Package className="w-6 h-6 text-muted-foreground" />
                    </div>
                    <span className="font-medium">{product.name}</span>
                  </div>
                </td>
                <td className="px-4 py-4">
                  <span className="px-3 py-1 text-xs rounded-full bg-muted">
                    {product.category}
                  </span>
                </td>
                <td className="px-4 py-4 text-right font-semibold">
                  {product.price.toLocaleString()}€
                </td>
                <td className="px-4 py-4">
                  <div className="flex flex-col items-center gap-1">
                    <span className="font-medium">{product.stock}</span>
                    <span className={`px-2 py-0.5 text-xs rounded-full ${stockStatus.color}`}>
                      {stockStatus.label}
                    </span>
                  </div>
                </td>
                <td className="px-4 py-4">
                  <div className="flex justify-center">
                    {getTrendIcon(product.trend)}
                  </div>
                </td>
                <td className="px-4 py-4">
                  <div className="flex items-center justify-center gap-1">
                    <Star className="w-4 h-4 fill-yellow-400 text-yellow-400" />
                    <span className="font-medium">{product.rating}</span>
                  </div>
                </td>
              </motion.tr>
            )
          })}
        </tbody>
      </table>
    </div>
  )
}

// 4. Sales Table with Progress Bars
function SalesTable() {
  const maxRevenue = Math.max(...salesData.map(d => d.revenue))

  return (
    <div className="border rounded-xl overflow-hidden">
      <table className="w-full">
        <thead className="bg-muted/50">
          <tr>
            <th className="px-4 py-3 text-left text-sm font-medium">Mois</th>
            <th className="px-4 py-3 text-left text-sm font-medium">Revenus</th>
            <th className="px-4 py-3 text-center text-sm font-medium">Commandes</th>
            <th className="px-4 py-3 text-right text-sm font-medium">Croissance</th>
          </tr>
        </thead>
        <tbody>
          {salesData.map((row, i) => (
            <motion.tr
              key={row.month}
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ delay: i * 0.1 }}
              className="border-t hover:bg-muted/30 transition-colors"
            >
              <td className="px-4 py-4 font-medium">{row.month}</td>
              <td className="px-4 py-4 w-1/3">
                <div className="space-y-1">
                  <div className="flex items-center justify-between text-sm">
                    <span className="font-semibold">{row.revenue.toLocaleString()}€</span>
                  </div>
                  <div className="h-2 rounded-full bg-muted overflow-hidden">
                    <motion.div
                      initial={{ width: 0 }}
                      animate={{ width: `${(row.revenue / maxRevenue) * 100}%` }}
                      transition={{ delay: i * 0.1, duration: 0.5 }}
                      className="h-full rounded-full bg-gradient-to-r from-primary to-purple-600"
                    />
                  </div>
                </div>
              </td>
              <td className="px-4 py-4 text-center">
                <span className="px-3 py-1 rounded-full bg-muted font-medium">
                  {row.orders}
                </span>
              </td>
              <td className="px-4 py-4 text-right">
                <span className={`inline-flex items-center gap-1 font-semibold ${
                  row.growth >= 0 ? 'text-green-600' : 'text-red-600'
                }`}>
                  {row.growth >= 0 ? (
                    <TrendingUp className="w-4 h-4" />
                  ) : (
                    <TrendingDown className="w-4 h-4" />
                  )}
                  {row.growth >= 0 ? '+' : ''}{row.growth}%
                </span>
              </td>
            </motion.tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}

// 5. Paginated Table
function PaginatedTable() {
  const [currentPage, setCurrentPage] = useState(1)
  const itemsPerPage = 4
  const totalPages = Math.ceil(usersData.length / itemsPerPage)

  const paginatedUsers = usersData.slice(
    (currentPage - 1) * itemsPerPage,
    currentPage * itemsPerPage
  )

  return (
    <div className="space-y-4">
      <div className="border rounded-xl overflow-hidden">
        <table className="w-full">
          <thead className="bg-muted/50">
            <tr>
              <th className="px-4 py-3 text-left text-sm font-medium">Utilisateur</th>
              <th className="px-4 py-3 text-left text-sm font-medium">Email</th>
              <th className="px-4 py-3 text-left text-sm font-medium">Rôle</th>
              <th className="px-4 py-3 text-left text-sm font-medium">Date d'inscription</th>
            </tr>
          </thead>
          <tbody>
            <AnimatePresence mode="wait">
              {paginatedUsers.map((user) => (
                <motion.tr
                  key={user.id}
                  initial={{ opacity: 0, y: 10 }}
                  animate={{ opacity: 1, y: 0 }}
                  exit={{ opacity: 0, y: -10 }}
                  className="border-t hover:bg-muted/30 transition-colors"
                >
                  <td className="px-4 py-3">
                    <div className="flex items-center gap-3">
                      <div className="w-8 h-8 rounded-full bg-gradient-to-br from-primary to-purple-600 flex items-center justify-center text-white text-xs font-medium">
                        {user.avatar}
                      </div>
                      <span className="font-medium">{user.name}</span>
                    </div>
                  </td>
                  <td className="px-4 py-3 text-muted-foreground">{user.email}</td>
                  <td className="px-4 py-3">
                    <span className="px-2 py-1 text-xs rounded-full bg-primary/10 text-primary">
                      {user.role}
                    </span>
                  </td>
                  <td className="px-4 py-3 text-muted-foreground">{user.joined}</td>
                </motion.tr>
              ))}
            </AnimatePresence>
          </tbody>
        </table>
      </div>

      {/* Pagination */}
      <div className="flex items-center justify-between">
        <p className="text-sm text-muted-foreground">
          Affichage de {(currentPage - 1) * itemsPerPage + 1} à {Math.min(currentPage * itemsPerPage, usersData.length)} sur {usersData.length} résultats
        </p>

        <div className="flex items-center gap-2">
          <button
            onClick={() => setCurrentPage(p => Math.max(1, p - 1))}
            disabled={currentPage === 1}
            className="p-2 rounded-lg border hover:bg-muted transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
          >
            <ChevronLeft className="w-4 h-4" />
          </button>

          {[...Array(totalPages)].map((_, i) => (
            <button
              key={i}
              onClick={() => setCurrentPage(i + 1)}
              className={`w-8 h-8 rounded-lg text-sm font-medium transition-colors ${
                currentPage === i + 1
                  ? 'bg-primary text-primary-foreground'
                  : 'hover:bg-muted'
              }`}
            >
              {i + 1}
            </button>
          ))}

          <button
            onClick={() => setCurrentPage(p => Math.min(totalPages, p + 1))}
            disabled={currentPage === totalPages}
            className="p-2 rounded-lg border hover:bg-muted transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
          >
            <ChevronRight className="w-4 h-4" />
          </button>
        </div>
      </div>
    </div>
  )
}

// 6. Expandable Rows Table
function ExpandableTable() {
  const [expandedRows, setExpandedRows] = useState([])

  const toggleExpand = (id) => {
    setExpandedRows(prev =>
      prev.includes(id) ? prev.filter(i => i !== id) : [...prev, id]
    )
  }

  return (
    <div className="border rounded-xl overflow-hidden">
      <table className="w-full">
        <thead className="bg-muted/50">
          <tr>
            <th className="px-4 py-3 w-12"></th>
            <th className="px-4 py-3 text-left text-sm font-medium">Produit</th>
            <th className="px-4 py-3 text-left text-sm font-medium">Catégorie</th>
            <th className="px-4 py-3 text-right text-sm font-medium">Prix</th>
            <th className="px-4 py-3 text-center text-sm font-medium">Stock</th>
          </tr>
        </thead>
        <tbody>
          {productsData.map((product) => (
            <>
              <tr
                key={product.id}
                onClick={() => toggleExpand(product.id)}
                className="border-t hover:bg-muted/30 transition-colors cursor-pointer"
              >
                <td className="px-4 py-3">
                  <motion.div
                    animate={{ rotate: expandedRows.includes(product.id) ? 180 : 0 }}
                    transition={{ duration: 0.2 }}
                  >
                    <ChevronDown className="w-4 h-4 text-muted-foreground" />
                  </motion.div>
                </td>
                <td className="px-4 py-3 font-medium">{product.name}</td>
                <td className="px-4 py-3">
                  <span className="px-3 py-1 text-xs rounded-full bg-muted">
                    {product.category}
                  </span>
                </td>
                <td className="px-4 py-3 text-right font-semibold">{product.price}€</td>
                <td className="px-4 py-3 text-center">{product.stock}</td>
              </tr>
              <AnimatePresence>
                {expandedRows.includes(product.id) && (
                  <motion.tr
                    key={`${product.id}-expanded`}
                    initial={{ opacity: 0, height: 0 }}
                    animate={{ opacity: 1, height: 'auto' }}
                    exit={{ opacity: 0, height: 0 }}
                  >
                    <td colSpan={5} className="px-4 py-4 bg-muted/30">
                      <div className="grid grid-cols-3 gap-4 pl-8">
                        <div>
                          <p className="text-sm text-muted-foreground">Note client</p>
                          <div className="flex items-center gap-1 mt-1">
                            <Star className="w-4 h-4 fill-yellow-400 text-yellow-400" />
                            <span className="font-medium">{product.rating}/5</span>
                          </div>
                        </div>
                        <div>
                          <p className="text-sm text-muted-foreground">Tendance</p>
                          <div className="flex items-center gap-1 mt-1">
                            {product.trend === 'up' ? (
                              <TrendingUp className="w-4 h-4 text-green-500" />
                            ) : product.trend === 'down' ? (
                              <TrendingDown className="w-4 h-4 text-red-500" />
                            ) : (
                              <Minus className="w-4 h-4" />
                            )}
                            <span className="font-medium capitalize">{product.trend}</span>
                          </div>
                        </div>
                        <div>
                          <p className="text-sm text-muted-foreground">Actions</p>
                          <div className="flex items-center gap-2 mt-1">
                            <button className="px-3 py-1 text-xs rounded-lg bg-primary text-primary-foreground">
                              Modifier
                            </button>
                            <button className="px-3 py-1 text-xs rounded-lg border hover:bg-muted">
                              Détails
                            </button>
                          </div>
                        </div>
                      </div>
                    </td>
                  </motion.tr>
                )}
              </AnimatePresence>
            </>
          ))}
        </tbody>
      </table>
    </div>
  )
}

// Main Component
export default function TablesDemo() {
  return (
    <div className="max-w-6xl mx-auto space-y-12">
      {/* Header */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        className="text-center space-y-4"
      >
        <h1 className="text-3xl font-bold">Tableaux de Données</h1>
        <p className="text-muted-foreground max-w-2xl mx-auto">
          Une collection de tableaux modernes avec tri, sélection, pagination,
          lignes extensibles et indicateurs visuels.
        </p>
      </motion.div>

      {/* 1. Basic Table */}
      <section className="space-y-4">
        <div>
          <h2 className="text-xl font-semibold">1. Tableau avec Tri</h2>
          <p className="text-sm text-muted-foreground">Cliquez sur les en-têtes pour trier</p>
        </div>
        <BasicTable />
      </section>

      {/* 2. Selectable Table */}
      <section className="space-y-4">
        <div>
          <h2 className="text-xl font-semibold">2. Tableau avec Sélection & Actions</h2>
          <p className="text-sm text-muted-foreground">Sélectionnez des lignes pour voir les actions groupées</p>
        </div>
        <SelectableTable />
      </section>

      {/* 3. Product Table */}
      <section className="space-y-4">
        <div>
          <h2 className="text-xl font-semibold">3. Tableau Produits</h2>
          <p className="text-sm text-muted-foreground">Avec indicateurs visuels de stock et tendances</p>
        </div>
        <ProductTable />
      </section>

      {/* 4. Sales Table */}
      <section className="space-y-4">
        <div>
          <h2 className="text-xl font-semibold">4. Tableau des Ventes</h2>
          <p className="text-sm text-muted-foreground">Avec barres de progression animées</p>
        </div>
        <SalesTable />
      </section>

      {/* 5. Paginated Table */}
      <section className="space-y-4">
        <div>
          <h2 className="text-xl font-semibold">5. Tableau Paginé</h2>
          <p className="text-sm text-muted-foreground">Navigation entre les pages avec animations</p>
        </div>
        <PaginatedTable />
      </section>

      {/* 6. Expandable Table */}
      <section className="space-y-4">
        <div>
          <h2 className="text-xl font-semibold">6. Tableau Extensible</h2>
          <p className="text-sm text-muted-foreground">Cliquez sur une ligne pour voir les détails</p>
        </div>
        <ExpandableTable />
      </section>
    </div>
  )
}

