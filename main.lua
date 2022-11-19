local fieldHandler = require('lib.fieldHandler')
local displayHandler = require('lib.displayHandler')
local keyboardHandler = require('lib.keyboardHandler')
local mouseHandler    = require('lib.mouseHandler')

local status = {
  inPlay = false
}

function love.load()
  --game setup
  print("initializing Handlers")
  --initialize Handlers
  fieldHandler.init()
  displayHandler.init()
end

function love.resize(X,Y) --activated everytime the window is resized, it then redoes all the math for love.draw so it's always displayed correctly
  displayHandler.resize(X,Y)
end

function love.focus(f)
  status.inPlay = f
end

function love.update(t)
  fieldHandler.update(t)
end

function love.draw()
  displayHandler.drawField()
  displayHandler.drawTopRow()
  displayHandler.drawHolding()
end

function love.keypressed(key, _scancode, _isrepeat)
  keyboardHandler.keyPressed(key)
end

function love.keyreleased(key)

  keyboardHandler.keyReleased(key)

  if key == "escape" then
     love.event.quit()
  end
end

function love.mousepressed(x, y, button, istouch)
  mouseHandler.mousePressed(x,y,button)
end

function love.mousereleased(x, y, button, istouch, presses)
  mouseHandler.mouseReleased(x,y,button)
end

function love.quit()
  print("bye lol.")
end