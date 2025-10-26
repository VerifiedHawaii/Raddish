<div align="center">

```
╔═══════════════════════════════════════════════════════════════════════════╗
║                                                                           ║
║    ██████╗   █████╗ ██████╗ ██████╗ ██╗███████╗██╗  ██╗                  ║
║    ██╔══██╗██╔══██╗██╔══██╗██╔══██╗██║██╔════╝██║  ██║                  ║
║    ██████╔╝███████║██║  ██║██║  ██║██║███████╗███████║                  ║
║    ██╔══██╗██╔══██║██║  ██║██║  ██║██║╚════██║██╔══██║                  ║
║    ██║  ██║██║  ██║██████╔╝██████╔╝██║███████║██║  ██║                  ║
║    ╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝ ╚═════╝ ╚═╝╚══════╝╚═╝  ╚═╝                  ║
║                                                                           ║
║         Redis-like In-Memory Cache & Networking for Roblox               ║
║                                                                           ║
╚═══════════════════════════════════════════════════════════════════════════╝
```

**⚡ Lightning-fast in-memory caching** • **🔄 Cross-server events** • **🌐 External APIs**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Roblox](https://img.shields.io/badge/Roblox-Ready-00A2FF?logo=roblox)](https://www.roblox.com/)
[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](https://github.com/VerifiedHawaii/Raddish/releases)
[![Documentation](https://img.shields.io/badge/docs-hawaiian.gg-green.svg)](https://docs.hawaiian.gg/raddish/getting-started)

[Features](#-features) • [Installation](#-installation) • [Quick Start](#-quick-start) • [Documentation](#-documentation) • [Contributing](#-contributing)

</div>

---

## 🎯 What is Raddish?

Raddish is a **Redis-like caching and networking system** built specifically for Roblox. It solves the biggest pain points of game development:

- **DataStore is slow** (100-300ms per call) → Raddish caches everything in memory (<1ms)
- **No cross-server communication** → Raddish provides Pub/Sub events
- **External APIs are hard** → Raddish handles caching, retries, and rate limiting
- **Complex data structures** → Raddish provides Hashes, Lists, Sets, and Sorted Sets

### Why Raddish?

| Traditional Approach | With Raddish | Improvement |
|---------------------|--------------|-------------|
| 100-300ms per DataStore call | <1ms from cache | **100-300x faster** |
| No cross-server events | Real-time Pub/Sub | **New capability!** |
| Manual API handling | Auto-caching & retry | **50-500x faster** |
| Basic key-value only | Redis data structures | **More powerful** |

## ✨ Features

<table>
<tr>
<td width="50%">

### 🚀 Core Features
- ⚡ **In-Memory Cache** - 100-1000x faster than DataStore
- 🔄 **Pub/Sub Events** - Cross-server communication
- 💾 **DataStore Bridge** - Auto-sync with persistence
- 🛡️ **Rate Limiting** - Automatic protection
- ⏰ **TTL Expiration** - Auto-cleanup of old data
- 🧹 **LRU Eviction** - Smart memory management

</td>
<td width="50%">

### 📊 Data Structures
- 🗃️ **Hashes** - Player data, configs
- 📋 **Lists** - Queues, chat history
- 🏷️ **Sets** - Tags, online players
- 🏆 **Sorted Sets** - Leaderboards, rankings
- 🔑 **Key-Value** - Simple caching
- 🔍 **Pattern Matching** - Find keys with wildcards

</td>
</tr>
<tr>
<td width="50%">

### 🌐 Networking
- 📡 **HTTP Methods** - GET, POST, PUT, DELETE, PATCH
- 💬 **Discord Webhooks** - Easy integration
- 🔁 **Retry Logic** - Exponential backoff
- 📦 **Request Batching** - Efficient API calls
- 🎯 **Response Caching** - Reduce API costs
- 🔐 **Auth Support** - Bearer tokens, API keys

</td>
<td width="50%">

### 🎮 Game-Ready
- 👥 **Player Management** - Session tracking
- 🏅 **Leaderboards** - Real-time rankings
- 💬 **Global Chat** - Cross-server messaging
- 🎪 **Live Events** - Synchronized gameplay
- 📊 **Analytics** - Track player behavior
- 🔒 **Distributed Locks** - Prevent exploits

</td>
</tr>
</table>

## 📦 Installation


### Manual Installation

1. Download the latest release from [Releases](https://github.com/VerifiedHawaii/Raddish/releases)
2. Extract the `Raddish` folder
3. Place it in `ReplicatedStorage` or `ServerScriptService` in Roblox Studio

### Verify Installation

```lua
local Raddish = require(game.ReplicatedStorage.Raddish)
print("Raddish loaded successfully!")
```

## 🚀 Quick Start

### Basic Usage

```lua
local Raddish = require(game.ReplicatedStorage.Raddish)

-- Store data with auto-expiration
Raddish.Set("player:123:health", 100, 60) -- Expires in 60 seconds

-- Get data (instant!)
local health = Raddish.Get("player:123:health")
print(health) -- 100

-- Increment counter
Raddish.Incr("visits") -- 1
Raddish.Incr("visits") -- 2

-- Check if key exists
if Raddish.Exists("player:123:health") then
    print("Player is alive!")
end
```

### Player Data Management

```lua
local Raddish = require(game.ReplicatedStorage.Raddish)

game.Players.PlayerAdded:Connect(function(player)
    -- Load player data (cached after first load)
    local coins = Raddish.GetWithCache(player, "Coins", 0, 300)
    local level = Raddish.GetWithCache(player, "Level", 1, 300)
    
    player:SetAttribute("Coins", coins)
    player:SetAttribute("Level", level)
    
    print(player.Name, "has", coins, "coins and is level", level)
end)

function giveCoins(player, amount)
    local newCoins = Raddish.IncrementWithCache(player, "Coins", amount, 0, 300)
    player:SetAttribute("Coins", newCoins)
    return newCoins
end

game.Players.PlayerRemoving:Connect(function(player)
    -- Auto-save player data
    Raddish.FlushPlayer(player)
end)
```

### Global Leaderboard

```lua
local Raddish = require(game.ReplicatedStorage.Raddish)

-- Add players to leaderboard
Raddish.ZAdd("leaderboard:global", 9999, "VerifiedHawaii")
Raddish.ZAdd("leaderboard:global", 5000, "Player2")
Raddish.ZAdd("leaderboard:global", 7500, "Player3")

-- Get top 10 players
local top10 = Raddish.ZRange("leaderboard:global", 1, 10, true)

for i, entry in ipairs(top10) do
    print(i, entry.member, entry.score)
end

-- Get player's rank
local rank = Raddish.ZRank("leaderboard:global", "VerifiedHawaii")
print("Rank:", rank + 1)

-- Update score
Raddish.ZIncrBy("leaderboard:global", 1000, "Player2")
```

### Cross-Server Events

```lua
local Raddish = require(game.ReplicatedStorage.Raddish)

-- Subscribe to events (all servers)
Raddish.Subscribe("global:announcement", function(data)
    print("Announcement:", data.message)
    
    -- Show to all players on this server
    for _, player in ipairs(game.Players:GetPlayers()) do
        game.ReplicatedStorage.ShowAnnouncement:FireClient(player, data.message)
    end
end)

-- Publish event (from any server, reaches all servers)
Raddish.Publish("global:announcement", {
    message = "Server maintenance in 10 minutes!",
    timestamp = os.time()
})
```

### External API Integration

```lua
local Raddish = require(game.ReplicatedStorage.Raddish)

-- Fetch data from your backend with caching
local response = Raddish.HttpGet("https://api.yourgame.com/player/123", {
    cache = true,
    cacheTTL = 300, -- Cache for 5 minutes
    headers = {
        ["Authorization"] = "Bearer your-api-key"
    }
})

if response.Success then
    print("Player level:", response.Body.level)
else
    warn("API error:", response.StatusMessage)
end
```

### Discord Webhooks

```lua
local Raddish = require(game.ReplicatedStorage.Raddish)

local WEBHOOK_URL = "https://discord.com/api/webhooks/YOUR_ID/YOUR_TOKEN"

-- Rich embed
Raddish.SendDiscordWebhook(WEBHOOK_URL, {
    title = "Player Achievement",
    description = "VerifiedHawaii reached level 100!",
    color = 0x00FF00, -- Green
    fields = {
        {name = "Player", value = "VerifiedHawaii", inline = true},
        {name = "Level", value = "100", inline = true},
        {name = "Time Played", value = "50 hours", inline = true}
    },
    footer = {text = "Achievement System"},
    username = "Achievement Bot"
})
```

### Player Profile with Hashes

```lua
local Raddish = require(game.ReplicatedStorage.Raddish)

-- Store player profile data
Raddish.HSet("player:123", "name", "VerifiedHawaii")
Raddish.HSet("player:123", "level", 50)
Raddish.HSet("player:123", "gold", 1000)
Raddish.HSet("player:123", "vip", true)

-- Get specific field
local name = Raddish.HGet("player:123", "name")
print(name) -- "VerifiedHawaii"

-- Get all fields
local profile = Raddish.HGetAll("player:123")
print(profile)
-- {name = "VerifiedHawaii", level = 50, gold = 1000, vip = true}

-- Check if field exists
if Raddish.HExists("player:123", "vip") then
    print("Player is VIP!")
end
```

## 📚 Documentation

### Full Documentation
👉 **[docs.hawaiian.gg/raddish/getting-started](https://hawaiian.gg/raddish/getting-started)**

### Quick Links
- [Getting Started](https://docs.hawaiian.gg/raddish/getting-started)
- [Data Structures](https://docs.hawaiian.gg/raddish/data-structures)
- [Pub/Sub Events](https://docs.hawaiian.gg/raddish/pubsub)
- [Networking Guide](https://docs.hawaiian.gg/raddish/networking)
- [DataStore Bridge](https://docs.hawaiian.gg/raddish/datastore)

### API Overview

<details>
<summary><b>Cache Operations</b></summary>

```lua
Raddish.Set(key, value, ttl)          -- Store with optional TTL
Raddish.Get(key)                      -- Retrieve value
Raddish.Delete(key)                   -- Delete key
Raddish.Exists(key)                   -- Check if exists
Raddish.Expire(key, ttl)              -- Set expiration
Raddish.TTL(key)                      -- Get remaining TTL
Raddish.Keys(pattern)                 -- Find keys (wildcards)
Raddish.Incr(key)                     -- Increment by 1
Raddish.Decr(key)                     -- Decrement by 1
Raddish.FlushAll()                    -- Clear all cache
Raddish.GetStats()                    -- Get cache statistics
```

</details>

<details>
<summary><b>Hashes</b></summary>

```lua
Raddish.HSet(hash, field, value)      -- Set field
Raddish.HGet(hash, field)             -- Get field
Raddish.HGetAll(hash)                 -- Get all fields
Raddish.HDel(hash, field)             -- Delete field
Raddish.HExists(hash, field)          -- Check if exists
Raddish.HKeys(hash)                   -- Get all field names
Raddish.HVals(hash)                   -- Get all values
Raddish.HLen(hash)                    -- Get field count
```

</details>

<details>
<summary><b>Lists</b></summary>

```lua
Raddish.LPush(key, value)             -- Push to left (start)
Raddish.RPush(key, value)             -- Push to right (end)
Raddish.LPop(key)                     -- Pop from left
Raddish.RPop(key)                     -- Pop from right
Raddish.LRange(key, start, stop)      -- Get range
Raddish.LLen(key)                     -- Get length
Raddish.LIndex(key, index)            -- Get by index
```

</details>

<details>
<summary><b>Sets</b></summary>

```lua
Raddish.SAdd(key, member)             -- Add member
Raddish.SRem(key, member)             -- Remove member
Raddish.SIsMember(key, member)        -- Check membership (O(1))
Raddish.SMembers(key)                 -- Get all members
Raddish.SCard(key)                    -- Get size
```

</details>

<details>
<summary><b>Sorted Sets</b></summary>

```lua
Raddish.ZAdd(key, score, member)      -- Add with score
Raddish.ZRem(key, member)             -- Remove member
Raddish.ZRange(key, start, stop)      -- Get range (sorted)
Raddish.ZRangeByScore(key, min, max)  -- Get by score range
Raddish.ZScore(key, member)           -- Get score
Raddish.ZRank(key, member)            -- Get rank (0-indexed)
Raddish.ZIncrBy(key, delta, member)   -- Increment score
Raddish.ZCard(key)                    -- Get size
```

</details>

<details>
<summary><b>Pub/Sub</b></summary>

```lua
Raddish.Publish(channel, data)        -- Broadcast to all servers
Raddish.Subscribe(channel, callback)  -- Listen for events
Raddish.GetHistory(channel, limit)    -- Get event history
Raddish.GetSubscriberCount(channel)   -- Get subscriber count
Raddish.UnsubscribeAll(channel)       -- Remove all subscribers
```

</details>

<details>
<summary><b>Networking</b></summary>

```lua
Raddish.HttpGet(url, options)         -- GET request
Raddish.HttpPost(url, data, options)  -- POST request
Raddish.HttpPut(url, data, options)   -- PUT request
Raddish.HttpDelete(url, options)      -- DELETE request
Raddish.HttpPatch(url, data, options) -- PATCH request
Raddish.HttpBatch(requests)           -- Batch multiple requests

Raddish.SendWebhook(url, data)        -- Generic webhook
Raddish.SendDiscordWebhook(url, opts) -- Discord webhook
Raddish.APIRequest(base, endpoint)    -- REST API helper

Raddish.InvalidateHttpCache(url)      -- Clear cached response
Raddish.ClearHttpCache()              -- Clear all HTTP cache
Raddish.GetNetworkStats()             -- Get request stats
```

</details>

<details>
<summary><b>DataStore Bridge</b></summary>

```lua
Raddish.GetWithCache(player, key, default, ttl)
Raddish.SetWithCache(player, key, value, ttl)
Raddish.IncrementWithCache(player, key, delta, default, ttl)
Raddish.InvalidateCache(player, key)
Raddish.Flush()                       -- Save all pending writes
Raddish.FlushPlayer(player)           -- Save player data
```

</details>

## ⚙️ Configuration

You can configure Raddish by editing these values in the module files:

### CacheManager.lua
```lua
local MAX_CACHE_SIZE = 10000    -- Maximum cached items
local DEFAULT_TTL = 300         -- Default expiration (5 minutes)
```

### NetworkingModule.lua
```lua
local MAX_RETRIES = 3                -- HTTP retry attempts
local RETRY_DELAY = 2                -- Retry delay (seconds)
local RATE_LIMIT_WINDOW = 60         -- Rate limit window (seconds)
local MAX_REQUESTS_PER_WINDOW = 100  -- Max requests per window
```

### DataStoreBridge.lua
```lua
local USE_WRITE_THROUGH = true      -- Write to DataStore immediately
local WRITE_BACK_INTERVAL = 30      -- Batch write interval (seconds)
```

## 📊 Performance

| Operation | Traditional | With Raddish | Improvement |
|-----------|------------|--------------|-------------|
| Get player data | 100-300ms | <1ms | **100-300x faster** |
| Update leaderboard | 100-300ms | <1ms | **100-300x faster** |
| Check if online | Loop through players | <1ms | **1000x+ faster** |
| Cross-server event | Not possible | 100-500ms | **∞ (NEW!)** |
| External API (cached) | 50-500ms | <1ms | **50-500x faster** |

## 🤝 Contributing

Contributions are welcome! Here's how you can help:

1. **Fork the repository**
2. **Create a feature branch** (`git checkout -b feature/amazing-feature`)
3. **Commit your changes** (`git commit -m 'Add amazing feature'`)
4. **Push to the branch** (`git push origin feature/amazing-feature`)
5. **Open a Pull Request**

### Development Setup

```bash
# Clone the repository
git clone https://github.com/VerifiedHawaii/Raddish.git

# Create a branch for your feature
cd Raddish
git checkout -b feature/my-feature

# Make your changes and test in Roblox Studio

# Commit and push
git add .
git commit -m "Add my feature"
git push origin feature/my-feature
```

### Guidelines
- Follow the existing code style
- Add comments for complex logic
- Update documentation for new features
- Test thoroughly in Roblox Studio
- Keep commits focused and descriptive

## 🐛 Bug Reports

Found a bug? Please [open an issue](https://github.com/VerifiedHawaii/Raddish/issues) with:
- Clear title and description
- Steps to reproduce
- Expected vs actual behavior
- Roblox Studio version
- Any error messages

## 💡 Feature Requests

Have an idea? [Open a discussion](https://github.com/VerifiedHawaii/Raddish/discussions) and let's talk about it!

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

```
MIT License

Copyright (c) 2025 VerifiedHawaii

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

## 🙏 Acknowledgments

- Inspired by [Redis](https://redis.io/) - The amazing in-memory data store
- Built for the [Roblox](https://www.roblox.com/) game development community
- Thanks to all [contributors](https://github.com/VerifiedHawaii/Raddish/graphs/contributors)

## 📞 Support

- **Documentation**: [docs.hawaiian.gg/raddish/getting-started](https://docs.hawaiian.gg/raddish/getting-started)
- **Discord**: [Join our server](https://discord.gg/TuV4VbfG88)
- **Email**: support@hawaiian.gg
- **Issues**: [GitHub Issues](https://github.com/VerifiedHawaii/Raddish/issues)
- **Discussions**: [GitHub Discussions](https://github.com/VerifiedHawaii/Raddish/discussions)

## ⭐ Star History

If you find Raddish useful, please consider giving it a star! It helps others discover the project.

[![Star History Chart](https://api.star-history.com/svg?repos=VerifiedHawaii/Raddish&type=Date)](https://star-history.com/#VerifiedHawaii/Raddish&Date)

---

<div align="center">

**Built with ❤️ by [VerifiedHawaii](https://github.com/VerifiedHawaii)**

[⬆ Back to top](#)

</div>
