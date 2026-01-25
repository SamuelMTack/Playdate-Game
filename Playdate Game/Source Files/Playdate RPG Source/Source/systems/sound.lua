local snd = playdate.sound

Sound = {}

local sequence = nil

function Sound.init()
    -- No global synth needed if we create them per track
end

function Sound.playOverworldMusic()
    if sequence then 
        sequence:stop() 
        sequence = nil
    end
    
    sequence = snd.sequence.new()
    local track = sequence:addTrack()
    
    local synth = snd.synth.new(snd.kWaveSawtooth)
    synth:setVolume(0.2)
    synth:setADSR(0.1, 0.2, 0.5, 0.3)
    
    track:setInstrument(synth)
    
    -- Simple Arpeggio: C E G B (Major 7th)
    -- Steps refer to 16th notes typically if tempo is set
    track:addNote(1, "C3", 2)
    track:addNote(3, "E3", 2)
    track:addNote(5, "G3", 2)
    track:addNote(7, "B3", 2)
    track:addNote(9, "C4", 2)
    track:addNote(11, "G3", 2)
    track:addNote(13, "E3", 2)
    track:addNote(15, "C3", 2)
    
    sequence:setTempo(10) -- Slow atmospheric
    sequence:setLoops(0, 0) -- Infinite Loop
    sequence:play()
    print("Playing Overworld Music")
end

function Sound.playBattleMusic()
    if sequence then 
        sequence:stop() 
        sequence = nil
    end
    
    sequence = snd.sequence.new()
    local track = sequence:addTrack()
    
    local synth = snd.synth.new(snd.kWaveSawtooth)
    synth:setVolume(0.2)
    synth:setADSR(0.05, 0.1, 0.5, 0.2) -- Sharper envelope for battle
    
    track:setInstrument(synth)
    
    -- Faster, more tense: A Minor
    track:addNote(1, "A2", 1)
    track:addNote(2, "A2", 1)
    track:addNote(3, "C3", 1)
    track:addNote(4, "A2", 1)
    track:addNote(5, "E3", 1)
    track:addNote(7, "D3", 1)
    track:addNote(9, "A2", 1)
    track:addNote(11, "G2", 1)
    
    sequence:setTempo(20) -- Faster
    sequence:setLoops(0, 0)
    sequence:play()
    print("Playing Battle Music")
end

function Sound.playFanfare()
    local s = snd.synth.new(snd.kWaveSine)
    s:playNote("C4", 1, 0.2)
    playdate.timer.performAfterDelay(100, function() s:playNote("E4", 1, 0.2) end)
    playdate.timer.performAfterDelay(200, function() s:playNote("G4", 1, 0.2) end)
    playdate.timer.performAfterDelay(400, function() s:playNote("C5", 1, 0.4) end)
end

return Sound
