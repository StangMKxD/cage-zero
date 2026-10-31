--!strict
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Run=game:GetService("RunService")
local Shared=RS:WaitForChild("Shared")
local Animation=require(Shared.FootballAnimation)
local Config=require(Shared.configs.FootballActionConfigs)
local Provider=game:GetService("KeyframeSequenceProvider")
local Controller={}
local initialized=false
local generation=0
local id: string?=nil
local connection: RBXScriptConnection?=nil
local track: AnimationTrack?=nil
local function bind(char: Model)
	generation+=1;local gen=generation
	if connection then connection:Disconnect() end
	if track then track:Destroy();track=nil end
	local hum=char:WaitForChild("Humanoid",10);local animator=hum and hum:WaitForChild("Animator",5)
	if not animator or generation~=gen or not Run:IsStudio() then return end
	if not id then
		local seq=Animation.Build("Turn",{loop=false,priority=Enum.AnimationPriority.Action})
		id=Provider:RegisterKeyframeSequence(seq);seq:Destroy()
	end
	local a=Instance.new("Animation");a.Name="ReverseTurn_fcecd793";a.AnimationId=id :: string
	local current=animator:LoadAnimation(a);a:Destroy();current.Priority=Enum.AnimationPriority.Action;current.Looped=false;track=current
	connection=char:GetAttributeChangedSignal("SprintReverseStarted"):Connect(function()
		if char:GetAttribute("IsSprinting")~=true or char:GetAttribute("ShotActive")==true or char:GetAttribute("ShotCharging")==true or hum.FloorMaterial==Enum.Material.Air then return end
		local stamp=char:GetAttribute("SprintReverseStarted")
		local elapsed=if typeof(stamp)=="number" then workspace:GetServerTimeNow()-stamp else 0
		if elapsed>=Config.TurnDurationSec then return end
		current:Play(0.10,1,1.633/Config.TurnDurationSec)
		current.TimePosition=math.max(0,elapsed)*1.633/Config.TurnDurationSec
	end)
end
function Controller.Init()
	if initialized then return end;initialized=true
	local player=Players.LocalPlayer
	player.CharacterAdded:Connect(function(c) task.spawn(bind,c) end)
	if player.Character then task.spawn(bind,player.Character) end
end
return Controller
