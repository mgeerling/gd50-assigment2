--[[
    GD50
    Breakout Remake

    -- PlayState Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Represents the state of the game in which we are actively playing;
    player should control the paddle, with the ball actively bouncing between
    the bricks, walls, and the paddle. If the ball goes below the paddle, then
    the player should lose one point of health and be taken either to the Game
    Over screen if at 0 health or the Serve screen otherwise.
]]

PlayState = Class{__includes = BaseState}

--[[
    We initialize what's in our PlayState via a state table that we pass between
    states as we go from playing to serving.
]]
function PlayState:enter(params)
    self.paddle = params.paddle
    self.bricks = params.bricks
    self.health = params.health
    self.score = params.score
    self.highScores = params.highScores
    self.ball = params.ball
    self.level = params.level
    self.locked = params.locked

    self.recoverPoints = 5000

    -- give ball random starting velocity
    self.ball.dx = math.random(-200, 200)
    self.ball.dy = math.random(-50, -60)

    self.paddleSizeScore = 0

    --add powerups 
    --self.powerups{}
    self.powerup = Powerup(1)
    -- if self.locked == true then 
    --     table.insert(self.powerups,Powerup(10))
    -- end

    --create a timer for spawning powerups; TODO tweak boundaries later  
    self.powerupTimer = math.random(0,3)

    --create an array for all balls
    self.balls = {}
    table.insert(self.balls,self.ball)

    --check if we still have balls alive
    self.stillBalls = true

end


function PlayState:update(dt)

    --PAUSE FUNCTION
    if self.paused then
        if love.keyboard.wasPressed('space') then
            self.paused = false
            gSounds['pause']:play()
        else
            return
        end
    elseif love.keyboard.wasPressed('space') then
        self.paused = true
        gSounds['pause']:play()
        return
    end

    -- update positions based on velocity
    self.paddle:update(dt)
    self.ball:update(dt)
    self.powerup:update(dt)
    if self.powerup.isActive then 
        self.balls[2]:update(dt)
        self.balls[3]:update(dt)
    end 
    
    for j, ball in pairs(self.balls) do 
        if ball:collides(self.paddle) then
            -- raise ball above paddle in case it goes below it, then reverse dy
            ball.y = self.paddle.y - 8
            ball.dy = -ball.dy

            --
            -- tweak angle of bounce based on where it hits the paddle
            --

            -- if we hit the paddle on its left side while moving left...
            if ball.x < self.paddle.x + (self.paddle.width / 2) and self.paddle.dx < 0 then
                ball.dx = -50 + -(8 * (self.paddle.x + self.paddle.width / 2 - ball.x))
            
            -- else if we hit the paddle on its right side while moving right...
            elseif ball.x > self.paddle.x + (self.paddle.width / 2) and self.paddle.dx > 0 then
                ball.dx = 50 + (8 * math.abs(self.paddle.x + self.paddle.width / 2 - ball.x))
            end

            gSounds['paddle-hit']:play()
        end
    end

    if self.powerup.inPlay and self.powerup:collides(self.paddle) then 
        --TODO make a powerup noise 
        self.powerup.inPlay = false 
        self.powerup.isActive = true
        --TODO spawn a new ball and keep track 
        for i=2,3,1 do
            table.insert(self.balls,Ball(math.random(7)))
            self.balls[i].x = self.paddle.x + (self.paddle.width / 2) - 4
            self.balls[i].y = self.paddle.y - 8
            -- give ball random starting velocity
            self.balls[i].dx = math.random(-200, 200)
            self.balls[i].dy = math.random(-50, -60)
        end
        
    end 

    -- detect collision across all bricks with the ball
    for k, brick in pairs(self.bricks) do
        for j, ball in pairs(self.balls) do 

            -- only check collision if we're in play
            if brick.inPlay and ball:collides(brick) then

                -- add to score
                self.score = self.score + (brick.tier * 200 + brick.color * 25)
                self.paddleSizeScore = self.paddleSizeScore + (brick.tier * 200 + brick.color * 25)
                if self.paddleSizeScore > PADDLE_SCORE_REQ and self.paddle.size < 4 then 
                    self.paddle.size = self.paddle.size + 1 
                    self.paddleSizeScore = 0 
                end
                -- trigger the brick's hit function, which removes it from play
                brick:hit()
                --increment our powerup timer if there is not one in play
                --TODO: would be nice to encapsulate 
                if self.powerup.inPlay == false and self.powerup.isActive == false then 
                    self.powerupTimer = self.powerupTimer + 1
                    if self.powerupTimer > 4 then 
                        self.powerup.inPlay = true
                        self.powerup.dy = 20
                        self.powerup.x = ball.x
                        self.powerup.y = ball.y
                    end 
                end 

                -- if we have enough points, recover a point of health
                if self.score > self.recoverPoints then
                    -- can't go above 3 health
                    self.health = math.min(3, self.health + 1)

                    -- multiply recover points by 2
                    self.recoverPoints = math.min(100000, self.recoverPoints * 2)

                    -- play recover sound effect
                    gSounds['recover']:play()
                end

                -- go to our victory screen if there are no more bricks left
                if self:checkVictory() then
                    gSounds['victory']:play()

                    gStateMachine:change('victory', {
                        level = self.level,
                        paddle = self.paddle,
                        health = self.health,
                        score = self.score,
                        highScores = self.highScores,
                        ball = self.ball,
                        recoverPoints = self.recoverPoints
                    })
                end

                --
                -- collision code for bricks
                --
                -- we check to see if the opposite side of our velocity is outside of the brick;
                -- if it is, we trigger a collision on that side. else we're within the X + width of
                -- the brick and should check to see if the top or bottom edge is outside of the brick,
                -- colliding on the top or bottom accordingly 
                --

                -- left edge; only check if we're moving right, and offset the check by a couple of pixels
                -- so that flush corner hits register as Y flips, not X flips
                if ball.x + 2 < brick.x and ball.dx > 0 then
                    
                    -- flip x velocity and reset position outside of brick
                    ball.dx = -ball.dx
                    ball.x = brick.x - 8
                
                -- right edge; only check if we're moving left, , and offset the check by a couple of pixels
                -- so that flush corner hits register as Y flips, not X flips
                elseif ball.x + 6 > brick.x + brick.width and ball.dx < 0 then
                    
                    -- flip x velocity and reset position outside of brick
                    ball.dx = -ball.dx
                    ball.x = brick.x + 32
                
                -- top edge if no X collisions, always check
                elseif ball.y < brick.y then
                    
                    -- flip y velocity and reset position outside of brick
                    ball.dy = -ball.dy
                    ball.y = brick.y - 8
                
                -- bottom edge if no X collisions or top collision, last possibility
                else
                    
                    -- flip y velocity and reset position outside of brick
                    ball.dy = -ball.dy
                    ball.y = brick.y + 16
                end

                -- slightly scale the y velocity to speed up the game, capping at +- 150
                if math.abs(ball.dy) < 150 then
                    ball.dy = ball.dy * 1.02
                end

                -- only allow colliding with one brick, for corners
                break
            end
        end
    end

    --STYLE: these next two sections could be done more elegantly with some kind of array soln 
    -- for j, ball in pairs(self.balls) do 
    --     ball.y < VIRTUAL_HEIGHT then 
    --         self.stillBalls = true 
    --     else 
    --         self.stillBalls = false
    -- end 
    
    -- if ball goes below bounds, revert to serve state and decrease health
    if self.ball.y >= VIRTUAL_HEIGHT and self.powerup.isActive == false then
        self.health = self.health - 1
        if self.paddle.size > 1 then 
            self.paddle.size = self.paddle.size - 1
        end
        self.paddleSizeScore = 0 
        gSounds['hurt']:play()

        if self.health == 0 then
            gStateMachine:change('game-over', {
                score = self.score,
                highScores = self.highScores
            })
        else
            gStateMachine:change('serve', {
                paddle = self.paddle,
                bricks = self.bricks,
                health = self.health,
                score = self.score,
                highScores = self.highScores,
                level = self.level,
                recoverPoints = self.recoverPoints
            })
        end
    end

    if self.powerup.isActive and self.ball.y >= VIRTUAL_HEIGHT and self.balls[2].y >= VIRTUAL_HEIGHT and self.balls[3].y >= VIRTUAL_HEIGHT then
        self.powerup.isActive = false 
        self.health = self.health - 1
        if self.paddle.size > 1 then 
            self.paddle.size = self.paddle.size - 1
        end
        self.paddleSizeScore = 0 
        gSounds['hurt']:play()

        if self.health == 0 then
            gStateMachine:change('game-over', {
                score = self.score,
                highScores = self.highScores
            })
        else
            gStateMachine:change('serve', {
                paddle = self.paddle,
                bricks = self.bricks,
                health = self.health,
                score = self.score,
                highScores = self.highScores,
                level = self.level,
                recoverPoints = self.recoverPoints
            })
        end
    end

    -- for rendering particle systems
    for k, brick in pairs(self.bricks) do
        brick:update(dt)
    end

    if love.keyboard.wasPressed('escape') then
        love.event.quit()
    end
end

function PlayState:render()
    -- render bricks
    for k, brick in pairs(self.bricks) do
        brick:render()
    end

    -- render all particle systems
    for k, brick in pairs(self.bricks) do
        brick:renderParticles()
    end

    self.paddle:render()
    self.ball:render()
    self.powerup:render()
    if self.powerup.isActive then 
        self.balls[2]:render()
        self.balls[3]:render()
    end
 

    renderScore(self.score)
    renderHealth(self.health)

    -- pause text, if paused
    if self.paused then
        love.graphics.setFont(gFonts['large'])
        love.graphics.printf("PAUSED", 0, VIRTUAL_HEIGHT / 2 - 16, VIRTUAL_WIDTH, 'center')
    end
end

function PlayState:checkVictory()
    for k, brick in pairs(self.bricks) do
        if brick.inPlay then
            return false
        end 
    end

    return true
end