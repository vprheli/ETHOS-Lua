local function init()
system.registerLayout(
	{	key="myl3", 
		widgets={
			{x=8, y=100, w=256, h=100},			
			{x=8, y=208, w=256, h=100},	
			{x=8, y=316, w=256, h=100},
			{x=272, y=100, w=256, h=316},
			{x=536, y=100, w=256, h=154},
			{x=536, y=264, w=256, h=154},
		}
	}
)
end
return {init=init}