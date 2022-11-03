import sdf_helper as sh
import matplotlib.pyplot as plt

#meta = sh.getdata(rf"{path}/{prefix}"+str(iteration).zfill(4)+".sdf")
#sh.list_variables(meta)

plt.ion()
plt.set_cmap('seismic')
data=sh.getdata(rf"0000.sdf")
sh.plot_auto(data.Derived_Number_Density_Carbon)
