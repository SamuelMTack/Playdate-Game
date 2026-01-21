local snd = playdate.sound

SoundManager = {}

-- Synths
local sfxSynth = snd.synth.new(snd.kWaveSine)
local musicSynth = snd.synth.new(snd.kWaveTriangle)

-- Sequence for BGM
local musicSeq = nil
local isMusicPlaying = false

function SoundManager.init()
    sfxSynth:setVolume(0.5)

    -- Initialize Music Sequence Once
    musicSeq = snd.sequence.new()
    local track = musicSeq:addTrack()
    track:setInstrument(musicSynth)
    
    local notes = {38, 41, 45, 50, 45, 41} -- Arpeggio in D Minor
    
    for i = 1, 32 do
        local note = notes[((i-1) % #notes) + 1]
        track:addNote(1, note, (i-1)*4 + 1, 2)
    end
    
    musicSeq:setLoops(0, 32*4)
    musicSeq:setTempo(10)
end

function SoundManager.playBGM()
    if isMusicPlaying then return end
    if musicSeq then
        musicSeq:play()
        isMusicPlaying = true
    end
end

function SoundManager.stopBGM()
    if musicSeq then
        musicSeq:stop()
        isMusicPlaying = false
    end
end

function SoundManager.playBubble()
    local synth = snd.synth.new(snd.kWaveSine)
    synth:playNote(800, 0.3, 0.1) -- High pitch, short
    synth:setVolume(0.2)
end

function SoundManager.playHit()
    local synth = snd.synth.new(snd.kWaveNoise)
    synth:setADSR(0, 0.1, 0, 0)
    synth:playNote(100, 0.5, 0.3)
end

function SoundManager.playPickup()
    local synth = snd.synth.new(snd.kWaveSquare)
    synth:setADSR(0, 0.1, 0.1, 0.2)
    synth:playNote(600, 0.4, 0.1)
    playdate.timer.performAfterDelay(100, function()
        synth:playNote(800, 0.4, 0.1)
    end)
end

function SoundManager.playGameOver()
     local synth = snd.synth.new(snd.kWaveSawtooth)
     synth:playNote(300, 0.5, 1.0)
     -- Pitch bend down/slide effects are complex, simple note is fine for now
end

SoundManager.init()
