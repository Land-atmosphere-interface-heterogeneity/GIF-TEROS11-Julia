# test
# Dual-Arrhenius and Michaelis-Menten model, Davidson et al., 2012
# Mechanistic model of heterotrophic soil respiration as a function of soil temperature (Tsoil, C)  and soil moisture (Msoil, m3 m-3)
# For description and dimension of parameters, see DAMM_param.jl
function DAMM(Tsoil::Float64, Msoil::Float64; kMSx::Float64=1e-8, AlphaSx::Float64=1e8, kMO2::Float64=1e-3, EaSx::Float64=62.0, Sxtot::Float64=0.0125)::Float64 
	Sx = Sxtot * psx * Dliq * Msoil^3
	O2 = Dgas * O2airfrac * ((porosity - Msoil)^(4/3))
	MMSx = Sx / (kMSx + Sx)
	MMO2 = O2 / (kMO2 + O2)
	VmaxSx = (AlphaSx * exp(-EaSx/(R * (273.15 + Tsoil))))
	Resp = VmaxSx * MMSx * MMO2 # in mgC g-1 hr-1
	areaCflux = 10000 * Soildepth * Resp # in mgC m-2 hr-1
	Rsoil = areaCflux / 1000 / 12 * 1e6 / 60 / 60 # in umol CO2 m-2 s-1
end
