--[[
    EventQueue.lua
]]

local MessagingService = game:GetService("MessagingService")
local HttpService = game:GetService("HttpService")
local CacheManager = require(script.Parent.CacheManager)

local EventQueue = {}
EventQueue.__index = EventQueue

local subscribers = {}
local eventHistory = {}
local messageCount = {}
local lastReset = os.time()

-- Rate limiting config
local MAX_MESSAGES_PER_MINUTE = 150
local BATCH_SIZE = 10
local BATCH_INTERVAL = 1

function EventQueue.new()
	local self = setmetatable({}, EventQueue)

	-- Start batch processor
	task.spawn(function()
		self:_startBatchProcessor()
	end)

	-- Start rate limit reset
	task.spawn(function()
		self:_startRateLimitReset()
	end)

	return self
end

-- PUBLISH - Publish event to channel
function EventQueue:Publish(channel, data, options)
	options = options or {}
	local external = options.external ~= false -- Default true
	local cache = options.cache ~= false -- Default true

	local eventData = {
		data = data,
		timestamp = os.time(),
		id = HttpService:GenerateGUID(false)
	}

	-- Cache locally for quick access
	if cache then
		local queueKey = "queue_" .. channel
		local queue = CacheManager:Get(queueKey) or {}
		table.insert(queue, eventData)

		-- Keep only last 100 events per channel
		if #queue > 100 then
			table.remove(queue, 1)
		end

		CacheManager:Set(queueKey, queue, 300) -- 5 min TTL
	end

	-- Notify local subscribers (internal)
	if subscribers[channel] then
		for _, callback in ipairs(subscribers[channel]) do
			task.spawn(callback, eventData.data)
		end
	end

	-- Publish across servers (external) with rate limiting
	if external then
		self:_publishExternal(channel, eventData)
	end

	return eventData.id
end

-- SUBSCRIBE - Subscribe to channel
function EventQueue:Subscribe(channel, callback, options)
	options = options or {}
	local external = options.external ~= false -- Default true

	if not subscribers[channel] then
		subscribers[channel] = {}

		-- Subscribe to MessagingService for cross-server
		if external then
			local success, connection = pcall(function()
				return MessagingService:SubscribeAsync(channel, function(message)
					local eventData = message.Data

					-- Notify all subscribers
					for _, cb in ipairs(subscribers[channel]) do
						task.spawn(cb, eventData.data)
					end

					-- Cache the event
					local queueKey = "queue_" .. channel
					local queue = CacheManager:Get(queueKey) or {}
					table.insert(queue, eventData)

					if #queue > 100 then
						table.remove(queue, 1)
					end

					CacheManager:Set(queueKey, queue, 300)
				end)
			end)

			if not success then
				warn("[EventQueue] Failed to subscribe to external channel:", channel, connection)
			end
		end
	end

	table.insert(subscribers[channel], callback)

	return function()
		-- Unsubscribe function
		for i, cb in ipairs(subscribers[channel]) do
			if cb == callback then
				table.remove(subscribers[channel], i)
				break
			end
		end
	end
end

-- Get event history from cache
function EventQueue:GetHistory(channel, limit)
	limit = limit or 100
	local queueKey = "queue_" .. channel
	local queue = CacheManager:Get(queueKey) or {}

	local history = {}
	local start = math.max(1, #queue - limit + 1)

	for i = start, #queue do
		table.insert(history, queue[i])
	end

	return history
end

-- Get subscriber count for channel
function EventQueue:GetSubscriberCount(channel)
	return subscribers[channel] and #subscribers[channel] or 0
end

-- Unsubscribe all from channel
function EventQueue:UnsubscribeAll(channel)
	subscribers[channel] = nil
	return true
end

-- Private: Publish to external (cross-server) with batching
local publishBatch = {}

function EventQueue:_publishExternal(channel, eventData)
	if not publishBatch[channel] then
		publishBatch[channel] = {}
	end

	table.insert(publishBatch[channel], eventData)
end

function EventQueue:_startBatchProcessor()
	while true do
		task.wait(BATCH_INTERVAL)

		for channel, batch in pairs(publishBatch) do
			if #batch > 0 then
				-- Check rate limit
				if self:_canPublish() then
					local success, err = pcall(function()
						-- Send batch or individual messages
						if #batch == 1 then
							MessagingService:PublishAsync(channel, batch[1])
							messageCount[channel] = (messageCount[channel] or 0) + 1
						else
							-- Send as batch
							MessagingService:PublishAsync(channel .. "_batch", {
								batch = batch,
								count = #batch
							})
							messageCount[channel] = (messageCount[channel] or 0) + #batch
						end
					end)

					if not success then
						warn("[EventQueue] Failed to publish batch:", err)
					end

					publishBatch[channel] = {}
				else
					warn("[EventQueue] Rate limit reached, delaying publish")
				end
			end
		end
	end
end

function EventQueue:_canPublish()
	local totalMessages = 0
	for _, count in pairs(messageCount) do
		totalMessages = totalMessages + count
	end

	return totalMessages < MAX_MESSAGES_PER_MINUTE
end

function EventQueue:_startRateLimitReset()
	while true do
		task.wait(60)
		messageCount = {}
		lastReset = os.time()
	end
end

return EventQueue.new()