# Fixed parameters, values as in John Drake et al., 2018
R = 8.314472e-3 # Universal gas constant, kJ K-1 mol-1
O2airfrac = 0.209 # volume of O2 in the air, L L-1
BD = 1.5396 # Soil bulk density, g cm-3  
PD = 2.52 # Soil particle density, g cm-3
porosity = 1-BD/PD # total porosity 
psx = 2.4e-2 # Fraction of soil C that is considered soluble
Dliq = 3.17 # Diffusion coeff of substrate in liquid phase, dimensionless
Dgas = 1.67 # Diffusion coefficient of oxygen in air, dimensionless
Soildepth = 10 # effective soil depth, cm
