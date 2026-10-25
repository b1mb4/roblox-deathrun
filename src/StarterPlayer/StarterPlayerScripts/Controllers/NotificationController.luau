--!strict
--[[
    NotificationController.luau
    Displays animated HUD toast announcements for round events, eliminations, and checkpoints.
]]

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local NotificationController = {}
local screenGui: ScreenGui
local bannerContainer: Frame
local titleLabel: TextLabel
local subtitleLabel: TextLabel
local currentTween: Tween? = nil

function NotificationController.Init(gui: ScreenGui)
    screenGui = gui

    bannerContainer = Instance.new("Frame")
    bannerContainer.Name = "AnnouncementBanner"
    bannerContainer.Size = UDim2.new(0, 480, 0, 70)
    bannerContainer.Position = UDim2.new(0.5, -240, -0.2, 0)
    bannerContainer.BackgroundColor3 = Color3.fromRGB(15, 17, 24)
    bannerContainer.BackgroundTransparency = 0.15
    bannerContainer.BorderSizePixel = 0
    bannerContainer.Visible = false
    bannerContainer.ZIndex = 100
    bannerContainer.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = bannerContainer

    local stroke = Instance.new("UIStroke")
    stroke.Name = "BorderStroke"
    stroke.Thickness = 2
    stroke.Color = Color3.fromRGB(0, 170, 255)
    stroke.Parent = bannerContainer

    titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, -20, 0, 32)
    titleLabel.Position = UDim2.new(0, 10, 0, 6)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 20
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.Text = "ROUND STARTED"
    titleLabel.Parent = bannerContainer

    subtitleLabel = Instance.new("TextLabel")
    subtitleLabel.Name = "Subtitle"
    subtitleLabel.Size = UDim2.new(1, -20, 0, 24)
    subtitleLabel.Position = UDim2.new(0, 10, 0, 38)
    subtitleLabel.BackgroundTransparency = 1
    subtitleLabel.Font = Enum.Font.GothamMedium
    subtitleLabel.TextSize = 14
    subtitleLabel.TextColor3 = Color3.fromRGB(200, 210, 230)
    subtitleLabel.Text = "Survive to reach the finish!"
    subtitleLabel.Parent = bannerContainer
end

function NotificationController.ShowBanner(title: string, subtitle: string, accentColor: Color3?)
    if not bannerContainer then return end

    titleLabel.Text = string.upper(title)
    subtitleLabel.Text = subtitle

    local color = accentColor or Color3.fromRGB(0, 170, 255)
    titleLabel.TextColor3 = color
    local stroke = bannerContainer:FindFirstChild("BorderStroke") :: UIStroke?
    if stroke then
        stroke.Color = color
    end

    bannerContainer.Visible = true

    -- Animate slide in from top
    bannerContainer.Position = UDim2.new(0.5, -240, -0.15, 0)
    local slideIn = TweenService:Create(bannerContainer, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, -240, 0.08, 0)
    })
    slideIn:Play()

    task.spawn(function()
        task.wait(2.8)
        local slideOut = TweenService:Create(bannerContainer, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Position = UDim2.new(0.5, -240, -0.2, 0)
        })
        slideOut:Play()
        slideOut.Completed:Wait()
        bannerContainer.Visible = false
    end)
end

return NotificationController
