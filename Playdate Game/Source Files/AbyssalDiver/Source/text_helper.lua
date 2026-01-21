local gfx = playdate.graphics

-- Constants
kTextAlignment = {
    left = 0,
    right = 1,
    center = 2
}

function gfx.drawTextAligned(str, x, y, textAlignment)
    local font = gfx.getFont()
    if font == nil then 
        return -- Avoid error if no font
    end
    
    local lineHeight = font:getHeight() + 2 -- Basic leading approximation
    local ox = x
    str = ""..str
    
    for line in str:gmatch("[^\r\n]*") do       
        local width = gfx.getTextSize(line)
        
        local alignedX = x
        if textAlignment == kTextAlignment.right then
            alignedX = ox - width
        elseif textAlignment == kTextAlignment.center then
            alignedX = ox - (width / 2)
        end
        
        gfx.drawText(line, alignedX, y)
        y += lineHeight
    end
end
