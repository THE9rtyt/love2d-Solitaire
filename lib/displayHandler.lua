local fieldHandler = require "lib.fieldHandler"

local displayHandler = {}
-------------------------------------------------------------------------------------
-- Handles drawing screen features and private vars, each section in its own function
-------------------------------------------------------------------------------------

--------------
--Private Vars
--------------
local windowX,windowY, centerX,centerY
local cardScale --scale to draw a card at
local margins --a rough offset of pixels for spacing cards between eachother
local stackRows = {} --an array for holding the stack row pixel location
local stackY, stackShift --stack Y variables positioning

local mouseOffset = {
  x = 0,
  y = 0
}

--goto displayHandler.init() for more these var's setup

local cardX = 500
local cardY = 726


-------------
--load assets
-------------

--number images

local numbers_assets = {
  "/assets/text/text0.png",
  "/assets/text/text1.png",
  "/assets/text/text2.png",
  "/assets/text/text3.png",
  "/assets/text/text4.png",
  "/assets/text/text5.png",
  "/assets/text/text6.png",
  "/assets/text/text7.png",
  "/assets/text/text8.png",
  "/assets/text/text9.png"
}

--card images

local hearts = {
  "/assets/cards/ace_of_hearts.png",
  "/assets/cards/2_of_hearts.png",
  "/assets/cards/3_of_hearts.png",
  "/assets/cards/4_of_hearts.png",
  "/assets/cards/5_of_hearts.png",
  "/assets/cards/6_of_hearts.png",
  "/assets/cards/7_of_hearts.png",
  "/assets/cards/8_of_hearts.png",
  "/assets/cards/9_of_hearts.png",
  "/assets/cards/10_of_hearts.png",
  "/assets/cards/jack_of_hearts.png",
  "/assets/cards/queen_of_hearts.png",
  "/assets/cards/king_of_hearts.png",
}

local clubs = {
  "/assets/cards/ace_of_clubs.png",
  "/assets/cards/2_of_clubs.png",
  "/assets/cards/3_of_clubs.png",
  "/assets/cards/4_of_clubs.png",
  "/assets/cards/5_of_clubs.png",
  "/assets/cards/6_of_clubs.png",
  "/assets/cards/7_of_clubs.png",
  "/assets/cards/8_of_clubs.png",
  "/assets/cards/9_of_clubs.png",
  "/assets/cards/10_of_clubs.png",
  "/assets/cards/jack_of_clubs.png",
  "/assets/cards/queen_of_clubs.png",
  "/assets/cards/king_of_clubs.png",
}

local diamonds = {
  "/assets/cards/ace_of_diamonds.png",
  "/assets/cards/2_of_diamonds.png",
  "/assets/cards/3_of_diamonds.png",
  "/assets/cards/4_of_diamonds.png",
  "/assets/cards/5_of_diamonds.png",
  "/assets/cards/6_of_diamonds.png",
  "/assets/cards/7_of_diamonds.png",
  "/assets/cards/8_of_diamonds.png",
  "/assets/cards/9_of_diamonds.png",
  "/assets/cards/10_of_diamonds.png",
  "/assets/cards/jack_of_diamonds.png",
  "/assets/cards/queen_of_diamonds.png",
  "/assets/cards/king_of_diamonds.png",
}

local spades = {
  "/assets/cards/ace_of_spades.png",
  "/assets/cards/2_of_spades.png",
  "/assets/cards/3_of_spades.png",
  "/assets/cards/4_of_spades.png",
  "/assets/cards/5_of_spades.png",
  "/assets/cards/6_of_spades.png",
  "/assets/cards/7_of_spades.png",
  "/assets/cards/8_of_spades.png",
  "/assets/cards/9_of_spades.png",
  "/assets/cards/10_of_spades.png",
  "/assets/cards/jack_of_spades.png",
  "/assets/cards/queen_of_spades.png",
  "/assets/cards/king_of_spades.png",
}

local cardBack = "/assets/blank.png"

local cardTextures = {}
local back = {}

local numbers

--------------------
--module I/O methods
--------------------
function displayHandler.init()--load field settings into display handler for field size
  numbers = love.graphics.newArrayImage(numbers_assets)

  cardTextures = {
    love.graphics.newArrayImage(hearts),
    love.graphics.newArrayImage(clubs),
    love.graphics.newArrayImage(diamonds),
    love.graphics.newArrayImage(spades),
  }

  back = love.graphics.newImage(cardBack)
end

-------------------
--private function
-------------------

local function filterStackSize(stackSize)
  if stackSize > 3 then
    return 3
  else
    return stackSize
  end
end

--------------------------------------
-- public methods for drawing features
--------------------------------------
function displayHandler.resize(X,Y)
  margins = math.floor(Y*0.01)
  print("margins: "..margins)

  windowY = Y-margins
  windowX = windowY*1.2

  centerX = X/2
  centerY = Y/2

  local shift = centerX-math.floor(windowX/2)
  for i = 1,8,1 do
    stackRows[i] = math.floor( windowX / 7 ) * (i-1) + margins + shift
  end

  cardScale = (stackRows[2]-stackRows[1]-margins*2)/cardX

  stackY = cardY * cardScale + margins * 3
  stackShift = cardY * cardScale * 0.2
end

function displayHandler.scanHit(x,y)
  print("scanning hit x: "..x.." y: "..y)
  if y < stackY then --above the stacks
    print("above the stacks")
    if y < margins or y > stackY-margins  or
      x < stackRows[1]+margins or x > stackRows[8] then
      return nil --no hit, outside of toprow top/bottom and sides
    else
      print("check deck")

      if x > stackRows[1]+margins and x < stackRows[2]-margins then
        --deck hit
        return 8, 1
      end

      print("check playStack")

      local stackSize = fieldHandler.getPlayStackSize()
      local filteredSize = filterStackSize(stackSize)

      if filteredSize > 0 then
        local leftEdgeOfCard = stackRows[2]+margins+stackShift*(filteredSize-1)
        local rightEdgeOfCard = leftEdgeOfCard+cardX*cardScale

        if x < rightEdgeOfCard and x > leftEdgeOfCard then
          print("stack hit")

          mouseOffset = {
            x = x-leftEdgeOfCard,
            y = y-margins
          }
          return 9, 1
        end
      end
      
      print("check aces")
      for index, row in ipairs({ unpack(stackRows, 4) }) do
        if x > row+margins and x < stackRows[index+4]-margins then
          --aceStack hit
          mouseOffset = {
            x = x-row-margins,
            y = y-margins
          }

          return index+9, 1
        end
      end
    end
  else --below the deck and Aces
    for index, row in ipairs(stackRows) do --loop through stackRows, left to right to find rowhit
      if index == 8 then return nil end --return if index 8, did not click on a row's card
      if x < stackRows[index+1]-margins and x > row+margins then --if within the rows card width
        local stackSize = fieldHandler.getStackSize(index)
        for i = 1, stackSize-1, 1 do
          if y < stackY+stackShift*i then
            --save the mouse offset if cards are picked up
            mouseOffset = {
              x = x-row-margins,
              y = y-stackY-stackShift*(i-1)
            }
            return index, i
          end
        end

        local topOfCard = stackY+stackShift*(stackSize-1)
        local bottomOfCard = topOfCard+cardY*cardScale

        if y < bottomOfCard then
          --save the mouse offset if card is picked up
          mouseOffset = {
            x = x-row-margins,
            y = y-topOfCard
          }
          return index, stackSize
        end
      end
    end
  end
end

function displayHandler.drawField()
  local field = fieldHandler.getField()

  for Loc,stack in pairs(field) do
    for index,card in pairs(stack) do
      if card then
        if not card.flipped then
          love.graphics.draw(back,stackRows[Loc]+margins,stackY+stackShift*(index-1),0,cardScale,cardScale)
        else
          local cardImage = cardTextures[card.type]

          love.graphics.drawLayer(cardImage, card.number,stackRows[Loc]+margins,stackY+stackShift*(index-1),0,cardScale,cardScale)
        end
      end
    end
  end
end

function displayHandler.drawTopRow()
  local topRow = fieldHandler.getTopRow()

  --draw the deck card
  if #topRow.deck > 0 then
    love.graphics.draw(back,stackRows[1]+margins,margins,0,cardScale,cardScale)
  end

  for index, card in ipairs(topRow.playStack) do
    local cardImage = cardTextures[card.type]

    love.graphics.drawLayer(cardImage, card.number,stackRows[2]+stackShift*(index-1)+margins,margins,0,cardScale,cardScale)
  end

  for index, cards in ipairs(topRow.aces) do
    local topCard = cards[#cards]

    if topCard then
      local cardImage = cardTextures[topCard.type]

      love.graphics.drawLayer(cardImage, topCard.number,stackRows[index+3]+margins,margins,0,cardScale,cardScale)
    end
  end
end

function displayHandler.drawHolding()
  local holding = fieldHandler.getHolding()
  if #holding ~= 0 then
    for index,card in ipairs(holding) do
      local cardImage = cardTextures[card.type]
      local x,y = love.mouse.getPosition()

      love.graphics.drawLayer(cardImage, card.number,x-mouseOffset.x,y-mouseOffset.y+(index-1)*stackShift,0,cardScale,cardScale)
    end
  end
end


return displayHandler