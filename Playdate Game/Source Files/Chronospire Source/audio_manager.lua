local snd = playdate.sound

AudioManager = {}
AudioManager.SFX = {
    JUMP = 1,
    IMPACT = 2,
    CRANK = 3
}

-- Synths
local sfxSynth = snd.synth.new(snd.kWaveSawtooth)

-- Music Sequence
local musicSynth = snd.synth.new(snd.kWaveTriangle)
local musicSeq = snd.sequence.new()

function AudioManager.init()
    -- Setup Music
    -- Simple Arpeggio
    local track = musicSeq:addTrack()
    track:setInstrument(musicSynth)
    track:addNote(1, "C4", 1)
    track:addNote(2, "E4", 1)
    track:addNote(3, "G4", 1)
    track:addNote(4, "C5", 1)
    musicSeq:setLoops(0, 4, 0) -- Loop forever
    musicSeq:setTempo(10)
end

function AudioManager.playMusic()
    if musicSeq then
        musicSeq:play()
    else
        AudioManager.init()
        musicSeq:play()
    end
end

function AudioManager.stopMusic()
    if musicSeq then musicSeq:stop() end
end

function AudioManager.update()
    -- logic for dynamic music could go here
end

function AudioManager.playSFX(type)
    if type == AudioManager.SFX.JUMP then
        sfxSynth:playNote("C5", 0.1, 0.2)
        sfxSynth:setWaveform(snd.kWaveNoise) -- burst
    elseif type == AudioManager.SFX.IMPACT then
        sfxSynth:setWaveform(snd.kWaveTriangle)
        sfxSynth:playNote("C2", 0.2, 0.3)
    elseif type == AudioManager.SFX.CRANK then
        -- Subtle click
        sfxSynth:setWaveform(snd.kWaveNoise)
        sfxSynth:playNote("C8", 0.01, 0.05)
    end
end
