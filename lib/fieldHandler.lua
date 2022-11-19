local fieldHandler = {}

---------------------------------------------------------
-- Handles all private field vars and manages interaction
---------------------------------------------------------
local field = { --index 1..7
  {}, --stack 1
  {}, --stack 2
  {}, --stack 3
  {}, --stack 4
  {}, --stack 5
  {}, --stack 6
  {} --stack 7
}

local topRow = { --index 8..13
  deck = {},
  playStack = {},
  aces = {
    {},
    {},
    {},
    {}
  }
}

local holding = {
  card = {},
  fromIndex = nil
}

--[[
  card structure

  every card stored in an index will consist of a table 
    with the follwing keys and value types
  {int type, int number, bool flipped}

  types = 
  1 = hearts
  2 = clubs
  3 = diamonds
  4 = spades

  numbers = 
  1 = ace
  2..10 = 2..10
  11 = jack
  12 = queen
  13 = king

  flipped
  true = face up
  false = face down

]]

-------------------
--private functions
-------------------

local function makeCardList()
  local masterList = {}

  for type = 1,4,1 do
    for card = 1, 13, 1 do
      table.insert(masterList, {type = type, number = card, flipped = true})
    end
  end

  return masterList
end

local function shuffleCards(deck)
  local result = {}

  while #deck ~= 0 do
    local randNum = love.math.random(1,#deck)

    local card = table.remove(deck, randNum)
    table.insert(result, card)
  end

  return result
end

local function clearcards()
  --clear field stacks
  field = {
    {},
    {},
    {},
    {},
    {},
    {},
    {}
  }

  --clear top row
  topRow = {
  deck = {},
  playStack = {},
  aces = {
    {},
    {},
    {},
    {}
  }
}
end

local function layoutField(deck)
  for index, stack in ipairs(field) do
    for i = 1,index-1,1 do
      local card = table.remove(deck)
      card.flipped = false
      table.insert(stack,card)
    end
    local card = table.remove(deck)
    table.insert(stack,card)
  end
end

local function newGame()
  clearcards()

  local masterList = makeCardList()

  topRow.deck = shuffleCards(masterList)

  layoutField(topRow.deck)
end

local function revealDeck()
  print("revealing deck")
  if #topRow.deck > 0 then --cards in deck
    for _i = 1,3,1 do --reveal next 3 cards
      local card = table.remove(topRow.deck)

      if card then
        table.insert(topRow.playStack, card)
      else
        break
      end
    end
  else --deck empty, return playStack to deck
    for _i = 1,#topRow.playStack do
      local card = table.remove(topRow.playStack)

      table.insert(topRow.deck, card)
    end
  end
end

--check the ends of stacks for cards that need to be flipped
local function checkStacks()
  for index, stack in ipairs(field) do
    if #stack > 0 and not stack[#stack].flipped then
      stack[#stack].flipped = true
    end
  end
end

--non-checking card placement function for returning the holding cards
local function returnCards(stack,cards)
  if stack <= 7 then
    for _index, value in ipairs(cards) do
      table.insert(field[stack],value)
    end
  elseif stack == 9 then
    --magic number 1 here to grab the only index, 
    -- or else it adds the table of cards to the table we're placing it at
    table.insert(topRow.playStack,cards[1])
  elseif stack <= 13 then
    --same magic number 1 as above
    table.insert(topRow.aces[stack-9],cards[1])
  end

  return {}
end
  
local function placeToStacks(stack,cards)
  if #field[stack] == 0 or
  (holding.card[1].number+1 == field[stack][#field[stack]].number) and
  (holding.card[1].type%2 ~= field[stack][#field[stack]].type%2)
  then
    for _index, value in ipairs(cards) do
      table.insert(field[stack],value)
    end
  else
    print("return card on failed stack combo")
    returnCards(holding.fromIndex,holding.card)
  end

  return {}
end

local function placeToAces(stack,cards)
  if #topRow.aces[stack-9] == 0  then -- empty stack
    if holding.card[1].number == 1 then
    --ace stack is empty and holding an ace
    table.insert(topRow.aces[stack-9],cards[1])
    else
      print("return card on failed ace combo")
      returnCards(holding.fromIndex,holding.card)
    end
  elseif (holding.card[1].number-1 == topRow.aces[stack-9][#topRow.aces[stack-9]].number) and
  (holding.card[1].type == topRow.aces[stack-9][#topRow.aces[stack-9]].type) then
    --stack is not empty and card is 1 above current card on top of stack
    table.insert(topRow.aces[stack-9],cards[1])
  else
    print("return card on failed ace combo")
    returnCards(holding.fromIndex,holding.card)
  end

  return {}
end

-- from: http://lua-users.org/wiki/CopyTable :pray:
-- Save copied tables in `copies`, indexed by original table.
local function deepcopy(orig, copies)
  copies = copies or {}
  local orig_type = type(orig)
  local copy
  if orig_type == 'table' then
      if copies[orig] then
          copy = copies[orig]
      else
          copy = {}
          copies[orig] = copy
          for orig_key, orig_value in next, orig, nil do
              copy[deepcopy(orig_key, copies)] = deepcopy(orig_value, copies)
          end
          setmetatable(copy, deepcopy(getmetatable(orig), copies))
      end
  else -- number, string, boolean, etc
      copy = orig
  end
  return copy
end

--------------------
--module I/O methods
--------------------
function fieldHandler.init()
  newGame()
end

function fieldHandler.getField()
  return field
end

function fieldHandler.getTopRow()
  --make local copy of topRow
  local temp = deepcopy(topRow)
  local length = #temp.playStack
  
  if length >= 3 then
    temp.playStack = { unpack(temp.playStack, length-2) }
    if holding.card[1] and holding.fromIndex == 9 then --if holding a card from the stack
      table.remove(temp.playStack, 1)
    end
  end

  return temp
end

function fieldHandler.getHolding()
  return holding.card
end

function fieldHandler.getPlayStackSize()
  return #topRow.playStack
end

function fieldHandler.getStackSize(stack)
  return #field[stack]
end

----------------------------------
-- public methods for field Events
----------------------------------

function fieldHandler.grabCard(index, stackItem)
  if holding.card[1] then return end --in the event a card is picked up while holding

  if index <= 7 then --stacks
    if field[index][stackItem].flipped then
      print("grabbing cards")
      for _index = stackItem,#field[index],1 do
        table.insert(holding.card, table.remove(field[index], stackItem))
      end
    end

  elseif index == 8 then --deck
    print("here")
    revealDeck()
  elseif index == 9 then --play stack
    table.insert(holding.card, table.remove(topRow.playStack))

  elseif index <= 13 then --aces
    if #topRow.aces[index-9] > 0 then
      table.insert(holding.card, table.remove(topRow.aces[index-9]))
    end

  end
  holding.fromIndex = index
end

function fieldHandler.dropCard(index)
  if #holding.card ~= 0 then
    if index then
      if index <= 7 then
        holding.card = placeToStacks(index,holding.card)
      elseif #holding.card > 1 then
        print("returning cards on no found stacks")
        --make sure to return cards cause we can only dump multiple on the stacks
        holding.card = returnCards(holding.fromIndex,holding.card)
      elseif index >= 10 and index <= 13 then
        holding.card = placeToAces(index,holding.card)
      end
    else
      print("returning card on no found spots")
      holding.card = returnCards(holding.fromIndex,holding.card)
    end

    checkStacks()
  end
end

function fieldHandler.update(updateTime)

end

return fieldHandler