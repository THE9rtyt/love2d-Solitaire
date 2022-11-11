local displayHandler = require "lib.displayHandler"
local fieldHandler = require "lib.fieldHandler"


local mouseHandler = {}

-----------------------------------------
--Private Vars
-----------------------------------------


-----------------------------------------
-- I/O Methods
-----------------------------------------
function mouseHandler.init()--load field settings into display handler for field size
  
end

-------------------
--private function
-------------------

----------------------------------------
-- public method for Mouse Click Events
----------------------------------------
function mouseHandler.mousePressed(x,y, button, status)
  if button == 1 then
    local hit, stackItem = displayHandler.scanHit(x,y)
    if hit then
      if hit == 8 then
        print("deck hit")
      elseif stackItem > 0 then
        fieldHandler.grabCard(hit, stackItem)
      end
    end
  end
end

function mouseHandler.mouseReleased(x,y,button, status)
  if button == 1 then
    local hit = displayHandler.scanHit(x,y)
    --don't check if it's a hit, we'll let the fieldHandler know and return the card
    fieldHandler.dropCard(hit)
  end
end

return mouseHandler