--[[
    GD50
    Breakout Remake

    -- Powerup Class --

    Author: Matt Geerling

    Represents a powerup
]]

Powerup = Class{}

function Powerup:init(skin)
    --not in play by default
    self.inPlay = false 
    -- x is placed in the middle
    self.x = 50

    -- y is placed a little above the bottom edge of the screen
    self.y = 50

    -- start us off with no velocity
    self.dy = 0

    -- starting dimensions
    self.width = 16
    self.height = 16
    self.isActive = false
    self.skin = skin

end

function Powerup:update(dt)
    self.y = self.y + self.dy * dt
end

--COLLISION CODE 
--[[ REUSED FROM BALL 
    Expects an argument with a bounding box, be that a paddle or a brick,
    and returns true if the bounding boxes of this and the argument overlap.
]]
function Powerup:collides(target)
    -- first, check to see if the left edge of either is farther to the right
    -- than the right edge of the other
    if self.x > target.x + target.width or target.x > self.x + self.width then
        return false
    end

    -- then check to see if the bottom edge of either is higher than the top
    -- edge of the other
    if self.y > target.y + target.height or target.y > self.y + self.height then
        return false
    end 

    -- if the above aren't true, they're overlapping
    return true
end

--[[
    Render the paddle by drawing the main texture, passing in the quad
    that corresponds to the proper skin and size.
]]
function Powerup:render()
    if self.inPlay then 
        love.graphics.draw(gTextures['main'], gFrames['powerups'][self.skin],
            self.x, self.y)
    end 
end