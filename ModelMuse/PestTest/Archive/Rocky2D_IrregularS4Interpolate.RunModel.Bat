if exist "arrays\Rocky2D_IrregularS4Interpolate.Maximum_Permeability_1.arrays" del "arrays\Rocky2D_IrregularS4Interpolate.Maximum_Permeability_1.arrays"
if exist "arrays\Rocky2D_IrregularS4Interpolate.Maximum_Permeability_2.arrays" del "arrays\Rocky2D_IrregularS4Interpolate.Maximum_Permeability_2.arrays"
if exist "arrays\Rocky2D_IrregularS4Interpolate.Middle_Permeability_1.arrays" del "arrays\Rocky2D_IrregularS4Interpolate.Middle_Permeability_1.arrays"
if exist "arrays\Rocky2D_IrregularS4Interpolate.Middle_Permeability_2.arrays" del "arrays\Rocky2D_IrregularS4Interpolate.Middle_Permeability_2.arrays"
if exist "arrays\Rocky2D_IrregularS4Interpolate.Minimum_Permeability_1.arrays" del "arrays\Rocky2D_IrregularS4Interpolate.Minimum_Permeability_1.arrays"
if exist "arrays\Rocky2D_IrregularS4Interpolate.Minimum_Permeability_2.arrays" del "arrays\Rocky2D_IrregularS4Interpolate.Minimum_Permeability_2.arrays"
if exist "arrays\Rocky2D_IrregularS4Interpolate.ScaledEffectiveAirThermalConductivity_1.arrays" del "arrays\Rocky2D_IrregularS4Interpolate.ScaledEffectiveAirThermalConductivity_1.arrays"
if exist "arrays\Rocky2D_IrregularS4Interpolate.ScaledEffectiveAirThermalConductivity_2.arrays" del "arrays\Rocky2D_IrregularS4Interpolate.ScaledEffectiveAirThermalConductivity_2.arrays"
if exist "Rocky2D_IrregularS4Interpolate.14B_1" del "Rocky2D_IrregularS4Interpolate.14B_1"
if exist "Rocky2D_IrregularS4Interpolate.14B_2" del "Rocky2D_IrregularS4Interpolate.14B_2"
if exist "Rocky2D_IrregularS4Interpolate.14B_3" del "Rocky2D_IrregularS4Interpolate.14B_3"
if exist "Rocky2D_IrregularS4Interpolate.15B_1" del "Rocky2D_IrregularS4Interpolate.15B_1"
if exist "Rocky2D_IrregularS4Interpolate.15B_2" del "Rocky2D_IrregularS4Interpolate.15B_2"
if exist "Rocky2D_IrregularS4Interpolate.bcof" del "Rocky2D_IrregularS4Interpolate.bcof"
if exist "Rocky2D_IrregularS4Interpolate.bcop" del "Rocky2D_IrregularS4Interpolate.bcop"
if exist "Rocky2D_IrregularS4Interpolate.ele" del "Rocky2D_IrregularS4Interpolate.ele"
if exist "Rocky2D_IrregularS4Interpolate.lst" del "Rocky2D_IrregularS4Interpolate.lst"
if exist "Rocky2D_IrregularS4Interpolate.nod" del "Rocky2D_IrregularS4Interpolate.nod"
if exist "Rocky2D_IrregularS4Interpolate.rst" del "Rocky2D_IrregularS4Interpolate.rst"
if exist "Rocky2D_IrregularS4Interpolate.smy" del "Rocky2D_IrregularS4Interpolate.smy"
"plproc.exe" Rocky2D_IrregularS4Interpolate.Nodal_Porosity.script
"plproc.exe" Rocky2D_IrregularS4Interpolate.SolidMatrixCompressibility.script
"plproc.exe" Rocky2D_IrregularS4Interpolate.Maximum_Permeability.script
"plproc.exe" Rocky2D_IrregularS4Interpolate.SolidGrain_SpecificHeat.script
"plproc.exe" Rocky2D_IrregularS4Interpolate.ScaledEffectiveAirThermalConductivity.script
"plproc.exe" 'Rocky2D_IrregularS4Interpolate.14B.script'
"EnhancedTemplateProcessor.exe" arrays\Rocky2D_IrregularS4Interpolate.Middle_Permeability_1.arrays.tpl
"EnhancedTemplateProcessor.exe" arrays\Rocky2D_IrregularS4Interpolate.Middle_Permeability_2.arrays.tpl
"EnhancedTemplateProcessor.exe" arrays\Rocky2D_IrregularS4Interpolate.Minimum_Permeability_1.arrays.tpl
"EnhancedTemplateProcessor.exe" arrays\Rocky2D_IrregularS4Interpolate.Minimum_Permeability_2.arrays.tpl
"plproc.exe" 'Rocky2D_IrregularS4Interpolate.15B.script'
"sutra_4_0.exe"
"SutraObsExtractor.exe" Rocky2D_IrregularS4Interpolate.soe_ev