GameState = {}

GameState.TYPES = {
    OVERWORLD = 1,
    BATTLE = 2,
    MENU = 3,
    DIALOGUE = 4
}

GameState.current = GameState.TYPES.OVERWORLD

function GameState.switch(newState)
    GameState.current = newState
    -- Optional: trigger enter/exit callbacks here if needed
end
