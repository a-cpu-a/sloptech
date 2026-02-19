local mn = "sloptech";
_G[mn] = { _priv = {}, dir = {}, pipey = {} };

--https://api.luanti.org/
--https://github.com/GregTechCEu/GregTech-Modern?tab=readme-ov-file
--DO NOT USE: https://github.com/brachy84/zedtech-ceu?tab=readme-ov-file (not chill license!)
-- maybe ok, as mit: https://github.com/ULSTICK/GregTechRefreshed

dofile(core.get_modpath(mn) .. "/content/pipey/init.lua");
dofile(core.get_modpath(mn) .. "/content/tools/wrench.lua");
dofile(core.get_modpath(mn) .. "/content/machines/register_machines.lua");
dofile(core.get_modpath(mn) .. "/content/dev/register_dev.lua");
