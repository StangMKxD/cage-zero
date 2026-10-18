--!strict
-- src/client/ui/UIManager.luau
-- MODULE 07: 07-ui-navigation-and-screens
-- Single UI Router & State Machine managing MAIN_MENU, LOBBY_MODE, and MATCH_MODE

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Types = require(Shared:WaitForChild("Types"))

local TopCurrencyBar = require(script.Parent.components.TopCurrencyBar)
local NavigationDock = require(script.Parent.components.NavigationDock)
local ToastNotification = require(script.Parent.components.ToastNotification)

export type UIMode = Types.UIMode

export type ScreenController = {
	SetVisible: (visible: boolean) -> (),
	IsVisible: (() -> boolean)?,
	Mount: ((parent: Instance) -> Instance)?,
}

local UIManager = {}

local LOBBY_SCREENS: { [string]: boolean } = {
	ModeSelectScreen = true,
	PreMatchLobbyScreen = true,
	LockerScreen = true,
	SummonGachaScreen = true,
	TradingPlazaScreen = true,
}

local MATCH_OVERLAYS: { [string]: boolean } = {
	DuelChoiceModal = true,
	ParryPromptOverlay = true,
	FreeKickOverlay = true,
	PostMatchSummaryScreen = true,
}

local currentMode: UIMode = "MAIN_MENU"
local activeLobbyScreen: string? = nil
local activeMatchPrimaryScreen: string? = nil
local openOverlays: { [string]: boolean } = {}
local registeredScreens: { [string]: ScreenController } = {}
local screenVisibilityState: { [string]: boolean } = {}
local rootScreenGui: ScreenGui? = nil
local isInitialized = false

local function setScreenVisibility(screenName: string, visible: boolean)
	screenVisibilityState[screenName] = visible
	local controller = registeredScreens[screenName]
	if controller and controller.SetVisible then
		controller.SetVisible(visible)
	end
end

local function hideAllLobbyScreens()
	for screenName in pairs(LOBBY_SCREENS) do
		setScreenVisibility(screenName, false)
	end
	activeLobbyScreen = nil
end

local function hideAllMatchOverlays()
	for overlayName in pairs(MATCH_OVERLAYS) do
		openOverlays[overlayName] = false
		setScreenVisibility(overlayName, false)
	end
end

function UIManager.RegisterScreen(screenName: string, controller: ScreenController)
	registeredScreens[screenName] = controller
	if screenVisibilityState[screenName] == nil then
		screenVisibilityState[screenName] = false
	end
end

function UIManager.SetMode(mode: UIMode)
	currentMode = mode

	if mode == "MAIN_MENU" then
		TopCurrencyBar.SetVisible(false)
		NavigationDock.SetVisible(false)
		hideAllLobbyScreens()
		hideAllMatchOverlays()
		setScreenVisibility("MatchHUDScreen", false)
		activeMatchPrimaryScreen = nil
		setScreenVisibility("MainMenuScreen", true)
	elseif mode == "LOBBY_MODE" then
		setScreenVisibility("MainMenuScreen", false)
		hideAllMatchOverlays()
		setScreenVisibility("MatchHUDScreen", false)
		activeMatchPrimaryScreen = nil

		TopCurrencyBar.SetVisible(true)
		NavigationDock.SetVisible(true)
		-- Open default Lobby Screen (ModeSelectScreen) while guaranteeing only 1 active lobby screen
		UIManager.NavigateToScreen("ModeSelectScreen")
	elseif mode == "MATCH_MODE" then
		-- Immediately hide all Lobby UI (TopCurrencyBar, NavigationDock, and all Lobby windows)
		setScreenVisibility("MainMenuScreen", false)
		TopCurrencyBar.SetVisible(false)
		NavigationDock.SetVisible(false)
		hideAllLobbyScreens()
		hideAllMatchOverlays()

		activeMatchPrimaryScreen = "MatchHUDScreen"
		setScreenVisibility("MatchHUDScreen", true)
	end
end

function UIManager.NavigateToScreen(screenName: string): boolean
	if screenName == "MainMenuScreen" then
		UIManager.SetMode("MAIN_MENU")
		return true
	end

	if screenName == "MatchHUDScreen" then
		UIManager.SetMode("MATCH_MODE")
		return true
	end

	if screenName == "TrainingMode" then
		if currentMode ~= "LOBBY_MODE" then
			UIManager.SetMode("LOBBY_MODE")
		end
		hideAllLobbyScreens()
		ToastNotification.Show("Entered Personal Cage Training Area", "INFO")
		return true
	end

	if LOBBY_SCREENS[screenName] then
		if currentMode ~= "LOBBY_MODE" then
			currentMode = "LOBBY_MODE"
			setScreenVisibility("MainMenuScreen", false)
			hideAllMatchOverlays()
			setScreenVisibility("MatchHUDScreen", false)
			activeMatchPrimaryScreen = nil
			TopCurrencyBar.SetVisible(true)
			NavigationDock.SetVisible(true)
		end

		-- Close previous Lobby window immediately so no two Lobby screens ever overlap
		for existingLobbyScreen in pairs(LOBBY_SCREENS) do
			if existingLobbyScreen ~= screenName then
				setScreenVisibility(existingLobbyScreen, false)
			end
		end

		activeLobbyScreen = screenName
		setScreenVisibility(screenName, true)
		return true
	end

	if MATCH_OVERLAYS[screenName] then
		UIManager.OpenOverlay(screenName)
		return true
	end

	return false
end

function UIManager.OpenOverlay(overlayName: string)
	if not MATCH_OVERLAYS[overlayName] then
		return
	end

	if currentMode ~= "MATCH_MODE" then
		UIManager.SetMode("MATCH_MODE")
	end

	openOverlays[overlayName] = true
	setScreenVisibility(overlayName, true)
end

function UIManager.CloseOverlay(overlayName: string)
	if not MATCH_OVERLAYS[overlayName] then
		return
	end

	openOverlays[overlayName] = false
	setScreenVisibility(overlayName, false)
end

function UIManager.IsOverlayOpen(overlayName: string): boolean
	return openOverlays[overlayName] == true
end

function UIManager.GetMode(): UIMode
	return currentMode
end

function UIManager.GetActiveScreen(): string?
	if currentMode == "MAIN_MENU" then
		return "MainMenuScreen"
	elseif currentMode == "LOBBY_MODE" then
		return activeLobbyScreen
	elseif currentMode == "MATCH_MODE" then
		return activeMatchPrimaryScreen
	end
	return nil
end

function UIManager.IsScreenVisible(screenName: string): boolean
	return screenVisibilityState[screenName] == true
end

function UIManager.GetVisibleLobbyScreenCount(): number
	local count = 0
	for screenName in pairs(LOBBY_SCREENS) do
		if screenVisibilityState[screenName] == true then
			count += 1
		end
	end
	return count
end

function UIManager.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	NavigationDock.SetNavigationHandler(function(tabId)
		UIManager.NavigateToScreen(tabId)
	end)

	local localPlayer = Players.LocalPlayer
	if localPlayer then
		local playerGui = localPlayer:FindFirstChildOfClass("PlayerGui")
		if playerGui then
			local gui = Instance.new("ScreenGui")
			gui.Name = "CageZeroRootUI"
			gui.ResetOnSpawn = false
			gui.IgnoreGuiInset = true
			gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
			gui.Parent = playerGui
			rootScreenGui = gui

			TopCurrencyBar.Mount(gui)
			NavigationDock.Mount(gui)
			ToastNotification.Mount(gui)

			for _, controller in pairs(registeredScreens) do
				if controller.Mount then
					controller.Mount(gui)
				end
			end
		end
	end

	UIManager.SetMode("MAIN_MENU")
end

function UIManager.GetRootGui(): ScreenGui?
	return rootScreenGui
end

return UIManager
