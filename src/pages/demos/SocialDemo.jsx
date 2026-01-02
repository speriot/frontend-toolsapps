import { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import {
  Heart, MessageCircle, Share2, Bookmark, MoreHorizontal,
  Image as ImageIcon, Smile, MapPin, Users, Verified,
  ChevronLeft, ChevronRight, Play, Volume2, VolumeX
} from 'lucide-react'

const posts = [
  {
    id: 1,
    author: {
      name: 'Sophie Martin',
      username: '@sophiemartin',
      avatar: 'SM',
      verified: true
    },
    content: 'Tellement heureuse de partager ce nouveau projet avec vous ! 🚀✨ Des mois de travail acharné, et le résultat est là. Qu\'en pensez-vous ?',
    images: [
      'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=800&h=600&fit=crop',
      'https://images.unsplash.com/photo-1634017839464-5c339bbe3c5a?w=800&h=600&fit=crop',
    ],
    likes: 2453,
    comments: 128,
    shares: 89,
    time: '2h',
    liked: false,
    saved: false
  },
  {
    id: 2,
    author: {
      name: 'Thomas Dubois',
      username: '@thomasd',
      avatar: 'TD',
      verified: false
    },
    content: 'Le coucher de soleil ce soir était incroyable 🌅 Parfois il suffit de lever les yeux pour voir la beauté du monde.',
    images: [
      'https://images.unsplash.com/photo-1495616811223-4d98c6e9c869?w=800&h=600&fit=crop',
    ],
    likes: 892,
    comments: 45,
    shares: 23,
    time: '5h',
    liked: true,
    saved: true
  },
  {
    id: 3,
    author: {
      name: 'Léa Bernard',
      username: '@leabernard',
      avatar: 'LB',
      verified: true
    },
    content: 'Nouveau tutoriel disponible ! 📚 Comment créer des interfaces utilisateur modernes avec React et Framer Motion. Lien dans ma bio !',
    images: [],
    likes: 1567,
    comments: 234,
    shares: 567,
    time: '8h',
    liked: false,
    saved: false
  },
]

const stories = [
  { id: 1, name: 'Votre story', avatar: 'VS', hasStory: false, isOwn: true },
  { id: 2, name: 'Sophie', avatar: 'SM', hasStory: true, isOwn: false },
  { id: 3, name: 'Thomas', avatar: 'TD', hasStory: true, isOwn: false },
  { id: 4, name: 'Léa', avatar: 'LB', hasStory: true, isOwn: false },
  { id: 5, name: 'Pierre', avatar: 'PM', hasStory: true, isOwn: false },
  { id: 6, name: 'Emma', avatar: 'ER', hasStory: true, isOwn: false },
]

function StoryCircle({ story, index }) {
  return (
    <motion.button
      initial={{ opacity: 0, scale: 0.8 }}
      animate={{ opacity: 1, scale: 1 }}
      transition={{ delay: index * 0.05 }}
      whileHover={{ scale: 1.05 }}
      whileTap={{ scale: 0.95 }}
      className="flex flex-col items-center gap-1 flex-shrink-0"
    >
      <div className={`relative p-0.5 rounded-full ${
        story.hasStory 
          ? 'bg-gradient-to-tr from-yellow-400 via-pink-500 to-purple-600' 
          : story.isOwn 
            ? 'bg-muted' 
            : ''
      }`}>
        <div className="p-0.5 bg-background rounded-full">
          <div className="w-14 h-14 rounded-full bg-gradient-to-br from-primary/20 to-purple-600/20 flex items-center justify-center text-lg font-semibold">
            {story.avatar}
          </div>
        </div>
        {story.isOwn && (
          <div className="absolute -bottom-0.5 -right-0.5 w-6 h-6 rounded-full bg-primary flex items-center justify-center border-2 border-background">
            <span className="text-primary-foreground text-xs">+</span>
          </div>
        )}
      </div>
      <span className="text-xs truncate w-16 text-center">{story.name}</span>
    </motion.button>
  )
}

function ImageCarousel({ images }) {
  const [currentIndex, setCurrentIndex] = useState(0)

  if (images.length === 0) return null
  if (images.length === 1) {
    return (
      <motion.img
        src={images[0]}
        alt=""
        className="w-full aspect-square object-cover rounded-xl"
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
      />
    )
  }

  return (
    <div className="relative">
      <motion.img
        key={currentIndex}
        src={images[currentIndex]}
        alt=""
        className="w-full aspect-square object-cover rounded-xl"
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
      />

      {/* Navigation buttons */}
      {currentIndex > 0 && (
        <button
          onClick={() => setCurrentIndex(currentIndex - 1)}
          className="absolute left-2 top-1/2 -translate-y-1/2 w-8 h-8 rounded-full bg-background/80 backdrop-blur flex items-center justify-center shadow-lg hover:bg-background transition-colors"
        >
          <ChevronLeft className="w-5 h-5" />
        </button>
      )}
      {currentIndex < images.length - 1 && (
        <button
          onClick={() => setCurrentIndex(currentIndex + 1)}
          className="absolute right-2 top-1/2 -translate-y-1/2 w-8 h-8 rounded-full bg-background/80 backdrop-blur flex items-center justify-center shadow-lg hover:bg-background transition-colors"
        >
          <ChevronRight className="w-5 h-5" />
        </button>
      )}

      {/* Indicators */}
      <div className="absolute bottom-3 left-1/2 -translate-x-1/2 flex gap-1">
        {images.map((_, i) => (
          <div
            key={i}
            className={`w-2 h-2 rounded-full transition-colors ${
              i === currentIndex ? 'bg-white' : 'bg-white/50'
            }`}
          />
        ))}
      </div>
    </div>
  )
}

function PostCard({ post, index }) {
  const [liked, setLiked] = useState(post.liked)
  const [saved, setSaved] = useState(post.saved)
  const [likesCount, setLikesCount] = useState(post.likes)
  const [showHeart, setShowHeart] = useState(false)

  const handleDoubleTap = () => {
    if (!liked) {
      setLiked(true)
      setLikesCount(likesCount + 1)
    }
    setShowHeart(true)
    setTimeout(() => setShowHeart(false), 800)
  }

  const handleLike = () => {
    setLiked(!liked)
    setLikesCount(liked ? likesCount - 1 : likesCount + 1)
  }

  return (
    <motion.article
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ delay: index * 0.1 }}
      className="bg-card rounded-2xl border shadow-sm overflow-hidden"
    >
      {/* Header */}
      <div className="flex items-center justify-between p-4">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-full bg-gradient-to-br from-primary to-purple-600 flex items-center justify-center text-white font-medium">
            {post.author.avatar}
          </div>
          <div>
            <div className="flex items-center gap-1">
              <span className="font-semibold text-sm">{post.author.name}</span>
              {post.author.verified && (
                <Verified className="w-4 h-4 text-primary fill-primary" />
              )}
            </div>
            <span className="text-xs text-muted-foreground">{post.time}</span>
          </div>
        </div>
        <button className="p-2 rounded-full hover:bg-muted transition-colors">
          <MoreHorizontal className="w-5 h-5 text-muted-foreground" />
        </button>
      </div>

      {/* Content */}
      <div className="px-4 pb-3">
        <p className="text-sm leading-relaxed">{post.content}</p>
      </div>

      {/* Images */}
      {post.images.length > 0 && (
        <div
          className="px-4 relative"
          onDoubleClick={handleDoubleTap}
        >
          <ImageCarousel images={post.images} />

          {/* Double-tap heart animation */}
          <AnimatePresence>
            {showHeart && (
              <motion.div
                initial={{ scale: 0, opacity: 0 }}
                animate={{ scale: 1, opacity: 1 }}
                exit={{ scale: 0, opacity: 0 }}
                className="absolute inset-0 flex items-center justify-center pointer-events-none"
              >
                <Heart className="w-24 h-24 text-white fill-white drop-shadow-lg" />
              </motion.div>
            )}
          </AnimatePresence>
        </div>
      )}

      {/* Actions */}
      <div className="p-4 flex items-center justify-between">
        <div className="flex items-center gap-4">
          <motion.button
            whileTap={{ scale: 0.9 }}
            onClick={handleLike}
            className="flex items-center gap-1"
          >
            <motion.div
              animate={liked ? { scale: [1, 1.3, 1] } : {}}
              transition={{ duration: 0.3 }}
            >
              <Heart className={`w-6 h-6 ${liked ? 'fill-red-500 text-red-500' : ''}`} />
            </motion.div>
            <span className="text-sm font-medium">{likesCount.toLocaleString()}</span>
          </motion.button>

          <button className="flex items-center gap-1">
            <MessageCircle className="w-6 h-6" />
            <span className="text-sm font-medium">{post.comments}</span>
          </button>

          <button className="flex items-center gap-1">
            <Share2 className="w-6 h-6" />
            <span className="text-sm font-medium">{post.shares}</span>
          </button>
        </div>

        <motion.button
          whileTap={{ scale: 0.9 }}
          onClick={() => setSaved(!saved)}
        >
          <Bookmark className={`w-6 h-6 ${saved ? 'fill-foreground' : ''}`} />
        </motion.button>
      </div>
    </motion.article>
  )
}

function CreatePostCard() {
  const [content, setContent] = useState('')

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      className="bg-card rounded-2xl border shadow-sm p-4"
    >
      <div className="flex gap-3">
        <div className="w-10 h-10 rounded-full bg-gradient-to-br from-primary to-purple-600 flex items-center justify-center text-white font-medium flex-shrink-0">
          VS
        </div>
        <div className="flex-1">
          <textarea
            placeholder="Quoi de neuf ?"
            value={content}
            onChange={(e) => setContent(e.target.value)}
            className="w-full resize-none bg-transparent border-none outline-none text-sm placeholder:text-muted-foreground"
            rows={2}
          />

          <div className="flex items-center justify-between mt-3 pt-3 border-t">
            <div className="flex items-center gap-2">
              <motion.button
                whileHover={{ scale: 1.1 }}
                whileTap={{ scale: 0.9 }}
                className="p-2 rounded-full hover:bg-muted transition-colors text-primary"
              >
                <ImageIcon className="w-5 h-5" />
              </motion.button>
              <motion.button
                whileHover={{ scale: 1.1 }}
                whileTap={{ scale: 0.9 }}
                className="p-2 rounded-full hover:bg-muted transition-colors text-primary"
              >
                <Smile className="w-5 h-5" />
              </motion.button>
              <motion.button
                whileHover={{ scale: 1.1 }}
                whileTap={{ scale: 0.9 }}
                className="p-2 rounded-full hover:bg-muted transition-colors text-primary"
              >
                <MapPin className="w-5 h-5" />
              </motion.button>
            </div>

            <motion.button
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.98 }}
              disabled={!content.trim()}
              className="px-4 py-2 rounded-full bg-primary text-primary-foreground text-sm font-medium disabled:opacity-50 disabled:cursor-not-allowed"
            >
              Publier
            </motion.button>
          </div>
        </div>
      </div>
    </motion.div>
  )
}

function SuggestedUsers() {
  const users = [
    { name: 'Emma Richard', username: '@emmar', avatar: 'ER', followers: '12.5K' },
    { name: 'Lucas Petit', username: '@lucasp', avatar: 'LP', followers: '8.2K' },
    { name: 'Marie Dupont', username: '@maried', avatar: 'MD', followers: '25.1K' },
  ]

  return (
    <motion.div
      initial={{ opacity: 0, x: 20 }}
      animate={{ opacity: 1, x: 0 }}
      transition={{ delay: 0.3 }}
      className="bg-card rounded-2xl border shadow-sm p-4"
    >
      <h3 className="font-semibold mb-4">Suggestions pour vous</h3>
      <div className="space-y-4">
        {users.map((user, i) => (
          <motion.div
            key={user.username}
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.4 + i * 0.1 }}
            className="flex items-center gap-3"
          >
            <div className="w-10 h-10 rounded-full bg-gradient-to-br from-primary/20 to-purple-600/20 flex items-center justify-center font-medium">
              {user.avatar}
            </div>
            <div className="flex-1 min-w-0">
              <p className="font-medium text-sm truncate">{user.name}</p>
              <p className="text-xs text-muted-foreground">{user.followers} followers</p>
            </div>
            <motion.button
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.98 }}
              className="px-3 py-1.5 text-xs font-medium rounded-full bg-primary text-primary-foreground"
            >
              Suivre
            </motion.button>
          </motion.div>
        ))}
      </div>
    </motion.div>
  )
}

export default function SocialDemo() {
  return (
    <div className="max-w-6xl mx-auto">
      <div className="grid lg:grid-cols-3 gap-6">
        {/* Main Feed */}
        <div className="lg:col-span-2 space-y-6">
          {/* Stories */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            className="bg-card rounded-2xl border shadow-sm p-4"
          >
            <div className="flex gap-4 overflow-x-auto scrollbar-hide pb-2">
              {stories.map((story, i) => (
                <StoryCircle key={story.id} story={story} index={i} />
              ))}
            </div>
          </motion.div>

          {/* Create Post */}
          <CreatePostCard />

          {/* Posts */}
          {posts.map((post, i) => (
            <PostCard key={post.id} post={post} index={i} />
          ))}
        </div>

        {/* Sidebar */}
        <div className="hidden lg:block space-y-6">
          <SuggestedUsers />

          <motion.div
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ delay: 0.5 }}
            className="text-xs text-muted-foreground space-y-2"
          >
            <p>À propos · Aide · Presse · API · Emplois · Confidentialité · Conditions</p>
            <p>© 2024 ToolsApps Social Demo</p>
          </motion.div>
        </div>
      </div>
    </div>
  )
}

