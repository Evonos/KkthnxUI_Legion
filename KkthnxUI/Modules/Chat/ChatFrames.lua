local K, C, L = select(2, ...):unpack()
if C.Chat.Enable ~= true then return end

-- Lua api
local _G = _G
local gsub = string.gsub
local upper = string.upper
local type = type
local format = string.format
local select = select
local print = print
local find = string.find
local len = string.len
local sub = string.sub

-- Wow api
local GetID, GetName = GetID, GetName
local CreateFrame = CreateFrame
local hooksecurefunc = hooksecurefunc
local Movers = K.Movers
local origs = {}

local strings = {
	INSTANCE_CHAT = L_CHAT_INSTANCE,
	GUILD = L_CHAT_GUILD,
	PARTY = L_CHAT_PARTY,
	RAID = L_CHAT_RAID,
	OFFICER = L_CHAT_OFFICER,
	INSTANCE_CHAT_LEADER = L_CHAT_INSTANCE_LEADER,
	PARTY_LEADER = L_CHAT_PARTY_LEADER,
	RAID_LEADER = L_CHAT_RAID_LEADER,
	PET_BATTLE_COMBAT_LOG = L_CHAT_PET_BATTLE,

	-- zhCN
	Guild = L_CHAT_GUILD,
	raid = L_CHAT_RAID,
	Party = L_CHAT_PARTY,
}

local function ShortChannel(channel) return string.format("|Hchannel:%s|h[%s]|h", channel, strings[channel] or channel:gsub("channel:", "")) end

local function AddMessage(frame, str, ...)
	str = str:gsub("|Hplayer:(.-)|h%[(.-)%]|h", "|Hplayer:%1|h%2|h")
	str = str:gsub("|HBNplayer:(.-)|h%[(.-)%]|h", "|HBNplayer:%1|h%2|h")
	str = str:gsub("|Hchannel:(.-)|h%[(.-)%]|h", ShortChannel)
	str = str:gsub("^To (.-|h)", "|cffad2424@|r%1")
	str = str:gsub("^(.-|h) whispers", "%1")
	str = str:gsub("^(.-|h) says", "%1")
	str = str:gsub("^(.-|h) yells", "%1")
	str = str:gsub("<" .. AFK .. ">", "|cffFF0000" .. L_CHAT_AFK .. "|r ")
	str = str:gsub("<" .. DND .. ">", "|cffE7E716" .. L_CHAT_DND .."|r ")
	str = str:gsub("^%["..RAID_WARNING.."%]", L_CHAT_RAID_WARNING)
	return origs[frame](frame, str, ...)
end

ChatConfigFrameDefaultButton:Kill()
QuickJoinToastButton:Kill()
ChatFrameMenuButton:Kill()

-- Set chat style
local function SetChatStyle(frame)
	local frame = frame
	local id = frame:GetID()
	local framename = frame:GetName()
	local tab = _G[framename.."Tab"]
	local editbox = _G[framename.."EditBox"]

	frame:SetFrameLevel(5)

	frame:SetClampRectInsets(0, 0, 0, 0)
	frame:SetClampedToScreen(false)
	frame:SetFading(false)

	-- Move the chat edit box
	editbox:ClearAllPoints()
	editbox:SetPoint("BOTTOMLEFT", ChatFrame1, "TOPLEFT", -4, 23)
	editbox:SetPoint("BOTTOMRIGHT", ChatFrame1, "TOPRIGHT", 4, 23)

	-- Hide textures
	for i = 1, #CHAT_FRAME_TEXTURES do
		_G[framename..CHAT_FRAME_TEXTURES[i]]:SetTexture(nil)
	end

	-- Removes default chatframe tabs texture
	_G[format("ChatFrame%sTabLeft", id)]:Kill()
	_G[format("ChatFrame%sTabMiddle", id)]:Kill()
	_G[format("ChatFrame%sTabRight", id)]:Kill()

	_G[format("ChatFrame%sTabSelectedLeft", id)]:Kill()
	_G[format("ChatFrame%sTabSelectedMiddle", id)]:Kill()
	_G[format("ChatFrame%sTabSelectedRight", id)]:Kill()

	_G[format("ChatFrame%sTabHighlightLeft", id)]:Kill()
	_G[format("ChatFrame%sTabHighlightMiddle", id)]:Kill()
	_G[format("ChatFrame%sTabHighlightRight", id)]:Kill()

	_G[format("ChatFrame%sTabSelectedLeft", id)]:Kill()
	_G[format("ChatFrame%sTabSelectedMiddle", id)]:Kill()
	_G[format("ChatFrame%sTabSelectedRight", id)]:Kill()

	_G[format("ChatFrame%sButtonFrameUpButton", id)]:Kill()
	_G[format("ChatFrame%sButtonFrameDownButton", id)]:Kill()
	_G[format("ChatFrame%sButtonFrameBottomButton", id)]:Kill()
	_G[format("ChatFrame%sButtonFrameMinimizeButton", id)]:Kill()
	_G[format("ChatFrame%sButtonFrame", id)]:Kill()

	_G[format("ChatFrame%sEditBoxLeft", id)]:Kill()
	_G[format("ChatFrame%sEditBoxMid", id)]:Kill()
	_G[format("ChatFrame%sEditBoxRight", id)]:Kill()

	_G[format("ChatFrame%sTabGlow", id)]:Kill()

	-- Kill off editbox artwork
	local a, b, c = select(6, editbox:GetRegions()) a:Kill() b:Kill() c:Kill()

	-- Kill bubble tex/glow
	if tab.conversationIcon then tab.conversationIcon:Kill() end

	-- Disable alt key usage
	editbox:SetAltArrowKeyMode(false)

	-- Hide editbox on login
	editbox:Hide()

	-- Script to hide editbox instead of fading editbox to 0.35 alpha via im style
	editbox:HookScript("OnEditFocusGained", function(self) self:Show() end)
	editbox:HookScript("OnEditFocusLost", function(self) self:Hide() end)

	local function OnTextChanged(self)
		local text = self:GetText()

		if InCombatLockdown() then
			local MIN_REPEAT_CHARACTERS = 5
			if (len(text) > MIN_REPEAT_CHARACTERS) then
				local repeatChar = true
				for i = 1, MIN_REPEAT_CHARACTERS, 1 do
					if (sub(text,(0-i), (0-i)) ~= sub(text,(-1-i),(-1-i)) ) then
						repeatChar = false
						break
					end
				end
				if (repeatChar) then
					self:Hide()
					return
				end
			end
		end

		local new, found = gsub(text, "|Kf(%S+)|k(%S+)%s(%S+)|k", "%2 %3")
		if found > 0 then
			new = new:gsub("|", "")
			self:SetText(new)
		end
	end
	editbox:HookScript("OnTextChanged", OnTextChanged)

	-- Hide edit box every time we click on a tab
	tab:HookScript("OnClick", function() editbox:Hide() end)

	-- CREATE OUR OWN TEXTURE FOR EDIT BOX
	if C.Chat.TabsMouseover ~= true then
		local EditBoxBackground = CreateFrame("Frame", "ChatEditBoxBackground", editbox)
		EditBoxBackground:SetBackdrop(K.Backdrop)
		EditBoxBackground:SetBackdropColor(unpack(C.Media.Backdrop_Color))
		EditBoxBackground:SetBackdropBorderColor(unpack(C.Media.Border_Color))
		EditBoxBackground:ClearAllPoints()
		EditBoxBackground:SetPoint("TOPLEFT", editbox, "TOPLEFT", 7, -2)
		EditBoxBackground:SetPoint("BOTTOMRIGHT", editbox, "BOTTOMRIGHT", -7, 2)
		EditBoxBackground:SetFrameStrata("LOW")
		EditBoxBackground:SetFrameLevel(1)

		local function colorize(r, g, b)
			EditBoxBackground:SetBackdropBorderColor(r, g, b)
		end

		-- Update border color according where we talk
		hooksecurefunc("ChatEdit_UpdateHeader", function()
			local type = editbox:GetAttribute("chatType")
			if type == "CHANNEL" then
				local id = GetChannelName(editbox:GetAttribute("channelTarget"))
				if id == 0 then
					colorize(unpack(C.Media.Border_Color))
				else
					colorize(ChatTypeInfo[type..id].r, ChatTypeInfo[type..id].g, ChatTypeInfo[type..id].b)
				end
			else
				colorize(ChatTypeInfo[type].r, ChatTypeInfo[type].g, ChatTypeInfo[type].b)
			end
		end)
	end

	if frame ~= _G["ChatFrame2"] then
		origs[frame] = frame.AddMessage
		frame.AddMessage = AddMessage
	else
		CombatLogQuickButtonFrame_Custom:StripTextures()
		CombatLogQuickButtonFrame_Custom:SetBackdrop(K.BorderBackdrop)
		CombatLogQuickButtonFrame_Custom:SetBackdropColor(unpack(C.Media.Backdrop_Color))
	end

	frame.skinned = true
end

-- Setup chatframes 1 to 10 on login
local function SetupChat(self)
	for i = 1, NUM_CHAT_WINDOWS do
		local Frame = _G["ChatFrame"..i]
		SetChatStyle(Frame)
	end

	-- Remember last channel
	ChatTypeInfo.WHISPER.sticky = 1
	ChatTypeInfo.BN_WHISPER.sticky = 1
	ChatTypeInfo.OFFICER.sticky = 1
	ChatTypeInfo.RAID_WARNING.sticky = 1
	ChatTypeInfo.CHANNEL.sticky = 1
end

local function SetupChatPosAndFont(self)
	for i = 1, NUM_CHAT_WINDOWS do
		local Frame = _G["ChatFrame"..i]
		local ID = Frame:GetID()
		local _, FontSize = FCF_GetChatWindowInfo(ID)

		-- Min. size for chat font
		if FontSize < 12 then
			FCF_SetChatWindowFontSize(nil, Frame, 12)
		else
			FCF_SetChatWindowFontSize(nil, Frame, FontSize)
		end

		-- Font and font style for chat
		if C.Chat.Outline == true then
			Frame:SetFont(C.Media.Font, FontSize, C.Media.Font_Style)
			Frame:SetShadowOffset(0, 0)
			Frame:SetShadowColor(0, 0, 0, 0.2)
		else
			Frame:SetFont(C.Media.Font, FontSize)
			Frame:SetShadowOffset(K.Mult, -K.Mult)
			Frame:SetShadowColor(0, 0, 0, 0.9)
		end

		-- Force chat position
		if (ID == 1) then
			Frame:ClearAllPoints()
			Frame:SetSize(C.Chat.Width, C.Chat.Height)
			Frame:SetPoint(C.Position.Chat[1], C.Position.Chat[2], C.Position.Chat[3], C.Position.Chat[4], C.Position.Chat[5])
			FCF_RestorePositionAndDimensions(Frame)
			FCF_SavePositionAndDimensions(Frame)
		end
	end
end

local BNet = CreateFrame("Frame", "BNetMover", UIParent)
BNet:SetSize(BNToastFrame:GetWidth(), BNToastFrame:GetHeight())
BNet:SetPoint(unpack(C.Position.BnetPopup))
Movers:RegisterFrame(BNet)

BNToastFrame:HookScript("OnShow", function(self)
	self:ClearAllPoints()
	self:SetPoint("TOPLEFT", BNetMover, "TOPLEFT", 3, -3)
end)

local UIChat = CreateFrame("Frame")
UIChat:RegisterEvent("ADDON_LOADED")
UIChat:RegisterEvent("PLAYER_ENTERING_WORLD")
UIChat:SetScript("OnEvent", function(self, event, addon)
	if event == "ADDON_LOADED" then
		if addon == "Blizzard_CombatLog" then
			self:UnregisterEvent("ADDON_LOADED")
			SetupChat(self)
		end
	elseif event == "PLAYER_ENTERING_WORLD" then
		self:UnregisterEvent("PLAYER_ENTERING_WORLD")
		SetupChatPosAndFont(self)
	end
end)

-- Setup temp chat (bn, whisper) when needed
local function SetupTempChat()
	local frame = FCF_GetCurrentChatFrame()
	if frame.skinned then return end
	SetChatStyle(frame)
end
hooksecurefunc("FCF_OpenTemporaryWindow", SetupTempChat)

-- Disable pet battle tab
local old = FCFManager_GetNumDedicatedFrames
function FCFManager_GetNumDedicatedFrames(...)
	return select(1, ...) ~= "PET_BATTLE_COMBAT_LOG" and old(...) or 1
end

-- Remove player's realm name
local function RemoveRealmName(self, event, msg, author, ...)
	local realm = string.gsub(K.Realm, " ", "")
	if msg:find("-" .. realm) then
		return false, gsub(msg, "%-"..realm, ""), author, ...
	end
end
ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", RemoveRealmName)

-- Save slash command typo
local function TypoHistory_Posthook_AddMessage(chat, text)
	if strfind(text, HELP_TEXT_SIMPLE) then
		ChatEdit_AddHistory(chat.editBox)
	end
end

for i = 1, NUM_CHAT_WINDOWS do
	if i ~= 2 then
		hooksecurefunc(_G["ChatFrame"..i], "AddMessage", TypoHistory_Posthook_AddMessage)
	end
end

-- Big Trade Chat
local bigchat = false
function SlashCmdList.BIGCHAT(msg, editbox)
	if bigchat == false then
		ChatFrame1:SetSize(400, 400)
		bigchat = true
		K.Print(L_CHAT_BIGCHAT_ON)
	else
		ChatFrame1:SetSize(400, 150)
		bigchat = false
		K.Print(L_CHAT_BIGCHAT_OFF)
	end
end
SLASH_BIGCHAT1 = "/bigchat"