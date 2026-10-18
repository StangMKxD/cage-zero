--!strict
-- src/client/init.client.luau
-- MODULE 08: 08-integration-and-uat
-- Client Bootstrapper initializing Network, UIManager + 11 Screens, and all 6 Client Controllers

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Network = require(Shared:WaitForChild("Network"))

local UIFolder = script:WaitForChild("ui")
local UIManager = require(UIFolder:WaitForChild("UIManager"))
local ScreensFolder = UIFolder:WaitForChild("screens")

-- Require all 11 screens so they register with UIManager
require(ScreensFolder:WaitForChild("MainMenuScreen"))
require(ScreensFolder:WaitForChild("ModeSelectScreen"))
require(ScreensFolder:WaitForChild("PreMatchLobbyScreen"))
require(ScreensFolder:WaitForChild("LockerScreen"))
require(ScreensFolder:WaitForChild("SummonGachaScreen"))
require(ScreensFolder:WaitForChild("TradingPlazaScreen"))
require(ScreensFolder:WaitForChild("MatchHUDScreen"))
require(ScreensFolder:WaitForChild("DuelChoiceModal"))
require(ScreensFolder:WaitForChild("ParryPromptOverlay"))
require(ScreensFolder:WaitForChild("FreeKickOverlay"))
require(ScreensFolder:WaitForChild("PostMatchSummaryScreen"))

local ControllersFolder = script:WaitForChild("controllers")
local InputController = require(ControllersFolder:WaitForChild("InputController"))
local ParryIndicatorController = require(ControllersFolder:WaitForChild("ParryIndicatorController"))
local DuelUIController = require(ControllersFolder:WaitForChild("DuelUIController"))
local CameraCutsceneController = require(ControllersFolder:WaitForChild("CameraCutsceneController"))
local FreeKickUIController = require(ControllersFolder:WaitForChild("FreeKickUIController"))
local EventVFXController = require(ControllersFolder:WaitForChild("EventVFXController"))

-- 1. Initialize Network client cache
Network.Init()

-- 2. Initialize Single UI Router & Screens
UIManager.Init()

-- 3. Initialize all Client Controllers
InputController.Init()
ParryIndicatorController.Init()
DuelUIController.Init()
CameraCutsceneController.Init()
FreeKickUIController.Init()
EventVFXController.Init()
