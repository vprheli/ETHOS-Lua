local function init()
  local version = system.getVersion()
  local board   = version.board
  if string.find(board,"20") then    
    system.registerLayout(
      {	key="myl1", 
        widgets={
          {x=37, y=100, w=300, h=280},	--Image
          {x=350, y=100, w=200, h=86},	--ValueR1C1
          {x=563, y=100, w=200, h=86},	--ValueR1C2
          {x=350, y=197, w=200, h=86},	--ValueR2C1
          {x=563, y=197, w=200, h=86},	--ValueR2C2
          {x=350, y=294, w=200, h=86},	--ValueR3C1
          {x=563, y=294, w=200, h=86}	--ValueR3C2
          
        }, 
        trims={
          {x=60, y=380, w=300, h=37}, 	--T4
          {x=3, y=110, w=36, h=274}, 	--T3
          {x=761, y=110, w=36, h=274}, 	--T2
          {x=480, y=380, w=300, h=37} 	--T1

        }

      }
    )
  end
end
return {init=init}