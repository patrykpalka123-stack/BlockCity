-- ModuleScript: ServerScriptService > CityConfig
-- Wspólne stałe miasta i wzory pasów ruchu (te same co w wersji przeglądarkowej, 1 blok = 4 study)
local M = {}
M.PITCH = 64      -- odległość między skrzyżowaniami (16 bloków)
M.N = 7           -- 7 x 7 skrzyżowań
M.ROADY = 0.2     -- wysokość nawierzchni
M.SPAWN = Vector3.new(4 * 64 + 12, 4, 4 * 64 + 12)
-- kierunki: 0 = +X (wschód), 1 = +Z (południe), 2 = -X, 3 = -Z  (tablica indeksowana od 1!)
M.DIRS = { {1, 0}, {0, 1}, {-1, 0}, {0, -1} }
local P = M.PITCH

function M.laneC(d, k, l)
	if d == 0 then return l * P + 18
	elseif d == 2 then return l * P + 6
	elseif d == 1 then return k * P + 6
	else return k * P + 18 end
end

-- punkt wjazdu na skrzyżowanie (x, z)
function M.entryPt(d, k, l)
	if d == 0 then return k * P, M.laneC(0, k, l)
	elseif d == 2 then return k * P + 24, M.laneC(2, k, l)
	elseif d == 1 then return M.laneC(1, k, l), l * P
	else return M.laneC(3, k, l), l * P + 24 end
end

-- punkt wyjazdu ze skrzyżowania (x, z)
function M.exitPt(d, k, l)
	if d == 0 then return k * P + 24, M.laneC(0, k, l)
	elseif d == 2 then return k * P, M.laneC(2, k, l)
	elseif d == 1 then return M.laneC(1, k, l), l * P + 24
	else return M.laneC(3, k, l), l * P end
end

function M.okI(k, l)
	return k >= 1 and k <= M.N and l >= 1 and l <= M.N
end

-- stan świateł dla kierunku d (parzyste = oś X, nieparzyste = oś Z): "g" / "y" / "r"
function M.lightOf(d)
	local p = workspace:GetServerTimeNow() % 12
	if d % 2 == 0 then
		if p < 5 then return "g" elseif p < 6 then return "y" else return "r" end
	else
		if p < 6 then return "r" elseif p < 11 then return "g" else return "y" end
	end
end

return M
