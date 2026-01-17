
local pd <const> = playdate
local sound <const> = pd.sound

class('SoundManager').extends()

function SoundManager:init()
    -- Placeholder for synth or sample loading
    self.synth = sound.synth.new(sound.kWaveSquare)
    self.synth:setVolume(0.2)
    
    -- In a real scenario we'd load files:
    -- self.bgm = sound.fileplayer.new('sounds/theme')
    
    -- Simple SFX using synth for now to ensure it works without external assets
    -- If user adds assets later, they can just replace these calls
end

function SoundManager:playMove()
    self.synth:playNote("C4", 0.05)
end

function SoundManager:playRotate()
    self.synth:playNote("E4", 0.05)
end

function SoundManager:playDrop()
    self.synth:playNote("G3", 0.1)
end

function SoundManager:playClear()
    -- Arpeggio or happy sound
    self.synth:playNote("C5", 0.1)
    -- Just a single note for simplicity in this MVP
end

function SoundManager:playGameOver()
    self.synth:playNote("A2", 0.5)
end

function SoundManager:startBGM()
    -- if self.bgm then self.bgm:play(0) end
end

function SoundManager:stopBGM()
    -- if self.bgm then self.bgm:stop() end
end
