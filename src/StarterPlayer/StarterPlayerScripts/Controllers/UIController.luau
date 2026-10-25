--!strict
--[[
    UIController.luau
    Authoritative client-side interface manager:
    - TrapControlGui: Responsive trap cards with real-time countdowns, hotkeys, and cooldown fills
    - RoundStatusGui: Top bar with status pill, clock, alive runners & controllers count
    - RunnerHUD: Checkpoint progress & survival objective
    - ResultsGui: End of round victory banner
    - DevPanel: Toggle role and solo test utilities
]]

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Enums = require(Shared:WaitForChild("Enums"))
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local TrapConfig = require(Shared:WaitForChild("TrapConfig"))

local UIController = {}

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local mainGui: ScreenGui
local roundStatusFrame: Frame
local trapControlFrame: Frame
local runnerHudFrame: Frame
local resultsFrame: Frame
local devPanelFrame: Frame

local timeLabel: TextLabel
local statusLabel: TextLabel
local runnersCountLabel: TextLabel
local controllersCountLabel: TextLabel

local checkpointLabel: TextLabel
local resultsTitleLabel: TextLabel
local resultsSubtitleLabel: TextLabel

type TrapCardElements = {
    Card: TextButton,
    Title: TextLabel,
    Description: TextLabel,
    StatusBadge: TextLabel,
    CooldownText: TextLabel,
    ProgressBar: Frame,
    ProgressFill: Frame,
    Stroke: UIStroke,
    Icon: TextLabel,
}

local trapCards: { [string]: TrapCardElements } = {}
local TrapClientController: any
local currentRole: string = Enums.PlayerState.Lobby

function UIController.Init(deps: { TrapClientController: any })
    TrapClientController = deps.TrapClientController

    -- Create root ScreenGui
    mainGui = Instance.new("ScreenGui")
    mainGui.Name = "DeathrunMainGui"
    mainGui.ResetOnSpawn = false
    mainGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    mainGui.Parent = playerGui

    -- Build all UI components
    UIController.BuildRoundStatusHUD()
    UIController.BuildTrapControlPanel()
    UIController.BuildRunnerHUD()
    UIController.BuildResultsModal()
    UIController.BuildDevPanel()

    -- Hook up real-time frame tick for smooth cooldown countdowns
    RunService.RenderStepped:Connect(function()
        UIController.UpdateCooldownVisuals()
    end)
end

function UIController.BuildRoundStatusHUD()
    roundStatusFrame = Instance.new("Frame")
    roundStatusFrame.Name = "RoundStatusHUD"
    roundStatusFrame.Size = UDim2.new(0, 480, 0, 52)
    roundStatusFrame.Position = UDim2.new(0.5, -240, 0, 14)
    roundStatusFrame.BackgroundColor3 = Color3.fromRGB(16, 18, 24)
    roundStatusFrame.BackgroundTransparency = 0.2
    roundStatusFrame.BorderSizePixel = 0
    roundStatusFrame.Parent = mainGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = roundStatusFrame

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1.5
    stroke.Color = Color3.fromRGB(40, 45, 60)
    stroke.Parent = roundStatusFrame

    -- Status Pill (Left)
    statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "StatusLabel"
    statusLabel.Size = UDim2.new(0, 170, 0, 32)
    statusLabel.Position = UDim2.new(0, 10, 0, 10)
    statusLabel.BackgroundColor3 = Color3.fromRGB(24, 28, 38)
    statusLabel.BackgroundTransparency = 0.3
    statusLabel.Font = Enum.Font.GothamBold
    statusLabel.TextSize = 13
    statusLabel.TextColor3 = Color3.fromRGB(0, 200, 255)
    statusLabel.Text = "WAITING FOR PLAYERS"
    statusLabel.Parent = roundStatusFrame
    local statusCorner = Instance.new("UICorner")
    statusCorner.CornerRadius = UDim.new(0, 6)
    statusCorner.Parent = statusLabel

    -- Clock Timer (Center)
    timeLabel = Instance.new("TextLabel")
    timeLabel.Name = "TimeLabel"
    timeLabel.Size = UDim2.new(0, 90, 0, 36)
    timeLabel.Position = UDim2.new(0.5, -45, 0, 8)
    timeLabel.BackgroundTransparency = 1
    timeLabel.Font = Enum.Font.GothamBlack
    timeLabel.TextSize = 22
    timeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    timeLabel.Text = "00:00"
    timeLabel.Parent = roundStatusFrame

    -- Team Counts (Right)
    local countsContainer = Instance.new("Frame")
    countsContainer.Name = "CountsContainer"
    countsContainer.Size = UDim2.new(0, 180, 0, 34)
    countsContainer.Position = UDim2.new(1, -190, 0, 9)
    countsContainer.BackgroundTransparency = 1
    countsContainer.Parent = roundStatusFrame

    runnersCountLabel = Instance.new("TextLabel")
    runnersCountLabel.Name = "RunnersCount"
    runnersCountLabel.Size = UDim2.new(0, 85, 1, 0)
    runnersCountLabel.Position = UDim2.new(0, 0, 0, 0)
    runnersCountLabel.BackgroundColor3 = Color3.fromRGB(20, 40, 30)
    runnersCountLabel.BackgroundTransparency = 0.3
    runnersCountLabel.Font = Enum.Font.GothamBold
    runnersCountLabel.TextSize = 12
    runnersCountLabel.TextColor3 = Color3.fromRGB(80, 255, 140)
    runnersCountLabel.Text = "🟢 0 Runners"
    runnersCountLabel.Parent = countsContainer
    local rCorner = Instance.new("UICorner")
    rCorner.CornerRadius = UDim.new(0, 6)
    rCorner.Parent = runnersCountLabel

    controllersCountLabel = Instance.new("TextLabel")
    controllersCountLabel.Name = "ControllersCount"
    controllersCountLabel.Size = UDim2.new(0, 85, 1, 0)
    controllersCountLabel.Position = UDim2.new(0, 92, 0, 0)
    controllersCountLabel.BackgroundColor3 = Color3.fromRGB(45, 20, 25)
    controllersCountLabel.BackgroundTransparency = 0.3
    controllersCountLabel.Font = Enum.Font.GothamBold
    controllersCountLabel.TextSize = 12
    controllersCountLabel.TextColor3 = Color3.fromRGB(255, 90, 90)
    controllersCountLabel.Text = "🔴 0 Traps"
    controllersCountLabel.Parent = countsContainer
    local cCorner = Instance.new("UICorner")
    cCorner.CornerRadius = UDim.new(0, 6)
    cCorner.Parent = controllersCountLabel
end

function UIController.BuildTrapControlPanel()
    trapControlFrame = Instance.new("Frame")
    trapControlFrame.Name = "TrapControlPanel"
    trapControlFrame.Size = UDim2.new(0, 960, 0, 160)
    trapControlFrame.Position = UDim2.new(0.5, -480, 1, -175)
    trapControlFrame.BackgroundColor3 = Color3.fromRGB(14, 16, 22)
    trapControlFrame.BackgroundTransparency = 0.15
    trapControlFrame.BorderSizePixel = 0
    trapControlFrame.Visible = false
    trapControlFrame.Parent = mainGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = trapControlFrame

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 2
    stroke.Color = Color3.fromRGB(255, 75, 75)
    stroke.Parent = trapControlFrame

    -- Header Title
    local header = Instance.new("TextLabel")
    header.Name = "Header"
    header.Size = UDim2.new(1, -20, 0, 24)
    header.Position = UDim2.new(0, 10, 0, 6)
    header.BackgroundTransparency = 1
    header.Font = Enum.Font.GothamBlack
    header.TextSize = 13
    header.TextColor3 = Color3.fromRGB(255, 100, 100)
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.Text = "⚠️ TRAP CONTROL SYSTEM — SELECT TRAP OR PRESS HOTKEYS [1-6]"
    header.Parent = trapControlFrame

    -- Grid of 6 trap cards
    local grid = Instance.new("Frame")
    grid.Name = "TrapGrid"
    grid.Size = UDim2.new(1, -20, 0, 120)
    grid.Position = UDim2.new(0, 10, 0, 32)
    grid.BackgroundTransparency = 1
    grid.Parent = trapControlFrame

    local listLayout = Instance.new("UIListLayout")
    listLayout.FillDirection = Enum.FillDirection.Horizontal
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    listLayout.Padding = UDim.new(0, 8)
    listLayout.Parent = grid

    for _, trapId in ipairs(TrapConfig.Order) do
        local def = TrapConfig.Traps[trapId]
        local card = Instance.new("TextButton")
        card.Name = "Card_" .. trapId
        card.Size = UDim2.new(0, 148, 0, 118)
        card.BackgroundColor3 = Color3.fromRGB(22, 25, 34)
        card.AutoButtonColor = false
        card.Text = ""
        card.Parent = grid

        local cardCorner = Instance.new("UICorner")
        cardCorner.CornerRadius = UDim.new(0, 8)
        cardCorner.Parent = card

        local cardStroke = Instance.new("UIStroke")
        cardStroke.Thickness = 1.5
        cardStroke.Color = Color3.fromRGB(46, 204, 113)
        cardStroke.Parent = card

        -- Icon + Keybind badge
        local icon = Instance.new("TextLabel")
        icon.Name = "Icon"
        icon.Size = UDim2.new(0, 28, 0, 24)
        icon.Position = UDim2.new(0, 8, 0, 6)
        icon.BackgroundTransparency = 1
        icon.TextSize = 18
        icon.Text = def.Icon
        icon.Parent = card

        local keyBadge = Instance.new("TextLabel")
        keyBadge.Name = "KeyBadge"
        keyBadge.Size = UDim2.new(0, 26, 0, 18)
        keyBadge.Position = UDim2.new(1, -34, 0, 8)
        keyBadge.BackgroundColor3 = Color3.fromRGB(35, 40, 55)
        keyBadge.Font = Enum.Font.GothamBold
        keyBadge.TextSize = 11
        keyBadge.TextColor3 = Color3.fromRGB(0, 200, 255)
        keyBadge.Text = "[" .. def.Keybind .. "]"
        keyBadge.Parent = card
        local kCorner = Instance.new("UICorner")
        kCorner.CornerRadius = UDim.new(0, 4)
        kCorner.Parent = keyBadge

        -- Title
        local title = Instance.new("TextLabel")
        title.Name = "Title"
        title.Size = UDim2.new(1, -16, 0, 20)
        title.Position = UDim2.new(0, 8, 0, 30)
        title.BackgroundTransparency = 1
        title.Font = Enum.Font.GothamBold
        title.TextSize = 12
        title.TextColor3 = Color3.fromRGB(255, 255, 255)
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.TextTruncate = Enum.TextTruncate.AtEnd
        title.Text = def.DisplayName
        title.Parent = card

        -- Description
        local desc = Instance.new("TextLabel")
        desc.Name = "Description"
        desc.Size = UDim2.new(1, -16, 0, 24)
        desc.Position = UDim2.new(0, 8, 0, 48)
        desc.BackgroundTransparency = 1
        desc.Font = Enum.Font.Gotham
        desc.TextSize = 9
        desc.TextColor3 = Color3.fromRGB(160, 170, 190)
        desc.TextWrapped = true
        desc.TextXAlignment = Enum.TextXAlignment.Left
        desc.TextYAlignment = Enum.TextYAlignment.Top
        desc.Text = def.Description
        desc.Parent = card

        -- Progress bar track
        local progBar = Instance.new("Frame")
        progBar.Name = "ProgressBar"
        progBar.Size = UDim2.new(1, -16, 0, 4)
        progBar.Position = UDim2.new(0, 8, 0, 78)
        progBar.BackgroundColor3 = Color3.fromRGB(35, 40, 50)
        progBar.BorderSizePixel = 0
        progBar.Parent = card

        local progFill = Instance.new("Frame")
        progFill.Name = "Fill"
        progFill.Size = UDim2.new(1, 0, 1, 0)
        progFill.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
        progFill.BorderSizePixel = 0
        progFill.Parent = progBar

        -- Status Pill / Cooldown Text
        local statusBadge = Instance.new("TextLabel")
        statusBadge.Name = "StatusBadge"
        statusBadge.Size = UDim2.new(0, 60, 0, 20)
        statusBadge.Position = UDim2.new(0, 8, 0, 88)
        statusBadge.BackgroundColor3 = Color3.fromRGB(20, 60, 35)
        statusBadge.Font = Enum.Font.GothamBold
        statusBadge.TextSize = 10
        statusBadge.TextColor3 = Color3.fromRGB(46, 204, 113)
        statusBadge.Text = "READY"
        statusBadge.Parent = card
        local sCorner = Instance.new("UICorner")
        sCorner.CornerRadius = UDim.new(0, 4)
        sCorner.Parent = statusBadge

        local cdText = Instance.new("TextLabel")
        cdText.Name = "CooldownText"
        cdText.Size = UDim2.new(0, 60, 0, 20)
        cdText.Position = UDim2.new(1, -68, 0, 88)
        cdText.BackgroundTransparency = 1
        cdText.Font = Enum.Font.GothamMedium
        cdText.TextSize = 10
        cdText.TextColor3 = Color3.fromRGB(150, 160, 175)
        cdText.TextXAlignment = Enum.TextXAlignment.Right
        cdText.Text = string.format("%ds CD", def.Cooldown)
        cdText.Parent = card

        -- Click connection
        card.MouseButton1Click:Connect(function()
            if TrapClientController then
                TrapClientController.RequestActivation(trapId)
            end
        end)

        trapCards[trapId] = {
            Card = card,
            Title = title,
            Description = desc,
            StatusBadge = statusBadge,
            CooldownText = cdText,
            ProgressBar = progBar,
            ProgressFill = progFill,
            Stroke = cardStroke,
            Icon = icon,
        }
    end
end

function UIController.BuildRunnerHUD()
    runnerHudFrame = Instance.new("Frame")
    runnerHudFrame.Name = "RunnerHUD"
    runnerHudFrame.Size = UDim2.new(0, 320, 0, 64)
    runnerHudFrame.Position = UDim2.new(0.5, -160, 1, -85)
    runnerHudFrame.BackgroundColor3 = Color3.fromRGB(16, 20, 26)
    runnerHudFrame.BackgroundTransparency = 0.2
    runnerHudFrame.BorderSizePixel = 0
    runnerHudFrame.Visible = false
    runnerHudFrame.Parent = mainGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = runnerHudFrame

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1.5
    stroke.Color = Color3.fromRGB(80, 255, 140)
    stroke.Parent = runnerHudFrame

    local objLabel = Instance.new("TextLabel")
    objLabel.Name = "Objective"
    objLabel.Size = UDim2.new(1, -20, 0, 24)
    objLabel.Position = UDim2.new(0, 10, 0, 6)
    objLabel.BackgroundTransparency = 1
    objLabel.Font = Enum.Font.GothamBold
    objLabel.TextSize = 13
    objLabel.TextColor3 = Color3.fromRGB(80, 255, 140)
    objLabel.Text = "RUNNER OBJECTIVE: ESCAPE!"
    objLabel.Parent = runnerHudFrame

    checkpointLabel = Instance.new("TextLabel")
    checkpointLabel.Name = "CheckpointProgress"
    checkpointLabel.Size = UDim2.new(1, -20, 0, 22)
    checkpointLabel.Position = UDim2.new(0, 10, 0, 32)
    checkpointLabel.BackgroundTransparency = 1
    checkpointLabel.Font = Enum.Font.GothamMedium
    checkpointLabel.TextSize = 12
    checkpointLabel.TextColor3 = Color3.fromRGB(200, 220, 240)
    checkpointLabel.Text = "Checkpoint: 0 / 3 Reached"
    checkpointLabel.Parent = runnerHudFrame
end

function UIController.BuildResultsModal()
    resultsFrame = Instance.new("Frame")
    resultsFrame.Name = "ResultsModal"
    resultsFrame.Size = UDim2.new(0, 520, 0, 220)
    resultsFrame.Position = UDim2.new(0.5, -260, 0.5, -110)
    resultsFrame.BackgroundColor3 = Color3.fromRGB(15, 18, 26)
    resultsFrame.BackgroundTransparency = 0.1
    resultsFrame.BorderSizePixel = 0
    resultsFrame.Visible = false
    resultsFrame.ZIndex = 200
    resultsFrame.Parent = mainGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 14)
    corner.Parent = resultsFrame

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 2.5
    stroke.Color = Color3.fromRGB(255, 215, 0)
    stroke.Parent = resultsFrame

    resultsTitleLabel = Instance.new("TextLabel")
    resultsTitleLabel.Name = "Title"
    resultsTitleLabel.Size = UDim2.new(1, -40, 0, 48)
    resultsTitleLabel.Position = UDim2.new(0, 20, 0, 20)
    resultsTitleLabel.BackgroundTransparency = 1
    resultsTitleLabel.Font = Enum.Font.GothamBlack
    resultsTitleLabel.TextSize = 28
    resultsTitleLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    resultsTitleLabel.Text = "ROUND FINISHED"
    resultsTitleLabel.Parent = resultsFrame

    resultsSubtitleLabel = Instance.new("TextLabel")
    resultsSubtitleLabel.Name = "Subtitle"
    resultsSubtitleLabel.Size = UDim2.new(1, -40, 0, 36)
    resultsSubtitleLabel.Position = UDim2.new(0, 20, 0, 74)
    resultsSubtitleLabel.BackgroundTransparency = 1
    resultsSubtitleLabel.Font = Enum.Font.GothamBold
    resultsSubtitleLabel.TextSize = 16
    resultsSubtitleLabel.TextColor3 = Color3.fromRGB(220, 230, 245)
    resultsSubtitleLabel.Text = "All runners were eliminated!"
    resultsSubtitleLabel.Parent = resultsFrame

    local divider = Instance.new("Frame")
    divider.Size = UDim2.new(1, -40, 0, 1)
    divider.Position = UDim2.new(0, 20, 0, 120)
    divider.BackgroundColor3 = Color3.fromRGB(45, 50, 70)
    divider.BorderSizePixel = 0
    divider.Parent = resultsFrame

    local timerNotice = Instance.new("TextLabel")
    timerNotice.Name = "TimerNotice"
    timerNotice.Size = UDim2.new(1, -40, 0, 40)
    timerNotice.Position = UDim2.new(0, 20, 0, 140)
    timerNotice.BackgroundTransparency = 1
    timerNotice.Font = Enum.Font.Gotham
    timerNotice.TextSize = 13
    timerNotice.TextColor3 = Color3.fromRGB(150, 165, 185)
    timerNotice.Text = "Next round begins shortly... Teleporting back to lobby."
    timerNotice.Parent = resultsFrame
end

function UIController.BuildDevPanel()
    if not GameConfig.DevMode then return end

    devPanelFrame = Instance.new("Frame")
    devPanelFrame.Name = "DevPanel"
    devPanelFrame.Size = UDim2.new(0, 200, 0, 80)
    devPanelFrame.Position = UDim2.new(1, -210, 0, 14)
    devPanelFrame.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
    devPanelFrame.BackgroundTransparency = 0.25
    devPanelFrame.BorderSizePixel = 0
    devPanelFrame.Parent = mainGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = devPanelFrame

    local devTitle = Instance.new("TextLabel")
    devTitle.Size = UDim2.new(1, 0, 0, 20)
    devTitle.BackgroundTransparency = 1
    devTitle.Font = Enum.Font.GothamBold
    devTitle.TextSize = 11
    devTitle.TextColor3 = Color3.fromRGB(255, 170, 0)
    devTitle.Text = "🛠️ DEV TESTING PANEL"
    devTitle.Parent = devPanelFrame

    local switchBtn = Instance.new("TextButton")
    switchBtn.Name = "SwitchRoleButton"
    switchBtn.Size = UDim2.new(1, -16, 0, 28)
    switchBtn.Position = UDim2.new(0, 8, 0, 24)
    switchBtn.BackgroundColor3 = Color3.fromRGB(35, 45, 65)
    switchBtn.Font = Enum.Font.GothamBold
    switchBtn.TextSize = 11
    switchBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    switchBtn.Text = "Switch Role (Runner/Trap)"
    switchBtn.Parent = devPanelFrame
    local bCorner = Instance.new("UICorner")
    bCorner.CornerRadius = UDim.new(0, 6)
    bCorner.Parent = switchBtn

    local devNotice = Instance.new("TextLabel")
    devNotice.Size = UDim2.new(1, -16, 0, 16)
    devNotice.Position = UDim2.new(0, 8, 0, 56)
    devNotice.BackgroundTransparency = 1
    devNotice.Font = Enum.Font.Gotham
    devNotice.TextSize = 9
    devNotice.TextColor3 = Color3.fromRGB(150, 160, 180)
    devNotice.Text = "Solo test mode enabled"
    devNotice.Parent = devPanelFrame

    switchBtn.MouseButton1Click:Connect(function()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        local toggleRemote = remotes and remotes:FindFirstChild("DevToggleRole") :: RemoteEvent?
        if toggleRemote then
            toggleRemote:FireServer()
        end
    end)
end

function UIController.UpdateRole(newRole: string)
    currentRole = newRole

    if newRole == Enums.PlayerState.TrapController then
        trapControlFrame.Visible = true
        runnerHudFrame.Visible = false
    elseif newRole == Enums.PlayerState.Runner then
        trapControlFrame.Visible = false
        runnerHudFrame.Visible = true
    else
        trapControlFrame.Visible = false
        runnerHudFrame.Visible = false
    end
end

function UIController.UpdateRoundStatus(state: string, timeRemaining: number, extra: any)
    local mins = math.floor(timeRemaining / 60)
    local secs = timeRemaining % 60
    timeLabel.Text = string.format("%02d:%02d", mins, secs)

    if extra and extra.RunnersCount ~= nil then
        runnersCountLabel.Text = string.format("🟢 %d Runners", extra.RunnersCount)
    end
    if extra and extra.ControllersCount ~= nil then
        controllersCountLabel.Text = string.format("🔴 %d Traps", extra.ControllersCount)
    end

    if state == Enums.RoundState.WaitingForPlayers then
        statusLabel.Text = "WAITING FOR PLAYERS"
        statusLabel.TextColor3 = Color3.fromRGB(255, 170, 0)
        resultsFrame.Visible = false
    elseif state == Enums.RoundState.Intermission then
        statusLabel.Text = string.format("INTERMISSION (%ds)", timeRemaining)
        statusLabel.TextColor3 = Color3.fromRGB(0, 200, 255)
        resultsFrame.Visible = false
    elseif state == Enums.RoundState.InProgress then
        statusLabel.Text = "DEATHRUN ACTIVE"
        statusLabel.TextColor3 = Color3.fromRGB(80, 255, 140)
        resultsFrame.Visible = false
    elseif state == Enums.RoundState.RoundEnded then
        statusLabel.Text = "ROUND FINISHED"
        statusLabel.TextColor3 = Color3.fromRGB(255, 215, 0)

        if extra and extra.WinnerTeam then
            resultsFrame.Visible = true
            if extra.WinnerTeam == "Runners" then
                resultsTitleLabel.Text = "RUNNERS ESCAPED!"
                resultsTitleLabel.TextColor3 = Color3.fromRGB(80, 255, 120)
                resultsSubtitleLabel.Text = "A runner reached the finish line!"
            else
                resultsTitleLabel.Text = "TRAP CONTROLLERS WIN!"
                resultsTitleLabel.TextColor3 = Color3.fromRGB(255, 75, 75)
                resultsSubtitleLabel.Text = extra.WinReason == Enums.WinReason.TimeExpired 
                    and "Time expired! Controllers defended the course."
                    or "All runners were eliminated!"
            end
        end
    end
end

function UIController.UpdateCheckpoint(index: number)
    if checkpointLabel then
        checkpointLabel.Text = string.format("Checkpoint: %d / %d Reached", index, GameConfig.TotalCheckpoints)
    end
end

function UIController.UpdateCooldownVisuals()
    if not trapControlFrame.Visible then return end

    local now = os.clock()

    for trapId, cardElements in pairs(trapCards) do
        local state = TrapClientController and TrapClientController.GetTrapState(trapId)
        if state then
            local def = TrapConfig.Traps[trapId]
            local elapsedSinceUpdate = now - state.LastUpdated
            local currentCooldownRemaining = math.max(0, state.CooldownRemaining - elapsedSinceUpdate)
            local currentActiveRemaining = math.max(0, state.ActiveRemaining - elapsedSinceUpdate)

            if state.IsActive or currentActiveRemaining > 0 then
                -- Trap is currently executing
                cardElements.StatusBadge.Text = "ACTIVE"
                cardElements.StatusBadge.BackgroundColor3 = Color3.fromRGB(80, 60, 15)
                cardElements.StatusBadge.TextColor3 = Color3.fromRGB(255, 190, 20)
                cardElements.Stroke.Color = Color3.fromRGB(255, 190, 20)
                cardElements.CooldownText.Text = string.format("%.1fs", currentActiveRemaining)
                cardElements.ProgressFill.Size = UDim2.new(1, 0, 1, 0)
                cardElements.ProgressFill.BackgroundColor3 = Color3.fromRGB(255, 190, 20)
            elseif not state.IsAvailable or currentCooldownRemaining > 0 then
                -- Trap is on cooldown
                cardElements.StatusBadge.Text = "COOLDOWN"
                cardElements.StatusBadge.BackgroundColor3 = Color3.fromRGB(60, 20, 25)
                cardElements.StatusBadge.TextColor3 = Color3.fromRGB(240, 75, 75)
                cardElements.Stroke.Color = Color3.fromRGB(180, 50, 50)
                cardElements.CooldownText.Text = string.format("%.1fs", currentCooldownRemaining)

                local fraction = 1 - (currentCooldownRemaining / def.Cooldown)
                cardElements.ProgressFill.Size = UDim2.new(math.clamp(fraction, 0, 1), 0, 1, 0)
                cardElements.ProgressFill.BackgroundColor3 = Color3.fromRGB(240, 75, 75)
            else
                -- Trap is READY
                cardElements.StatusBadge.Text = "READY"
                cardElements.StatusBadge.BackgroundColor3 = Color3.fromRGB(20, 60, 35)
                cardElements.StatusBadge.TextColor3 = Color3.fromRGB(46, 204, 113)
                cardElements.Stroke.Color = Color3.fromRGB(46, 204, 113)
                cardElements.CooldownText.Text = string.format("%ds CD", def.Cooldown)
                cardElements.ProgressFill.Size = UDim2.new(1, 0, 1, 0)
                cardElements.ProgressFill.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
            end
        end
    end
end

return UIController
