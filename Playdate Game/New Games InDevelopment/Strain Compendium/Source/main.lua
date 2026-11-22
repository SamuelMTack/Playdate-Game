import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "CoreLibs/crank"
import "CoreLibs/ui"

local gfx <const> = playdate.graphics
local snd <const> = playdate.sound

local SCREEN_W <const> = 400
local SCREEN_H <const> = 240

-- Tactile UI click synthesizer
local sfxClick = snd.synth.new(snd.kWaveTriangle)
sfxClick:setVolume(0.16)
sfxClick:setADSR(0.002, 0.03, 0.0, 0.02)

-- Compendium Dataset: 22 Iconic Strains + Terpene Reference
local STRAINS <const> = {
    {
        name = "Blue Dream",
        type = "Hybrid",
        ratio = "60% Sativa / 40% Indica",
        sativaPct = 60,
        lineage = "Blueberry x Haze",
        thc = "18% - 24%",
        thcScore = 75,
        cbd = "0.1% - 0.5%",
        terpenes = "Myrcene, Pinene, Caryophyllene",
        flavors = "Sweet Berry, Herbal, Pine",
        effects = "Creative, Uplifted, Calm, Balanced",
        origin = "Santa Cruz, California (2000s)",
        description = "Blue Dream is a legendary California cross of Blueberry Indica and Haze Sativa. Celebrated for its sweet berry aroma and gentle cerebral invigoration paired with full-body calm, it became one of the most widely cultivated modern hybrids in North America."
    },
    {
        name = "Jack Herer",
        type = "Sativa",
        ratio = "80% Sativa / 20% Indica",
        sativaPct = 80,
        lineage = "Haze x (Northern Lights #5 x Shiva Skunk)",
        thc = "18% - 23%",
        thcScore = 72,
        cbd = "0.1% - 0.3%",
        terpenes = "Terpinolene, Caryophyllene, Pinene",
        flavors = "Spicy Pine, Woody, Citrus Zest",
        effects = "Clear-Headed, Creative, Energetic",
        origin = "Netherlands (Sensi Seeds, Mid-1990s)",
        description = "Named after the renowned author and activist, Jack Herer was bred in the Netherlands to combine tropical Haze elevation with the dense resin production of classic Afghan and Skunk lines. Known for its crisp pine-needle bouquet and focused clarity."
    },
    {
        name = "Northern Lights",
        type = "Indica",
        ratio = "95% Indica / 5% Sativa",
        sativaPct = 5,
        lineage = "Afghani Landrace x Thai Landrace",
        thc = "16% - 21%",
        thcScore = 66,
        cbd = "0.1% - 0.4%",
        terpenes = "Myrcene, Caryophyllene, Limonene",
        flavors = "Sweet Earth, Pine, Warm Spice",
        effects = "Deeply Relaxed, Serene, Sleepy",
        origin = "Pacific Northwest / Holland (1980s)",
        description = "One of the foundational cornerstones of modern indoor breeding, Northern Lights sprouted near Seattle before being refined in Amsterdam in 1985. Its resin-frosted buds deliver a honey-musk aroma and tranquil evening relaxation."
    },
    {
        name = "Sour Diesel",
        type = "Sativa",
        ratio = "90% Sativa / 10% Indica",
        sativaPct = 90,
        lineage = "Chemdawg 91 x Super Skunk",
        thc = "20% - 25%",
        thcScore = 82,
        cbd = "0.1% - 0.3%",
        terpenes = "Caryophyllene, Limonene, Myrcene",
        flavors = "Pungent Diesel, Tart Lemon, Skunk",
        effects = "Energetic, Dreamy, Talkative",
        origin = "New York / East Coast (Early 1990s)",
        description = "Affectionately called 'Sour D,' this East Coast icon emerged in the early 1990s from an accidental pollination of Chemdawg 91 and Super Skunk. Its unmistakable fuel-and-citrus aroma and fast-acting cerebral spark made it a cultural legend."
    },
    {
        name = "OG Kush",
        type = "Hybrid",
        ratio = "55% Indica / 45% Sativa",
        sativaPct = 45,
        lineage = "Chemdawg x (Lemon Thai x Hindu Kush)",
        thc = "20% - 26%",
        thcScore = 84,
        cbd = "0.1% - 0.3%",
        terpenes = "Myrcene, Limonene, Caryophyllene",
        flavors = "Earthy Pine, Sour Lemon, Woody Fuel",
        effects = "Euphoric, Uplifted, Heavy Relaxation",
        origin = "Florida to Los Angeles (1992-1996)",
        description = "First cultivated in Florida in 1992 and brought to Los Angeles in 1996 where 'OG' came to stand for 'Ocean Grown,' OG Kush forms the genetic backbone of countless West Coast varieties. Distinguished by its lemon-pine-fuel terpene signature."
    },
    {
        name = "Granddaddy Purple",
        type = "Indica",
        ratio = "85% Indica / 15% Sativa",
        sativaPct = 15,
        lineage = "Mendo Purps x Skunk x Afghanistan",
        thc = "17% - 23%",
        thcScore = 70,
        cbd = "0.1% - 0.4%",
        terpenes = "Myrcene, Pinene, Caryophyllene",
        flavors = "Sweet Grape, Wild Berry, Earth",
        effects = "Soothing, Tranquil, Appetite, Restful",
        origin = "Bay Area, California (Ken Estes, 2003)",
        description = "Introduced in 2003 by Ken Estes in the San Francisco Bay Area, Granddaddy Purple (GDP) fuses Mendo Purps with Skunk and Afghani genetics. Famous for its deep royal-violet foliage and unmistakable concord grape and berry bouquet."
    },
    {
        name = "Durban Poison",
        type = "Sativa",
        ratio = "100% Pure Landrace Sativa",
        sativaPct = 100,
        lineage = "South African Landrace (Durban)",
        thc = "17% - 24%",
        thcScore = 74,
        cbd = "0.05% - 0.2%",
        terpenes = "Terpinolene, Myrcene, Ocimene",
        flavors = "Sweet Anise, Licorice, Crisp Pine",
        effects = "Focused, Alert, Uplifted, Productive",
        origin = "Durban, South Africa (1970s Import)",
        description = "Brought from the port city of Durban, South Africa by breeder Ed Rosenthal in the 1970s, Durban Poison is one of the purest unhybridized Sativa landraces remaining. Prized for its sweet anise fragrance and daytime mental crispness."
    },
    {
        name = "Girl Scout Cookies (GSC)",
        type = "Hybrid",
        ratio = "60% Indica / 40% Sativa",
        sativaPct = 40,
        lineage = "OG Kush x Durban Poison",
        thc = "22% - 28%",
        thcScore = 90,
        cbd = "0.1% - 0.2%",
        terpenes = "Caryophyllene, Limonene, Humulene",
        flavors = "Baked Dough, Sweet Mint, Warm Earth",
        effects = "Euphoric, Happy, Full-Body Calm",
        origin = "San Francisco, California (Cookie Fam)",
        description = "Bred by the San Francisco Cookie Fam by crossing South African Durban Poison with Florida OG Kush, GSC launched the entire modern 'dessert strain' era. Known for its sweet bakery aroma, purple-tinted calyxes, and potent balance."
    },
    {
        name = "White Widow",
        type = "Hybrid",
        ratio = "60% Sativa / 40% Indica",
        sativaPct = 60,
        lineage = "Brazilian Sativa Landrace x South Indian Indica",
        thc = "18% - 22%",
        thcScore = 70,
        cbd = "0.1% - 0.3%",
        terpenes = "Myrcene, Caryophyllene, Pinene",
        flavors = "Woody Pepper, Earthy Floral, Citrus",
        effects = "Sociable, Sparked, Balanced Calm",
        origin = "Amsterdam, Netherlands (Shantibaba, 1994)",
        description = "Winner of the 1995 High Times Cannabis Cup, White Widow quickly became a staple of Dutch coffeehouses. Named for its thick blanket of frosty white crystal trichomes, it bridges lively Brazilian Sativa conversation with South Indian calm."
    },
    {
        name = "Pineapple Express",
        type = "Hybrid",
        ratio = "60% Sativa / 40% Indica",
        sativaPct = 60,
        lineage = "Trainwreck x Hawaiian",
        thc = "19% - 25%",
        thcScore = 78,
        cbd = "0.1% - 0.3%",
        terpenes = "Caryophyllene, Limonene, Ocimene",
        flavors = "Fresh Pineapple, Mango, Cedar",
        effects = "Cheerful, Creative, Alert, Breezy",
        origin = "California / Hawaii Genetics (Mid-2000s)",
        description = "Combining the energetic zest of a Hawaiian landrace Sativa with the potent resin of Trainwreck, Pineapple Express boasts bright tropical fruit aromatics underscored by pine and cedar, offering a sunny, productive afternoon lift."
    },
    {
        name = "Hindu Kush",
        type = "Indica",
        ratio = "100% Pure Landrace Indica",
        sativaPct = 0,
        lineage = "Hindu Kush Mountain Landrace",
        thc = "15% - 20%",
        thcScore = 62,
        cbd = "0.2% - 0.6%",
        terpenes = "Limonene, Caryophyllene, Pinene",
        flavors = "Sandalwood, Incense, Sweet Earth",
        effects = "Meditative, Calm, Physical Ease",
        origin = "Pakistan / Afghanistan Border Range",
        description = "Originating in the rugged 500-mile mountain range between Pakistan and Afghanistan, Hindu Kush is a pure indigenous Indica that evolved thick protective coats of trichomes against harsh alpine climates. Exudes a classic sandalwood-incense aroma."
    },
    {
        name = "Super Lemon Haze",
        type = "Sativa",
        ratio = "80% Sativa / 20% Indica",
        sativaPct = 80,
        lineage = "Lemon Skunk x Super Silver Haze",
        thc = "19% - 25%",
        thcScore = 80,
        cbd = "0.1% - 0.2%",
        terpenes = "Terpinolene, Caryophyllene, Myrcene",
        flavors = "Tart Lemon Candy, Zesty Lime, Sweet Haze",
        effects = "Zesty, Lively, Motivated, Optimistic",
        origin = "Amsterdam (Franco Loja / Green House)",
        description = "A back-to-back Cannabis Cup winner bred by the late Franco Loja at Green House Seeds, Super Lemon Haze pairs Lemon Skunk with Super Silver Haze. It bursts with tart lemon-drop aromatics and a sparkling, upbeat energy."
    },
    {
        name = "Gelato (Larry Bird)",
        type = "Hybrid",
        ratio = "55% Indica / 45% Sativa",
        sativaPct = 45,
        lineage = "Sunset Sherbet x Thin Mint GSC",
        thc = "21% - 27%",
        thcScore = 86,
        cbd = "0.1% - 0.2%",
        terpenes = "Caryophyllene, Limonene, Humulene",
        flavors = "Creamy Berry, Sweet Citrus, Lavender",
        effects = "Mellow, Creative, Comforting, Euphoric",
        origin = "San Francisco, CA (Mario Guzman / Sherbinskis)",
        description = "Crafted in San Francisco by Mario Guzman (Sherbinskis), Gelato—especially its prized Phenotype #33 ('Larry Bird')—blends Sunset Sherbet with Thin Mint GSC. Celebrated for its rich creamy fruit profile and velvet-smooth balance."
    },
    {
        name = "Bubba Kush",
        type = "Indica",
        ratio = "85% Indica / 15% Sativa",
        sativaPct = 15,
        lineage = "OG Kush x Pre-98 Northern Lights Pheno",
        thc = "17% - 22%",
        thcScore = 68,
        cbd = "0.1% - 0.3%",
        terpenes = "Caryophyllene, Limonene, Myrcene",
        flavors = "Roasted Coffee, Dark Cocoa, Hashish",
        effects = "Cozy, Tranquil, Heavy-Eyelid Calm",
        origin = "Los Angeles, California (Matt 'Bubba' Berger, 1996)",
        description = "Emerging in Los Angeles in 1996, Bubba Kush is famous for its bulky, dense structure and distinctive roasted coffee and dark chocolate terpene profile. A go-to classic for unwinding at the end of a long day."
    },
    {
        name = "Green Crack (Cush)",
        type = "Sativa",
        ratio = "65% Sativa / 35% Indica",
        sativaPct = 65,
        lineage = "Skunk #1 x Unknown Indica",
        thc = "17% - 24%",
        thcScore = 74,
        cbd = "0.1% - 0.2%",
        terpenes = "Myrcene, Caryophyllene, Pinene",
        flavors = "Tangy Mango, Citrus, Crisp Earth",
        effects = "Laser-Focused, Invigorating, Brisk",
        origin = "Athens, Georgia (Cecil C., 1970s/1989)",
        description = "Originally bred in Athens, Georgia under the name 'Cush,' this Skunk #1 descendant delivers a vibrant mango-and-papaya tang and brisk daytime momentum suitable for tackling creative projects or outdoor adventures."
    },
    {
        name = "Wedding Cake",
        type = "Hybrid",
        ratio = "60% Indica / 40% Sativa",
        sativaPct = 40,
        lineage = "Triangle Kush x Animal Mints",
        thc = "22% - 27%",
        thcScore = 88,
        cbd = "0.1% - 0.2%",
        terpenes = "Limonene, Caryophyllene, Myrcene",
        flavors = "Vanilla Frosting, Tangy Earth, Pepper",
        effects = "Content, Relaxed, Warmly Uplifted",
        origin = "Southern California (Seed Junky Genetics)",
        description = "Known in Canada as 'Pink Cookies,' Wedding Cake was bred by Seed Junky Genetics from Triangle Kush and Animal Mints. It pairs a rich vanilla-cookie sweetness with a peppery Kush backbone."
    },
    {
        name = "Maui Wowie",
        type = "Sativa",
        ratio = "80% Sativa / 20% Indica",
        sativaPct = 80,
        lineage = "Hawaiian Island Landrace Hybrid",
        thc = "16% - 22%",
        thcScore = 66,
        cbd = "0.1% - 0.3%",
        terpenes = "Myrcene, Pinene, Caryophyllene",
        flavors = "Tropical Pineapple, Coconut, Pine",
        effects = "Breezy, Cheerful, Lighthearted",
        origin = "Maui, Hawaii (1960s-1970s Volcanic Soil)",
        description = "Cultivated in the nutrient-rich volcanic soils of Maui during the late 1960s and 1970s, Maui Wowie defined tropical island Sativas with its sweet pineapple aroma and breezy, stress-free disposition."
    },
    {
        name = "Zkittlez (The Original Z)",
        type = "Indica",
        ratio = "70% Indica / 30% Sativa",
        sativaPct = 30,
        lineage = "Grape Ape x Grapefruit",
        thc = "18% - 23%",
        thcScore = 72,
        cbd = "0.1% - 0.3%",
        terpenes = "Caryophyllene, Humulene, Linalool",
        flavors = "Tropical Fruit Salad, Sweet Berry, Citrus",
        effects = "Calm, Focused, Unhurried, Pleasant",
        origin = "Northern California (3rd Gen Family & Terp Hogz)",
        description = "Renowned for winning top honors at the Emerald Cup for its extraordinary terpene richness, Zkittlez crosses Grape Ape with Grapefruit to produce a rainbow of tropical fruit notes with a clear, unhurried calm."
    },
    {
        name = "Strawberry Cough",
        type = "Sativa",
        ratio = "80% Sativa / 20% Indica",
        sativaPct = 80,
        lineage = "Strawberry Fields x Haze",
        thc = "18% - 23%",
        thcScore = 72,
        cbd = "0.1% - 0.3%",
        terpenes = "Myrcene, Pinene, Caryophyllene",
        flavors = "Fresh Strawberries, Sweet Herb, Pepper",
        effects = "Social, Smiling, Clear, Uplifted",
        origin = "Vermont / Connecticut & Kyle Kushman",
        description = "Famous for its uncanny scent of freshly picked strawberries and an expansive smoke that makes even seasoned connoisseurs cough, this Strawberry Fields x Haze cross brings a sociable, smiling daytime brightness."
    },
    {
        name = "Gorilla Glue #4 (GG4)",
        type = "Hybrid",
        ratio = "50% Indica / 50% Sativa",
        sativaPct = 50,
        lineage = "Chem's Sister x Sour Dubb x Chocolate Diesel",
        thc = "23% - 29%",
        thcScore = 92,
        cbd = "0.1% - 0.2%",
        terpenes = "Caryophyllene, Myrcene, Limonene",
        flavors = "Earthy Mocha, Pungent Pine, Sour Diesel",
        effects = "Deep Physical Melt, Content, Unwound",
        origin = "Nevada / California (Joesy Whales, 2014)",
        description = "Also known as Original Glue, GG4 was discovered by breeder Joesy Whales and named for the sticky resin that coated trimming scissors. A multiple Cannabis Cup champion with chocolate-diesel depth."
    },
    {
        name = "Afghani",
        type = "Indica",
        ratio = "100% Pure Landrace Indica",
        sativaPct = 0,
        lineage = "Afghan Mountain Landrace",
        thc = "15% - 20%",
        thcScore = 62,
        cbd = "0.2% - 0.7%",
        terpenes = "Myrcene, Pinene, Caryophyllene",
        flavors = "Rich Earth, Pine Resin, Sweet Hash",
        effects = "Grounded, Restful, Deeply Soothing",
        origin = "Afghanistan (Ancient Heirloom Landrace)",
        description = "One of the oldest domesticated cannabis varieties in human history, Afghani landraces were traditionally cultivated for hand-rubbed charas and sieved hashish, passing their broad leaves and dense resin on to modern Indicas."
    },
    {
        name = "9 Pound Hammer",
        type = "Indica",
        ratio = "80% Indica / 20% Sativa",
        sativaPct = 20,
        lineage = "Gooberry x Hells OG x Jack the Ripper",
        thc = "19% - 24%",
        thcScore = 78,
        cbd = "0.1% - 0.3%",
        terpenes = "Myrcene, Pinene, Caryophyllene",
        flavors = "Sweet Lime, Melon, Earthy Grape",
        effects = "Heavy Slumber, Deep Rest, Calm",
        origin = "Pacific Northwest (Jinxproof Genetics)",
        description = "Bred by Jinxproof Genetics from Gooberry, Hells OG, and Jack the Ripper, 9 Pound Hammer wraps sweet melon-and-lime aromatics around a long-lasting evening tranquility."
    }
}

-- Terpene Reference Glossary (accessible as the "Terpenes" filter tab!)
local TERPENE_GUIDE <const> = {
    {
        name = "Myrcene (The Herbal Calm)",
        type = "Terpene",
        ratio = "Boiling Point: 334°F (168°C)",
        sativaPct = 25,
        lineage = "Also found in: Mangoes, Hops, Lemongrass, Thyme",
        thc = "Abundance: #1 Most Common Terpene",
        thcScore = 95,
        cbd = "Aroma: Earthy, Musky, Clove, Ripe Fruit",
        terpenes = "Key Strains: Blue Dream, OG Kush, Granddaddy Purple",
        flavors = "Earthy Musk, Balsamic Herb, Sweet Mango",
        effects = "Soothing, Grounding, Physical Ease",
        origin = "Monoterpene",
        description = "Beta-myrcene is the most prevalent terpene in modern cannabis cultivars. It contributes a rich, earthy, slightly fruity bouquet reminiscent of ripe mangoes and hops, and is heavily associated with soothing, full-body comfort."
    },
    {
        name = "Limonene (The Citrus Spark)",
        type = "Terpene",
        ratio = "Boiling Point: 349°F (176°C)",
        sativaPct = 75,
        lineage = "Also found in: Lemon Rind, Orange Peel, Juniper",
        thc = "Abundance: #2 Most Common Terpene",
        thcScore = 85,
        cbd = "Aroma: Zesty Lemon, Tangy Orange, Grapefruit",
        terpenes = "Key Strains: Wedding Cake, Sour Diesel, Hindu Kush",
        flavors = "Bright Citrus, Sweet Orange, Lemon Zest",
        effects = "Elevated Mood, Bright, Refreshing",
        origin = "Cyclic Monoterpene",
        description = "Limonene gives citrus fruits and citrus-forward strains their unmistakable zesty punch. In aromatherapy and botanical research, limonene is studied for its mood-brightening and stress-relieving qualities."
    },
    {
        name = "Caryophyllene (The Peppery Spice)",
        type = "Terpene",
        ratio = "Boiling Point: 266°F (130°C)",
        sativaPct = 50,
        lineage = "Also found in: Black Pepper, Cloves, Cinnamon, Rosemary",
        thc = "Abundance: #3 Most Common Terpene",
        thcScore = 80,
        cbd = "Aroma: Cracked Pepper, Warm Wood, Clove",
        terpenes = "Key Strains: GSC, Gelato, Bubba Kush, GG4",
        flavors = "Spicy Black Pepper, Warm Clove, Diesel",
        effects = "Balancing, Comforting, Grounded",
        origin = "Sesquiterpene (Binds to CB2 Receptors)",
        description = "Beta-caryophyllene is unique among terpenes because its molecular structure allows it to bind directly to peripheral CB2 endocannabinoid receptors, acting as both an aromatic terpene and a dietary cannabinoid."
    },
    {
        name = "Pinene (The Forest Breeze)",
        type = "Terpene",
        ratio = "Boiling Point: 311°F (155°C)",
        sativaPct = 70,
        lineage = "Also found in: Pine Needles, Rosemary, Basil, Cedar",
        thc = "Abundance: Most Common Terpene in Nature",
        thcScore = 70,
        cbd = "Aroma: Crisp Pine Forest, Fresh Fir, Rosemary",
        terpenes = "Key Strains: Jack Herer, Blue Dream, Strawberry Cough",
        flavors = "Fresh Pine Needles, Resinous Cedar, Herb",
        effects = "Alert, Clear-Headed, Crisp",
        origin = "Bicyclic Monoterpene (Alpha & Beta)",
        description = "Alpha- and beta-pinene are the most abundant terpenes in the natural plant kingdom. Walking through a pine forest fills the air with pinene, prized in cannabis cultivars for promoting crisp mental clarity."
    },
    {
        name = "Terpinolene (The Floral Wood)",
        type = "Terpene",
        ratio = "Boiling Point: 365°F (185°C)",
        sativaPct = 90,
        lineage = "Also found in: Lilacs, Nutmeg, Tea Tree, Apples",
        thc = "Abundance: Signature of Classic Sativas",
        thcScore = 60,
        cbd = "Aroma: Fresh Pine, Floral Lilac, Herbal Citrus",
        terpenes = "Key Strains: Durban Poison, Jack Herer, Super Lemon Haze",
        flavors = "Floral Pine, Sweet Herb, Nutmeg",
        effects = "Uplifted, Cerebral, Creative",
        origin = "Monoterpene",
        description = "Though dominant in roughly 1 in 10 strains, terpinolene is the defining aromatic signature of classic Haze and Durban Sativa families, blending floral lilac, crisp apple, and pine into an invigorating bouquet."
    },
    {
        name = "Linalool (The Lavender Floral)",
        type = "Terpene",
        ratio = "Boiling Point: 388°F (198°C)",
        sativaPct = 20,
        lineage = "Also found in: Lavender, Coriander, Sweet Basil",
        thc = "Abundance: Prized Minor Terpene",
        thcScore = 50,
        cbd = "Aroma: Floral Lavender, Soft Spice, Spring Blossom",
        terpenes = "Key Strains: Zkittlez, Lavender, Amnesia Haze",
        flavors = "Floral Lavender, Delicate Berry, Sweet Herb",
        effects = "Peaceful, Unwound, Serene",
        origin = "Terpene Alcohol",
        description = "Linalool gives English lavender its beloved soothing fragrance. When present in cannabis cultivars alongside myrcene or caryophyllene, it imparts a delicate floral elegance and deep sense of serenity."
    }
}

-- Filter Tabs
local CATEGORIES <const> = { "All", "Sativa", "Indica", "Hybrid", "Favs", "Terpenes" }
local categoryIndex = 1

-- App State: "DIRECTORY" (split-screen list + summary card) or "READER" (full-screen scrollable article)
local viewMode = "DIRECTORY"
local filteredList = {}
local selectedIndex = 1
local listScrollTop = 1
local VISIBLE_ROWS <const> = 8

-- Reader View vertical scroll offset (pixels)
local readerScrollY = 0
local readerMaxScrollY = 220
local crankTickAccum = 0

-- Saved Bookmarks / Favorites table (strain name -> boolean)
local favorites = {}

local function loadFavorites()
    local saved = playdate.datastore.read("favorites")
    if saved and type(saved) == "table" then
        favorites = saved
    else
        -- Default a couple of classics as bookmarked so the Favs tab is immediately useful
        favorites = { ["Blue Dream"] = true, ["Jack Herer"] = true, ["Northern Lights"] = true }
    end
end

local function saveFavorites()
    playdate.datastore.write(favorites, "favorites")
end

local function toggleCurrentFavorite()
    local item = filteredList[selectedIndex]
    if not item or item.type == "Terpene" then return end
    if favorites[item.name] then
        favorites[item.name] = nil
    else
        favorites[item.name] = true
    end
    saveFavorites()
    sfxClick:playNote(580, 0.2, 0.04)
end

local function rebuildFilteredList()
    local cat = CATEGORIES[categoryIndex]
    filteredList = {}

    if cat == "Terpenes" then
        for _, t in ipairs(TERPENE_GUIDE) do
            table.insert(filteredList, t)
        end
    else
        for _, s in ipairs(STRAINS) do
            if cat == "All" then
                table.insert(filteredList, s)
            elseif cat == "Favs" then
                if favorites[s.name] then
                    table.insert(filteredList, s)
                end
            elseif s.type == cat then
                table.insert(filteredList, s)
            end
        end
    end

    if selectedIndex > #filteredList then
        selectedIndex = math.max(1, #filteredList)
    end
    if selectedIndex < listScrollTop then
        listScrollTop = selectedIndex
    elseif selectedIndex > listScrollTop + VISIBLE_ROWS - 1 then
        listScrollTop = math.max(1, selectedIndex - VISIBLE_ROWS + 1)
    end
end

-- Draw a small 1-bit botanical leaf emblem styled to the strain's type (Sativa=slender, Indica=broad, Hybrid=balanced)
local function drawBotanicalEmblem(cx, cy, radius, strainType)
    gfx.setColor(gfx.kColorBlack)
    gfx.setLineWidth(1)

    -- Circular badge frame
    gfx.drawCircleAtPoint(cx, cy, radius)

    local angles = { -90, -132, -48, -166, -14 }
    local lengths = { radius - 3, radius - 5, radius - 5, radius - 8, radius - 8 }
    local leafWidth = (strainType == "Indica") and 3.5 or ((strainType == "Sativa") and 1.6 or 2.5)

    -- Stem
    gfx.drawLine(cx, cy + 2, cx, cy + radius - 2)

    for i, deg in ipairs(angles) do
        local rad = math.rad(deg)
        local len = lengths[i]
        local tipX = cx + math.cos(rad) * len
        local tipY = cy + 3 + math.sin(rad) * len
        local midX = cx + math.cos(rad) * (len * 0.52)
        local midY = cy + 3 + math.sin(rad) * (len * 0.52)
        local perpX = -math.sin(rad) * leafWidth
        local perpY = math.cos(rad) * leafWidth

        gfx.drawLine(cx, cy + 3, tipX, tipY)
        gfx.drawLine(cx, cy + 3, midX + perpX, midY + perpY)
        gfx.drawLine(midX + perpX, midY + perpY, tipX, tipY)
        gfx.drawLine(cx, cy + 3, midX - perpX, midY - perpY)
        gfx.drawLine(midX - perpX, midY - perpY, tipX, tipY)
    end
end

-- Draw Top Category Filter Bar
local function drawCategoryBar()
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(0, 0, SCREEN_W, 22)
    gfx.setColor(gfx.kColorBlack)
    gfx.setLineWidth(1)
    gfx.drawLine(0, 22, SCREEN_W, 22)

    local tabX = 4
    for i, cat in ipairs(CATEGORIES) do
        local label = (cat == "Favs") and "★Favs" or cat
        local textW = gfx.getTextSize(label)
        local pillW = textW + 10

        if i == categoryIndex then
            gfx.setColor(gfx.kColorBlack)
            gfx.fillRoundRect(tabX, 2, pillW, 17, 3)
            gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
            gfx.drawText(label, tabX + 5, 3)
            gfx.setImageDrawMode(gfx.kDrawModeCopy)
        else
            gfx.setColor(gfx.kColorBlack)
            gfx.drawText(label, tabX + 5, 3)
        end
        tabX = tabX + pillW + 4
    end
end

-- Draw Split-Screen Directory View (Left: Strain List, Right: At-a-Glance Summary Card)
local function drawDirectoryView()
    drawCategoryBar()

    local listW = 166
    local contentTop = 23
    local contentBottom = SCREEN_H - 18
    local contentH = contentBottom - contentTop

    -- Vertical divider between strain directory and preview card
    gfx.setColor(gfx.kColorBlack)
    gfx.drawLine(listW, contentTop, listW, contentBottom)

    if #filteredList == 0 then
        gfx.drawText("No Favorites yet!", 14, 90)
        gfx.drawText("Press B on any", 14, 110)
        gfx.drawText("strain to ★ star it.", 14, 128)
    else
        local rowH = 22
        for r = 0, VISIBLE_ROWS - 1 do
            local idx = listScrollTop + r
            if idx <= #filteredList then
                local item = filteredList[idx]
                local rowY = contentTop + 2 + r * rowH
                local isSelected = (idx == selectedIndex)

                if isSelected then
                    gfx.setColor(gfx.kColorBlack)
                    gfx.fillRoundRect(3, rowY, listW - 9, rowH - 2, 3)
                    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
                else
                    gfx.setColor(gfx.kColorBlack)
                    gfx.setImageDrawMode(gfx.kDrawModeCopy)
                end

                local prefix = favorites[item.name] and "★ " or ""
                -- Truncate long title cleanly in directory column
                local displayTitle = prefix .. item.name
                gfx.drawTextInRect(displayTitle, 7, rowY + 2, listW - 18, rowH - 2)
                gfx.setImageDrawMode(gfx.kDrawModeCopy)
            end
        end

        -- Scrollbar along the right edge of the left list pane
        if #filteredList > VISIBLE_ROWS then
            local trackX = listW - 4
            local trackY = contentTop + 4
            local trackH = contentH - 8
            local thumbH = math.max(14, math.floor((VISIBLE_ROWS / #filteredList) * trackH))
            local maxTop = #filteredList - VISIBLE_ROWS
            local thumbY = trackY + math.floor(((listScrollTop - 1) / maxTop) * (trackH - thumbH))
            gfx.setColor(gfx.kColorBlack)
            gfx.fillRect(trackX, thumbY, 2, thumbH)
        end
    end

    -- Right Pane: At-a-Glance Summary Card for the highlighted strain
    local item = filteredList[selectedIndex]
    if item then
        local rx = listW + 8
        local rw = SCREEN_W - rx - 6

        -- Botanical Leaf Emblem on top-right of summary card
        drawBotanicalEmblem(SCREEN_W - 24, contentTop + 22, 16, item.type)

        -- Strain Name & Category Pill
        gfx.drawText("*" .. item.name .. "*", rx, contentTop + 4)

        local badgeText = string.upper(item.type) .. "  |  " .. item.thc
        gfx.drawText(badgeText, rx, contentTop + 23)

        -- Sativa / Indica Visual Balance Bar
        local barY = contentTop + 43
        local barW = rw
        gfx.drawRect(rx, barY, barW, 7)
        local satFillW = math.floor((item.sativaPct / 100.0) * (barW - 2))
        gfx.fillRect(rx + 1, barY + 1, satFillW, 5)
        gfx.drawText(item.ratio, rx, barY + 10)

        -- Divider line
        gfx.drawLine(rx, barY + 28, SCREEN_W - 8, barY + 28)

        -- Genetics / Lineage
        gfx.drawTextInRect("*Lineage:* " .. item.lineage, rx, barY + 32, rw, 34)

        -- Dominant Terpenes
        gfx.drawTextInRect("*Terpenes:* " .. item.terpenes, rx, barY + 68, rw, 34)

        -- Flavor & Effects summary
        gfx.drawTextInRect("*Flavor:* " .. item.flavors, rx, barY + 104, rw, 20)
        gfx.drawTextInRect("*Effects:* " .. item.effects, rx, barY + 122, rw, 20)
    end

    -- Bottom Controls Bar
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(0, SCREEN_H - 18, SCREEN_W, 18)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawLine(0, SCREEN_H - 18, SCREEN_W, SCREEN_H - 18)
    gfx.drawText("Crank/U/D: Browse  L/R: Filter  A: Read Entry  B: ★Fav", 6, SCREEN_H - 15)
end

-- Draw Full-Screen Scrollable Reader View for in-depth reading
local function drawReaderView()
    local item = filteredList[selectedIndex]
    if not item then return end

    local y = 26 - readerScrollY
    local padX = 12
    local contentW = SCREEN_W - 28

    -- Header Section: Botanical Emblem + Title + Origin
    drawBotanicalEmblem(28, y + 18, 16, item.type)
    local starMark = favorites[item.name] and " ★" or ""
    gfx.drawText("*" .. item.name .. starMark .. "*", 52, y)
    gfx.drawText(item.type .. "  —  " .. item.ratio, 52, y + 19)

    y = y + 44
    gfx.drawLine(padX, y, SCREEN_W - 16, y)
    y = y + 8

    -- Overview & History Paragraphs (tall readable block)
    gfx.drawText("*COMPENDIUM OVERVIEW & HISTORY*", padX, y)
    y = y + 20
    local _, descH = gfx.drawTextInRect(item.description, padX, y, contentW, 140)
    y = y + math.max(68, descH) + 10

    -- Genetics & Origin Box
    gfx.drawRoundRect(padX, y, contentW, 50, 4)
    gfx.drawTextInRect("*Genetics:* " .. item.lineage, padX + 6, y + 6, contentW - 12, 20)
    gfx.drawTextInRect("*Origin:* " .. item.origin, padX + 6, y + 26, contentW - 12, 20)
    y = y + 60

    -- Cannabinoid & Potency Meter Box
    gfx.drawRoundRect(padX, y, contentW, 54, 4)
    gfx.drawText("*Cannabinoids:*  THC: " .. item.thc .. "   |   CBD: " .. item.cbd, padX + 6, y + 6)
    -- Potency Meter Bar
    gfx.drawText("Potency:", padX + 6, y + 28)
    local meterX = padX + 74
    local meterW = contentW - 86
    gfx.drawRect(meterX, y + 31, meterW, 10)
    local fillW = math.floor((item.thcScore / 100.0) * (meterW - 4))
    gfx.fillRect(meterX + 2, y + 33, fillW, 6)
    y = y + 64

    -- Terpenes, Flavors, and Effects Breakdown
    gfx.drawRoundRect(padX, y, contentW, 74, 4)
    gfx.drawTextInRect("*Dominant Terpenes:* " .. item.terpenes, padX + 6, y + 6, contentW - 12, 20)
    gfx.drawTextInRect("*Flavor & Aroma:* " .. item.flavors, padX + 6, y + 28, contentW - 12, 20)
    gfx.drawTextInRect("*Reported Effects:* " .. item.effects, padX + 6, y + 50, contentW - 12, 20)
    y = y + 86

    -- Sativa vs Indica Spectrum Meter
    gfx.drawText("*Sativa / Indica Spectrum:* " .. item.ratio, padX, y)
    y = y + 20
    gfx.drawRect(padX, y, contentW, 12)
    local satW = math.floor((item.sativaPct / 100.0) * (contentW - 4))
    gfx.fillRect(padX + 2, y + 2, satW, 8)
    y = y + 24

    -- Dynamically update max scroll range so player can scroll smoothly to the bottom
    readerMaxScrollY = math.max(0, (y + readerScrollY) - (SCREEN_H - 26))

    -- Fixed Top Header Bar in Reader View
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(0, 0, SCREEN_W, 20)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawLine(0, 20, SCREEN_W, 20)
    local hdrText = string.format("*ENTRY %d/%d*  |  %s (%s)", selectedIndex, #filteredList, item.name, item.type)
    gfx.drawText(hdrText, 6, 2)

    -- Right-edge Reader Scrollbar
    if readerMaxScrollY > 0 then
        local trackY = 24
        local trackH = SCREEN_H - 46
        local thumbH = 26
        local thumbY = trackY + math.floor((readerScrollY / readerMaxScrollY) * (trackH - thumbH))
        gfx.fillRect(SCREEN_W - 5, thumbY, 3, thumbH)
    end

    -- Fixed Bottom Helper Bar in Reader View
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(0, SCREEN_H - 18, SCREEN_W, 18)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawLine(0, SCREEN_H - 18, SCREEN_W, SCREEN_H - 18)
    gfx.drawText("Crank/U/D: Scroll Page   L/R: Prev/Next Strain   A: ★Fav   B: Back", 6, SCREEN_H - 15)
end

local function moveSelection(delta)
    if #filteredList == 0 then return end
    selectedIndex = selectedIndex + delta
    if selectedIndex < 1 then
        selectedIndex = #filteredList
    elseif selectedIndex > #filteredList then
        selectedIndex = 1
    end

    if selectedIndex < listScrollTop then
        listScrollTop = selectedIndex
    elseif selectedIndex > listScrollTop + VISIBLE_ROWS - 1 then
        listScrollTop = selectedIndex - VISIBLE_ROWS + 1
    end

    readerScrollY = 0
    sfxClick:playNote(420, 0.14, 0.02)
end

local function setupMenu()
    local menu = playdate.getSystemMenu()
    menu:removeAllMenuItems()

    menu:addMenuItem("Random Strain", function()
        categoryIndex = 1
        rebuildFilteredList()
        selectedIndex = math.random(1, #filteredList)
        moveSelection(0)
        viewMode = "READER"
        readerScrollY = 0
    end)

    menu:addMenuItem("Terpene Guide", function()
        for i, c in ipairs(CATEGORIES) do
            if c == "Terpenes" then
                categoryIndex = i
                break
            end
        end
        rebuildFilteredList()
        selectedIndex = 1
        viewMode = "READER"
        readerScrollY = 0
    end)

    menu:addMenuItem("Directory List", function()
        viewMode = "DIRECTORY"
    end)
end

local function init()
    math.randomseed(playdate.getSecondsSinceEpoch())
    loadFavorites()
    rebuildFilteredList()
    setupMenu()
end

init()

function playdate.update()
    local crankChange = playdate.getCrankChange()

    if viewMode == "DIRECTORY" then
        -- Up / Down or Crank browses through the strain list
        if playdate.buttonJustPressed(playdate.kButtonUp) then
            moveSelection(-1)
        elseif playdate.buttonJustPressed(playdate.kButtonDown) then
            moveSelection(1)
        end

        if math.abs(crankChange) > 0.1 then
            crankTickAccum = crankTickAccum + crankChange
            if crankTickAccum >= 18 then
                crankTickAccum = crankTickAccum - 18
                moveSelection(1)
            elseif crankTickAccum <= -18 then
                crankTickAccum = crankTickAccum + 18
                moveSelection(-1)
            end
        end

        -- Left / Right switches Category Filter tabs (All, Sativa, Indica, Hybrid, Favs, Terpenes)
        if playdate.buttonJustPressed(playdate.kButtonLeft) then
            categoryIndex = categoryIndex - 1
            if categoryIndex < 1 then categoryIndex = #CATEGORIES end
            selectedIndex = 1
            listScrollTop = 1
            rebuildFilteredList()
            sfxClick:playNote(350, 0.16, 0.03)
        elseif playdate.buttonJustPressed(playdate.kButtonRight) then
            categoryIndex = categoryIndex + 1
            if categoryIndex > #CATEGORIES then categoryIndex = 1 end
            selectedIndex = 1
            listScrollTop = 1
            rebuildFilteredList()
            sfxClick:playNote(350, 0.16, 0.03)
        end

        -- A opens the Full-Screen Reader View for the selected strain
        if playdate.buttonJustPressed(playdate.kButtonA) and #filteredList > 0 then
            viewMode = "READER"
            readerScrollY = 0
            sfxClick:playNote(520, 0.18, 0.04)
        end

        -- B toggles Favorite / Bookmark star on the selected strain
        if playdate.buttonJustPressed(playdate.kButtonB) and #filteredList > 0 then
            toggleCurrentFavorite()
            if CATEGORIES[categoryIndex] == "Favs" then
                rebuildFilteredList()
            end
        end

    elseif viewMode == "READER" then
        -- Smooth page scrolling via Crank or Up/Down D-pad
        if math.abs(crankChange) > 0.05 then
            readerScrollY = math.max(0, math.min(readerMaxScrollY, readerScrollY + crankChange * 1.35))
        end

        if playdate.buttonIsPressed(playdate.kButtonDown) then
            readerScrollY = math.min(readerMaxScrollY, readerScrollY + 5)
        elseif playdate.buttonIsPressed(playdate.kButtonUp) then
            readerScrollY = math.max(0, readerScrollY - 5)
        end

        -- Left / Right flips directly to the Previous / Next strain entry while reading
        if playdate.buttonJustPressed(playdate.kButtonLeft) then
            moveSelection(-1)
        elseif playdate.buttonJustPressed(playdate.kButtonRight) then
            moveSelection(1)
        end

        -- A toggles Favorite star while reading
        if playdate.buttonJustPressed(playdate.kButtonA) then
            toggleCurrentFavorite()
        end

        -- B returns to the Split-Screen Directory View
        if playdate.buttonJustPressed(playdate.kButtonB) then
            viewMode = "DIRECTORY"
            if CATEGORIES[categoryIndex] == "Favs" then
                rebuildFilteredList()
            end
            sfxClick:playNote(320, 0.16, 0.03)
        end
    end

    -- Render frame
    gfx.clear(gfx.kColorWhite)
    if viewMode == "DIRECTORY" then
        drawDirectoryView()
    else
        drawReaderView()
    end

    playdate.timer.updateTimers()
end
