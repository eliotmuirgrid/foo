local Configs = component.fields()
Configs.Port = 4000 -- TODO DELETE ME WHEN WE FIX CUSTOM fields.
local CHKerrMsg

local function CHKreportError()
   if CHKerrMsg then
      component.setStatus{data = '<p style="color:red;">' .. CHKerrMsg .. '</p>'}
      error(CHKerrMsg, 3)
   end
end

-- Port
if not Configs.Port then
   CHKerrMsg = "Required custom field 'Port' not found."
end
CHKreportError()

-- all good, reset status
component.setStatus{data = ""}