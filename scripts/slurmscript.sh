#!/bin/bash
####################################
#     ARIS slurm script template   #
#                                  #
# Submit script: sbatch filename   #
#                                  #
####################################
#SBATCH --job-name=epoch2D                      # Job name
#SBATCH --output=epoch2D.%j.out                 # Stdout (%j expands to jobId)
#SBATCH --error=epoch2D.%j.err                  # Stderr (%j expands to jobId)
#SBATCH --ntasks=4                             # Number of tasks(processes)
#SBATCH --nodes=1                               # Number of nodes requested
#SBATCH --ntasks-per-node=4                    # Tasks per node
#SBATCH --cpus-per-task=1                       # Threads per task
#SBATCH --time=00:30:00                         # walltime
#SBATCH --qos=normal
#SBATCH --mem=100G                              # memory per NODE
#SBATCH --partition=cpu-opteron                 # Partition

export I_MPI_FABRICS=shm:dapl
if [ x$SLURM_CPUS_PER_TASK == x ]; then
  export OMP_NUM_THREADS=1
else
  export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK
fi

## LOAD MODULES ##
module purge            # clean up loaded modules
# load necessary modules
module load openmpi/openmpi-4.1.1

## RUN YOUR PROGRAM ##
echo /lustre/user/jfuhong/epoch2D_Data_test | srun $HOME/epoch/epoch2d/bin/epoch2d
