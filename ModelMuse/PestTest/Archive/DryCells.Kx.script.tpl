ptf @
#Script for PLPROC

#Read MODFLOW-2005 grid information file
cl_Discretization = read_mf_grid_specs(file="DryCells.gsf")
#Read data to modify
read_list_file(reference_clist='cl_Discretization',skiplines=1, &
  slist=s_PIndex1;column=2, &
  plist=p_Value1;column=3, &
  file='DryCells.Kx.PstValues')
read_list_file(reference_clist='cl_Discretization',skiplines=1, &
  slist=s_PIndex2;column=4, &
  plist=p_Value2;column=5, &
  file='DryCells.Kx.PstValues')
read_list_file(reference_clist='cl_Discretization',skiplines=1, &
  slist=s_PIndex3;column=6, &
  plist=p_Value3;column=7, &
  file='DryCells.Kx.PstValues')

#Read parameter values
HK = @                        HK@
# Pilot points are not used with HK.

# Modfify data values
temp1=new_plist(reference_clist=cl_Discretization,value=0.0)
# Setting values for layer     1
  # Setting values for parameter HK
    # Substituting parameter values in zones
    p_Value1(select=(s_PIndex1 == 1)) = p_Value1 * HK
temp2=new_plist(reference_clist=cl_Discretization,value=0.0)
# Setting values for layer     2
  # Setting values for parameter HK
    # Substituting parameter values in zones
    p_Value2(select=(s_PIndex2 == 1)) = p_Value2 * HK
temp3=new_plist(reference_clist=cl_Discretization,value=0.0)
# Setting values for layer     3
  # Setting values for parameter HK
    # Substituting parameter values in zones
    p_Value3(select=(s_PIndex3 == 1)) = p_Value3 * HK

#Write new data values
write_column_data_file(header='no', &
  file='arrays\DryCells.Kx_1.arrays';delim="space", &
  plist=p_Value1)
write_column_data_file(header='no', &
  file='arrays\DryCells.Kx_2.arrays';delim="space", &
  plist=p_Value2)
write_column_data_file(header='no', &
  file='arrays\DryCells.Kx_3.arrays';delim="space", &
  plist=p_Value3)