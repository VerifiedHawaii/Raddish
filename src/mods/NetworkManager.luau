--[[
    NetworkingModule.lua
]]

local HttpService = game:GetService("HttpService")
local CacheManager = require(script.Parent.Parent.CacheManager)

local NetworkingModule = {}
NetworkingModule.__index = NetworkingModule

-- Configuration
local MAX_RETRIES = 3
local RETRY_DELAY = 2 -- seconds
local REQUEST_TIMEOUT = 10 -- seconds
local RATE_LIMIT_WINDOW = 60 -- seconds
local MAX_REQUESTS_PER_WINDOW = 100

-- Rate limiting tracking
local requestCounts = {}
local requestQueue = {}
local isProcessingQueue = false

function NetworkingModule.new()
	local self = setmetatable({}, NetworkingModule)

	-- Start queue processor
	task.spawn(function()
		self:_startQueueProcessor()
	end)

	-- Start rate limit reset
	task.spawn(function()
		self:_startRateLimitReset()
	end)

	return self
end

-- GET request with caching
function NetworkingModule:GetAsync(url, options)
	options = options or {}
	local useCache = options.cache ~= false
	local cacheTTL = options.cacheTTL or 300
	local headers = options.headers or {}

	-- Check cache first
	if useCache then
		local cacheKey = "http:get:" .. url
		local cached = CacheManager:Get(cacheKey)

		if cached then
			print("[NetworkingModule] Cache hit for:", url)
			return cached
		end
	end

	-- Make HTTP request
	local response = self:_makeRequest("GET", url, nil, headers)

	-- Cache successful responses
	if useCache and response and response.Success then
		local cacheKey = "http:get:" .. url
		CacheManager:Set(cacheKey, response, cacheTTL)
	end

	return response
end

-- POST request
function NetworkingModule:PostAsync(url, data, options)
	options = options or {}
	local headers = options.headers or {["Content-Type"] = "application/json"}
	local body = data

	-- Convert table to JSON if needed
	if type(data) == "table" then
		body = HttpService:JSONEncode(data)
	end

	return self:_makeRequest("POST", url, body, headers)
end

-- PUT request
function NetworkingModule:PutAsync(url, data, options)
	options = options or {}
	local headers = options.headers or {["Content-Type"] = "application/json"}
	local body = data

	if type(data) == "table" then
		body = HttpService:JSONEncode(data)
	end

	return self:_makeRequest("PUT", url, body, headers)
end

-- DELETE request
function NetworkingModule:DeleteAsync(url, options)
	options = options or {}
	local headers = options.headers or {}

	return self:_makeRequest("DELETE", url, nil, headers)
end

-- PATCH request
function NetworkingModule:PatchAsync(url, data, options)
	options = options or {}
	local headers = options.headers or {["Content-Type"] = "application/json"}
	local body = data

	if type(data) == "table" then
		body = HttpService:JSONEncode(data)
	end

	return self:_makeRequest("PATCH", url, body, headers)
end

-- Batch multiple requests
function NetworkingModule:BatchAsync(requests)
	local results = {}
	local promises = {}

	for i, request in ipairs(requests) do
		table.insert(promises, {
			index = i,
			request = request
		})
	end

	-- Execute all requests
	for _, promise in ipairs(promises) do
		local req = promise.request
		local result

		if req.method == "GET" then
			result = self:GetAsync(req.url, req.options)
		elseif req.method == "POST" then
			result = self:PostAsync(req.url, req.data, req.options)
		elseif req.method == "PUT" then
			result = self:PutAsync(req.url, req.data, req.options)
		elseif req.method == "DELETE" then
			result = self:DeleteAsync(req.url, req.options)
		elseif req.method == "PATCH" then
			result = self:PatchAsync(req.url, req.data, req.options)
		end

		results[promise.index] = result
	end

	return results
end

-- Queue a request (for rate limiting)
function NetworkingModule:QueueRequest(method, url, data, options)
	local requestId = HttpService:GenerateGUID(false)

	table.insert(requestQueue, {
		id = requestId,
		method = method,
		url = url,
		data = data,
		options = options,
		timestamp = os.time()
	})

	return requestId
end

-- Invalidate cache for URL
function NetworkingModule:InvalidateCache(url)
	local cacheKey = "http:get:" .. url
	CacheManager:Delete(cacheKey)
	return true
end

-- Clear all HTTP cache
function NetworkingModule:ClearCache()
	local keys = CacheManager:Keys("http:.*")

	for _, key in ipairs(keys) do
		CacheManager:Delete(key)
	end

	return #keys
end

-- Get request statistics
function NetworkingModule:GetStats()
	return {
		queueSize = #requestQueue,
		requestsThisWindow = requestCounts.current or 0,
		maxRequestsPerWindow = MAX_REQUESTS_PER_WINDOW,
		cacheSize = #CacheManager:Keys("http:.*")
	}
end

-- Webhook helper (common use case)
function NetworkingModule:SendWebhook(webhookUrl, data)
	local payload = {
		content = data.content or "",
		username = data.username or "Roblox Bot",
		avatar_url = data.avatar_url,
		embeds = data.embeds
	}

	return self:PostAsync(webhookUrl, payload, {
		headers = {["Content-Type"] = "application/json"}
	})
end

-- Discord webhook helper
function NetworkingModule:SendDiscordWebhook(webhookUrl, options)
	local embed = {
		title = options.title,
		description = options.description,
		color = options.color or 3447003, -- Blue
		fields = options.fields or {},
		footer = options.footer,
		timestamp = os.date("!%Y-%m-%dT%H:%M:%S") .. "Z"
	}

	return self:SendWebhook(webhookUrl, {
		content = options.content,
		username = options.username or "Roblox Game",
		embeds = {embed}
	})
end

-- REST API helper with authentication
function NetworkingModule:APIRequest(baseUrl, endpoint, options)
	options = options or {}
	local method = options.method or "GET"
	local data = options.data
	local headers = options.headers or {}

	-- Add authentication if provided
	if options.apiKey then
		headers["Authorization"] = "Bearer " .. options.apiKey
	elseif options.token then
		headers["X-API-Token"] = options.token
	end

	local url = baseUrl .. endpoint

	if method == "GET" then
		return self:GetAsync(url, {headers = headers, cache = options.cache, cacheTTL = options.cacheTTL})
	elseif method == "POST" then
		return self:PostAsync(url, data, {headers = headers})
	elseif method == "PUT" then
		return self:PutAsync(url, data, {headers = headers})
	elseif method == "DELETE" then
		return self:DeleteAsync(url, {headers = headers})
	elseif method == "PATCH" then
		return self:PatchAsync(url, data, {headers = headers})
	end
end

-- Private: Make HTTP request with retry logic
function NetworkingModule:_makeRequest(method, url, body, headers)
	local attempts = 0

	while attempts < MAX_RETRIES do
		attempts = attempts + 1

		-- Check rate limit
		if not self:_checkRateLimit() then
			warn("[NetworkingModule] Rate limit reached, queuing request")
			return {
				Success = false,
				StatusCode = 429,
				StatusMessage = "Rate limit reached",
				Body = nil
			}
		end

		-- Increment request count
		requestCounts.current = (requestCounts.current or 0) + 1

		-- Make request
		local success, response = pcall(function()
			if method == "GET" then
				return HttpService:GetAsync(url)
			elseif method == "POST" then
				return HttpService:PostAsync(url, body, Enum.HttpContentType.ApplicationJson, false, headers)
			elseif method == "PUT" or method == "PATCH" or method == "DELETE" then
				return HttpService:RequestAsync({
					Url = url,
					Method = method,
					Headers = headers,
					Body = body
				})
			end
		end)

		if success then
			-- Parse response
			local parsedResponse

			if type(response) == "string" then
				-- GET response
				local decodeSuccess, decoded = pcall(function()
					return HttpService:JSONDecode(response)
				end)

				parsedResponse = {
					Success = true,
					StatusCode = 200,
					StatusMessage = "OK",
					Body = decodeSuccess and decoded or response
				}
			else
				-- RequestAsync response
				parsedResponse = {
					Success = response.Success,
					StatusCode = response.StatusCode,
					StatusMessage = response.StatusMessage,
					Body = response.Body
				}

				-- Try to parse JSON body
				if parsedResponse.Body then
					local decodeSuccess, decoded = pcall(function()
						return HttpService:JSONDecode(parsedResponse.Body)
					end)

					if decodeSuccess then
						parsedResponse.Body = decoded
					end
				end
			end

			print("[NetworkingModule] Request successful:", method, url)
			return parsedResponse

		else
			warn("[NetworkingModule] Request failed (attempt " .. attempts .. "):", response)

			-- Check if we should retry
			if attempts < MAX_RETRIES then
				local delay = RETRY_DELAY * attempts -- Exponential backoff
				task.wait(delay)
			else
				return {
					Success = false,
					StatusCode = 500,
					StatusMessage = "Max retries reached",
					Body = response
				}
			end
		end
	end
end

-- Private: Check rate limit
function NetworkingModule:_checkRateLimit()
	local current = requestCounts.current or 0
	return current < MAX_REQUESTS_PER_WINDOW
end

-- Private: Reset rate limit counter
function NetworkingModule:_startRateLimitReset()
	while true do
		task.wait(RATE_LIMIT_WINDOW)
		requestCounts.current = 0
		print("[NetworkingModule] Rate limit reset")
	end
end

-- Private: Process queued requests
function NetworkingModule:_startQueueProcessor()
	while true do
		task.wait(1)

		if #requestQueue > 0 and not isProcessingQueue then
			isProcessingQueue = true

			local request = table.remove(requestQueue, 1)

			if request then
				print("[NetworkingModule] Processing queued request:", request.url)

				if request.method == "GET" then
					self:GetAsync(request.url, request.options)
				elseif request.method == "POST" then
					self:PostAsync(request.url, request.data, request.options)
				elseif request.method == "PUT" then
					self:PutAsync(request.url, request.data, request.options)
				elseif request.method == "DELETE" then
					self:DeleteAsync(request.url, request.options)
				end
			end

			isProcessingQueue = false
		end
	end
end

return NetworkingModule.new()