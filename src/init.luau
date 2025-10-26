--[[
    Raddish.lua
]]

local CacheManager = require("./Raddish/CacheManager")
local EventQueue = require("./Raddish/EventQueue")
local DataStructures = require("./Raddish/DataStructures")
local DataStoreBridge = require("./Raddish/DataStoreBridge")
local NetworkingModule = require("./Raddish/mods/NetworkManager")

local raddish = {}

-- Export all CacheManager methods
raddish.Set = function(...) return CacheManager:Set(...) end
raddish.Get = function(...) return CacheManager:Get(...) end
raddish.Delete = function(...) return CacheManager:Delete(...) end
raddish.Exists = function(...) return CacheManager:Exists(...) end
raddish.Expire = function(...) return CacheManager:Expire(...) end
raddish.TTL = function(...) return CacheManager:TTL(...) end
raddish.Keys = function(...) return CacheManager:Keys(...) end
raddish.FlushAll = function(...) return CacheManager:FlushAll(...) end
raddish.GetStats = function(...) return CacheManager:GetStats(...) end

-- Export all EventQueue methods
raddish.Publish = function(...) return EventQueue:Publish(...) end
raddish.Subscribe = function(...) return EventQueue:Subscribe(...) end
raddish.GetHistory = function(...) return EventQueue:GetHistory(...) end
raddish.GetSubscriberCount = function(...) return EventQueue:GetSubscriberCount(...) end
raddish.UnsubscribeAll = function(...) return EventQueue:UnsubscribeAll(...) end

-- Export all DataStructures methods
raddish.HSet = function(...) return DataStructures:HSet(...) end
raddish.HGet = function(...) return DataStructures:HGet(...) end
raddish.HGetAll = function(...) return DataStructures:HGetAll(...) end
raddish.HDel = function(...) return DataStructures:HDel(...) end
raddish.HExists = function(...) return DataStructures:HExists(...) end
raddish.HKeys = function(...) return DataStructures:HKeys(...) end
raddish.HVals = function(...) return DataStructures:HVals(...) end
raddish.HLen = function(...) return DataStructures:HLen(...) end

-- Export all DataStructures methods 
raddish.LPush = function(...) return DataStructures:LPush(...) end
raddish.RPush = function(...) return DataStructures:RPush(...) end
raddish.LPop = function(...) return DataStructures:LPop(...) end
raddish.RPop = function(...) return DataStructures:RPop(...) end
raddish.LRange = function(...) return DataStructures:LRange(...) end
raddish.LLen = function(...) return DataStructures:LLen(...) end
raddish.LIndex = function(...) return DataStructures:LIndex(...) end

-- Export all DataStructures methods
raddish.SAdd = function(...) return DataStructures:SAdd(...) end
raddish.SRem = function(...) return DataStructures:SRem(...) end
raddish.SIsMember = function(...) return DataStructures:SIsMember(...) end
raddish.SMembers = function(...) return DataStructures:SMembers(...) end
raddish.SCard = function(...) return DataStructures:SCard(...) end

-- Export all DataStructures methods
raddish.ZAdd = function(...) return DataStructures:ZAdd(...) end
raddish.ZRem = function(...) return DataStructures:ZRem(...) end
raddish.ZRange = function(...) return DataStructures:ZRange(...) end
raddish.ZRangeByScore = function(...) return DataStructures:ZRangeByScore(...) end
raddish.ZScore = function(...) return DataStructures:ZScore(...) end
raddish.ZCard = function(...) return DataStructures:ZCard(...) end
raddish.ZIncrBy = function(...) return DataStructures:ZIncrBy(...) end
raddish.ZRank = function(...) return DataStructures:ZRank(...) end

-- Export all DataStoreBridge methods
raddish.GetWithCache = function(...) return DataStoreBridge:GetWithCache(...) end
raddish.SetWithCache = function(...) return DataStoreBridge:SetWithCache(...) end
raddish.IncrementWithCache = function(...) return DataStoreBridge:IncrementWithCache(...) end
raddish.InvalidateCache = function(...) return DataStoreBridge:InvalidateCache(...) end
raddish.Flush = function(...) return DataStoreBridge:Flush(...) end
raddish.FlushPlayer = function(...) return DataStoreBridge:FlushPlayer(...) end

-- Export all NetworkManager methods

raddish.HttpGet = function(...) return NetworkingModule:GetAsync(...) end
raddish.HttpPost = function(...) return NetworkingModule:PostAsync(...) end
raddish.HttpPut = function(...) return NetworkingModule:PutAsync(...) end
raddish.HttpDelete = function(...) return NetworkingModule:DeleteAsync(...) end
raddish.HttpPatch = function(...) return NetworkingModule:PatchAsync(...) end
raddish.HttpBatch = function(...) return NetworkingModule:BatchAsync(...) end
raddish.QueueRequest = function(...) return NetworkingModule:QueueRequest(...) end
raddish.InvalidateHttpCache = function(...) return NetworkingModule:InvalidateCache(...) end
raddish.ClearHttpCache = function(...) return NetworkingModule:ClearCache(...) end
raddish.GetNetworkStats = function(...) return NetworkingModule:GetStats(...) end
raddish.SendWebhook = function(...) return NetworkingModule:SendWebhook(...) end
raddish.SendDiscordWebhook = function(...) return NetworkingModule:SendDiscordWebhook(...) end
raddish.APIRequest = function(...) return NetworkingModule:APIRequest(...) end


-- Atomic increment
function raddish.Incr(key, ttl)
	local value = CacheManager:Get(key) or 0

	if type(value) ~= "number" then
		warn("[RedisLikeSystem] Cannot increment non-number value")
		return nil
	end

	value = value + 1
	CacheManager:Set(key, value, ttl)

	return value
end

-- Atomic decrement
function raddish.Decr(key, ttl)
	local value = CacheManager:Get(key) or 0

	if type(value) ~= "number" then
		warn("[RedisLikeSystem] Cannot decrement non-number value")
		return nil
	end

	value = value - 1
	CacheManager:Set(key, value, ttl)

	return value
end

-- Get or set (if not exists)
function raddish.GetOrSet(key, defaultValue, ttl)
	local value = CacheManager:Get(key)

	if value == nil then
		CacheManager:Set(key, defaultValue, ttl)
		return defaultValue
	end

	return value
end

return raddish