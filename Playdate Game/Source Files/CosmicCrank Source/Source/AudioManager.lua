
local pd <const> = playdate
local snd <const> = pd.sound

class('AudioManager').extends(Object)

function AudioManager:init()
    -- Explosion Synth
    self.explosionSynth = snd.synth.new(snd.kWaveNoise)
    self.explosionSynth:setADSR(0, 0.1, 0, 0)
    self.explosionSynth:setVolume(0.5)
    
    -- Hit Synth
    self.hitSynth = snd.synth.new(snd.kWaveSawtooth)
    self.hitSynth:setADSR(0, 0.1, 0.1, 0.1)
    
    -- Music (Simple Sequence)
    self.musicSynth = snd.synth.new(snd.kWaveTriangle)
    self.musicSynth:setVolume(0.2)
    
    -- Create a simple track
    local track = snd.track.new()
    track:setInstrument(self.musicSynth)
    
    -- Add notes (C major scale ish)
    for i=0, 15 do
        local note = 60 + (i % 4) * 2 -- C4, E4, G4, ...
        track:addNote(i+1, note, 1)
    end
    
    self.sequence = snd.sequence.new()
    self.sequence:addTrack(track)
    self.sequence:setLoops(0, 0, 0) -- Infinite loop
end

function AudioManager:playExplosion()
    self.explosionSynth:playNote(60) -- Note doesn't matter much for noise
end

function AudioManager:playHit()
    self.hitSynth:playNote(50, 0.2)
end

function AudioManager:startMusic()
    self.sequence:play()
end

function AudioManager:stopMusic()
    self.sequence:stop()
end
