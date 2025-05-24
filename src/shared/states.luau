local TweenService = game:GetService("TweenService")
local Create = TweenService.Create

return {
	exampleState = function(part: BasePart, int: number)
		for count = int, 15, 1 do
			Create(
				TweenService,
				part,
				TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 0, false, 0),
				{
					Color = Color3.fromRGB(math.random(1, 255), math.random(1, 255), math.random(1, 255)),
					Size = Vector3.new(math.random(1, 255), math.random(1, 255), math.random(1, 255)),
				}
			)
		end
	end,
}
