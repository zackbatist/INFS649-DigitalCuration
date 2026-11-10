-- Keep each slide title and its speaker notes; drop the slide content.
-- Content before the first slide title (the page intro) stays as written.

local function starts(b, s)
  return (b.t == 'Para' or b.t == 'Plain') and pandoc.utils.stringify(b):sub(1, #s) == s
end

local symbols = { ['▶'] = true, ['⏭'] = true, ['⏸'] = true }

-- Drop the cue symbol; the badge style marks the cue on the page.
local function strip(b)
  return pandoc.walk_block(b, {
    Inlines = function(ils)
      if #ils > 0 and ils[1].t == 'Str' and symbols[ils[1].text] then
        ils:remove(1)
        if #ils > 0 and ils[1].t == 'Space' then ils:remove(1) end
      end
      return ils
    end
  })
end

local function mark(b)
  if starts(b, '▶') then return pandoc.Div({strip(b)}, pandoc.Attr('', {'cue', 'click'})) end
  if starts(b, '⏭') then return pandoc.Div({strip(b)}, pandoc.Attr('', {'cue', 'next'})) end
  if starts(b, '⏸') then return pandoc.Div({strip(b)}, pandoc.Attr('', {'cue', 'pause'})) end
  return b
end

function Pandoc(doc)
  local out, started = {}, false
  for _, b in ipairs(doc.blocks) do
    if b.t == 'Header' and b.level == 2 then
      started = true
      table.insert(out, b)
    elseif not started then
      table.insert(out, b)
    elseif b.t == 'Div' and b.classes:includes('notes') then
      for _, x in ipairs(b.content) do table.insert(out, mark(x)) end
    end
  end
  doc.blocks = out
  return doc
end
