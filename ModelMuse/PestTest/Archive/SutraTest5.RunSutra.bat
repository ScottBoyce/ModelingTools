if exist "SutraTest5.SUTRA.FIL" copy /Y "SutraTest5.SUTRA.FIL" "SUTRA.FIL"
"sutra_2_2.exe"
"SutraObsExtractor.exe" SutraTest5.soe_i
Start C:\ModelingTools\ModelMonitor\Release\Win64\ListingAnalyst.exe SutraTest5.lst
pause
