--!strict
-- src/client/ui/components/ToastNotification.luau
-- MODULE 07: 07-ui-navigation-and-screens
-- Non-intrusive Toast Notification banner for UI feedback

local UITheme = require(script.Parent.Parent.UITheme)

local ToastNotification = {}

export type ToastMessage = {
	message: string,
	category: "INFO" | "SUCCESS" | "WARNING" | "ERROR",
	timestamp: number,
}

local lastToast: ToastMessage? = nil
local toastLabel: TextLabel? = nil

function ToastNotification.Mount(parent: Instance): TextLabel
	local lbl = Instance.new("TextLabel")
	lbl.Name = "ToastNotificationBanner"
	lbl.Size = UDim2.new(0, 420, 0, 40)
	lbl.Position = UDim2.new(0.5, -210, 0, 74)
	lbl.BackgroundColor3 = UITheme.Colors.BackgroundElevated
	lbl.Font = UITheme.Fonts.SubHeader
	lbl.TextColor3 = UITheme.Colors.TextPrimary
	lbl.TextSize = 15
	lbl.Text = ""
	lbl.Visible = false
	UITheme.ApplyCornerAndStroke(lbl, UITheme.CornerRadius.Medium, UITheme.Colors.AccentCyan, 1.5)
	lbl.Parent = parent
	toastLabel = lbl
	return lbl
end

function ToastNotification.Show(message: string, category: ("INFO" | "SUCCESS" | "WARNING" | "ERROR")?)
	local resolvedCategory: "INFO" | "SUCCESS" | "WARNING" | "ERROR" = category or "INFO"
	lastToast = {
		message = message,
		category = resolvedCategory,
		timestamp = os.clock(),
	}

	if toastLabel then
		toastLabel.Text = message
		toastLabel.Visible = true
	end
end

function ToastNotification.Hide()
	if toastLabel then
		toastLabel.Visible = false
	end
end

function ToastNotification.GetLastToast(): ToastMessage?
	return lastToast
end

return ToastNotification
