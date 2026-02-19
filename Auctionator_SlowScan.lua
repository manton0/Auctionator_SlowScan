local lib = LibStub("LibAuctionScan-1.0")

local addon = {}
lib:Embed(addon)

local isScanning = false
local scanButton
local statusText

-----------------------------------------
-- Incremental price collection
-- We read each AH page live during SCAN_STATUS_UPDATE (the page is still
-- loaded at that point) so we never depend on GetItemInfo cache or on
-- the library passing data back. This also means partial scans work.
-----------------------------------------

local collectedPrices = {}  -- {[itemName] = lowestPerUnitPrice}
local collectedCount = 0    -- unique item names collected so far

local function ProcessCurrentPage()
	local minQuality = AUCTIONATOR_SCAN_MINLEVEL or 1
	local shown = GetNumAuctionItems("list")

	for i = 1, shown do
		local name, _, count, quality, _, _, _, _, buyoutPrice = GetAuctionItemInfo("list", i)
		if name and buyoutPrice and buyoutPrice > 0 and count and count > 0 then
			local qualityIndex = (quality or 0) + 1
			if qualityIndex >= minQuality then
				local perUnit = math.floor(buyoutPrice / count)
				if perUnit > 0 then
					if not collectedPrices[name] then
						collectedCount = collectedCount + 1
					end
					if not collectedPrices[name] or perUnit < collectedPrices[name] then
						collectedPrices[name] = perUnit
					end
				end
			end
		end
	end
end

local function FlushToAuctionator()
	if not Atr_ScanDB then return 0, 0, 0 end

	local numAdded, numUpdated, totalItems = 0, 0, 0

	for itemName, price in pairs(collectedPrices) do
		totalItems = totalItems + 1
		if Atr_ScanDB[itemName] == nil then
			numAdded = numAdded + 1
		else
			numUpdated = numUpdated + 1
		end
		Atr_ScanDB[itemName] = price
	end

	AUCTIONATOR_LAST_SCAN_TIME = time()

	if Atr_UpdateFullScanFrame then
		Atr_UpdateFullScanFrame()
	end

	return totalItems, numAdded, numUpdated
end

-----------------------------------------
-- Scan callback handler
-----------------------------------------

local function ScanCallback(event, ...)
	if event == "SCAN_STATUS_UPDATE" then
		local page, totalPages = ...
		-- The AH page is still loaded at this point, read it live
		ProcessCurrentPage()
		if statusText and totalPages then
			statusText:SetText("Slow Scan: page " .. page .. " / " .. totalPages .. "  (" .. collectedCount .. " items)")
		end

	elseif event == "SCAN_PAGE_UPDATE" then
		local page, totalPages = ...
		if statusText and totalPages then
			statusText:SetText("Slow Scan: page " .. page .. " / " .. totalPages .. "  (" .. collectedCount .. " items)")
		end

	elseif event == "SCAN_COMPLETE" then
		isScanning = false
		local totalItems, numAdded, numUpdated = FlushToAuctionator()

		if scanButton then
			scanButton:SetText("Slow Scan")
			scanButton:Enable()
		end
		if statusText then
			statusText:SetText("Done! " .. numAdded .. " added, " .. numUpdated .. " updated.")
		end
		DEFAULT_CHAT_FRAME:AddMessage(
			"|cff33ff99Auctionator SlowScan:|r Complete. " ..
			totalItems .. " items processed, " ..
			numAdded .. " added, " ..
			numUpdated .. " updated."
		)

	elseif event == "SCAN_INTERRUPTED" then
		isScanning = false
		local totalItems, numAdded, numUpdated = FlushToAuctionator()

		if scanButton then
			scanButton:SetText("Slow Scan")
			scanButton:Enable()
		end
		if statusText then
			statusText:SetText("Stopped. " .. numAdded .. " added, " .. numUpdated .. " updated.")
		end
		DEFAULT_CHAT_FRAME:AddMessage(
			"|cff33ff99Auctionator SlowScan:|r Stopped. " ..
			totalItems .. " items processed, " ..
			numAdded .. " added, " ..
			numUpdated .. " updated."
		)

	elseif event == "SCAN_TIMEOUT" then
		if statusText then
			statusText:SetText("Timeout on current filter, continuing...")
		end
	end
end

-----------------------------------------
-- Start / Stop
-----------------------------------------

local function StartSlowScan()
	if not Atr_ScanDB then
		DEFAULT_CHAT_FRAME:AddMessage("|cffff3333Auctionator SlowScan:|r Auctionator price database not initialized.")
		return
	end

	-- Reset collected data for a fresh scan
	collectedPrices = {}
	collectedCount = 0

	local scanQueue = { {name = ""} }
	local result = addon:StartScan(scanQueue, ScanCallback, {})
	if result == 1 or result == 0 then
		isScanning = true
		if scanButton then
			scanButton:SetText("Stop Scan")
		end
		if statusText then
			statusText:SetText("Starting slow scan...")
		end
	elseif result == -1 then
		DEFAULT_CHAT_FRAME:AddMessage("|cffff3333Auctionator SlowScan:|r Auction House is not open.")
	else
		DEFAULT_CHAT_FRAME:AddMessage("|cffff3333Auctionator SlowScan:|r Could not start scan (code: " .. tostring(result) .. ").")
	end
end

local function StopSlowScan()
	addon:StopScan()
	-- SCAN_INTERRUPTED callback will handle flushing data and resetting state
end

local function ToggleScan()
	if isScanning then
		StopSlowScan()
	else
		StartSlowScan()
	end
end

-----------------------------------------
-- UI creation
-----------------------------------------

local uiCreated = false

local function CreateScanUI()
	if uiCreated or not AuctionFrame then return end
	uiCreated = true

	-- Create the Slow Scan button, anchored to the top-right area of the AuctionFrame
	scanButton = CreateFrame("Button", "AtrSlowScanButton", AuctionFrame, "UIPanelButtonTemplate")
	scanButton:SetWidth(100)
	scanButton:SetHeight(22)
	scanButton:SetText("Slow Scan")
	scanButton:SetPoint("TOPRIGHT", AuctionFrame, "TOPRIGHT", -180, -28)
	scanButton:SetScript("OnClick", ToggleScan)

	-- Status text below the button
	statusText = scanButton:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	statusText:SetPoint("TOP", scanButton, "BOTTOM", 0, -2)
	statusText:SetText("")
end

-----------------------------------------
-- Event handling
-----------------------------------------

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("AUCTION_HOUSE_SHOW")
eventFrame:RegisterEvent("AUCTION_HOUSE_CLOSED")
eventFrame:SetScript("OnEvent", function(self, event)
	if event == "AUCTION_HOUSE_SHOW" then
		CreateScanUI()
		if scanButton then
			scanButton:Show()
		end
	elseif event == "AUCTION_HOUSE_CLOSED" then
		if isScanning then
			isScanning = false
			if scanButton then
				scanButton:SetText("Slow Scan")
			end
		end
	end
end)
