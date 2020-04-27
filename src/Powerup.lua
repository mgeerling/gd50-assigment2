--[[
    GD50
    Breakout Remake

    -- Powerup Class --

    Author: Matt Geerling

    Represents a powerup
]]

Powerup = Class{}

--[[
 TODO
]]
function Powerup:init()
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

end

function Powerup:update(dt)
    --make it fall like particles TODO
    self.y = self.y + self.dy * dt
end

--TODO Needs collision detection

--[[
    Render the paddle by drawing the main texture, passing in the quad
    that corresponds to the proper skin and size.
]]
function Powerup:render()
    if self.inPlay then 
        love.graphics.draw(gTextures['main'], gFrames['powerups'][1],
            self.x, self.y)
    end 
end