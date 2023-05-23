# Ion-Pairing Simulations
Umbrella Sampling Simulations of Ion Solutions in Liquid Water

Written By: Amro Dodin (Geissler & Limmer Groups - UC Berkeley & LBL)

## Software Versions

### LAMMPS Molecular Dynamics

**Molecular Dynamics Software:** LAMMPS 23 June 2022 Release 

**Required Packages:** KSPACE, MOLECULE, RIGID

**Optional Packages:** DRUDE [Drude Polarizable Models], ELECTRODE [Constant Potential Electrode Boundaries]

### Other Software

**Submit Scripts (Queuing System):** Sun Grid Engine

**General Utilities:** Python 3, sed

## Features

This project includes LAMMPS Molecular Dynamics scripts for simulating solutions of ions in water with various types of interfaces (e.g. Air-Water, Air-Conductor and Air-Insulator).
The code is designed to work with a variety of different models for water, ions (including molecular and multivalent ions).
Simple harmonic biasing along atomic z coordinates, and along interatomic distances is included to enable Umbrella Sampling.
Polarizable molecular dynamics support is included using explicit Drude oscillator models and implicit Electronic Continuum Correction models.

## Code Structure

The code is organized as follows:

- FF: Force field parameters, drude parameters, and molecule files
    - Force Fields (```ff.<label>.lmp```): LAMMPS scripts containing force      field parameters. Includes pair, bonded and k-space potentials.
    - Molecule Files (```<name>.mol```): LAMMPS molecule files. See LAMMPS [molecule](https://docs.lammps.org/molecule.html) command for more information.
    - Drude (```drude.dff```): Drude polarizable force field parameters for use with ```polarizer.py```. See LAMMPS [DRUDE](https://docs.lammps.org/Howto_drude2.html) package for more information.
- LAMMPS: LAMMPS input files and submit scripts.
    - ```parameters.lmp```: Contains all default parameters for simulations (see below).
    - ```drude_paramfile```: Alternative parameters more suitable for Drude oscillator simulations.
    - ```init.lmp```: Generates initial configuration of water molecules and ions. Initial configuration is on a lattice.
    - ```run.lmp```: Runs equilibration and/or production molecular dynamics simulations.
    - ```rerun-fields.lmp``` (analysis): A rerun command that computes the electric fields acting on each atom in a completed simulation.
    - ```rerun-water.lmp``` (analysis): A rerun command that computes water bulk statistics from a completed simulation.
    - ```parse_model.lmp``` (internal): Sets internal parameters to match the specified water, ion and boundary condition model (e.g. number of atom types in eqch species).
    - ```parse_biases[_label].lmp``` (internal): Sets internal parameters from the provided bias specifications.
    - ```sub-[X][-umbrella].sh``` (submit): Submit scripts for different stages of the simulation. Scripts labelled ```-umbrella``` generate job arrays for use with umbrella sampling to submit many different bias windows at once. ```X``` denotes what stage of the simulation and matches the ```.lmp``` filenames above.
- SCRIPTS: Utility scripts for parsing and preparing LAMMPS files.
    - ```polarizer.py```: Distributed as part of the LAMMPS [DRUDE](https://docs.lammps.org/Howto_drude2.html) package. Not written by me. It prepares LAMMPS data files for Drude oscillator simulations.
    - ```prep-carbonate-au-pol-data.sh```: Prepares data file for use with ```polarizer.py``` by adding the required labels to the mass section and removing conflicting sections. Built on sed.

## Parameters

### Setting Parameters

Reasonable default parameters that have been validated in a variety of different simulations are provided. 
All parameters and default values are listed in ```parameters.lmp```. 
They can be customized as desired either by providing a ```paramfile``` containing their values or as command line arguments to any of the ```.lmp``` scripts. 

Only one ```paramfile``` can be passed using the command line variable ```-v paramfile <paramfile_name>```. It is written in LAMMPS format. All variables must be set as [index](https://docs.lammps.org/variable.html) type variables. See ```LAMMPS/drude_paramfile``` or ```parameters.lmp``` for examples.

Command-Line Arguments are passed using the LAMMPS command line variable flag ```-v <variable_name> <value>```. 
Any number of variables can be provided but each variable can only appear once.

If multiple values of a given parameter are provided, they take precedence in the following order:

1. Command-Line Arguments
2. paramfile values
3. Default values in ```parameters.lmp```

In addition, if multiple variables are specified in the paramfile for some reason the value listed first takes precedence. 
Only  one paramfile can be provided and each variable can only be specified once in the command line.

Example usage:

    lmp -in run.lmp -v BC electrode -v pot 0.5 -v paramfile drude_paramfile

This runs equilibration and production molecular dynamics simulations with constant potential electrodes set at 0.5 V with Drude oscillators.

**NB:** If performing Drude polarizable simulations remember to pass ```drude_paramfile``` or similar specifications. The default parameters provided in ```parameters.lmp``` are not suitable for Drude oscillator simulations.

### A Few Key Parameters

Every parameter of the MD simulation and analysis has been set up for control via command line or a  paramfile.
Listing all parameters here would take too much space, but they are all listed and documented in ```LAMMPS/parameters.lmp``` with their  default values.

A few key parameters are required to specify which system is being simulated.
The following list of these parameters is provided for quick reference:

- ```cation```: Identity of the cation in the model. Currently the following are available:
    - ```Na```: Sodium +1 Cation. Force fields are provided for both simple point charge and Drude oscillator models.
- ```anion```: Identity  of the anion in the model. Currently the following aree available:
    - ```Cl```: Chloride -1 Anion. Force fields are currently  only provided for a simple point charge model.
    - ```Cl2```: "Chloride" -2 Anion. Also a simple point charge model. This fictitious anion has the same LJ parameters as Chloride but a 2- charge.
    - ```CO3```: Carbonate  2- anion. This is provided as both a simple point charge  model and a Drude polarizable model. Only the Drude model is recomended for acccurate simulation.
- ```water```: Water  model being used. Currently  the  following are available:
    - ```spce```: A rigid three point "simple  point charge model (Ewald") of  water
    - ```tip4p```:  A rigid water  model with 4 simple point charges
    - ```swm4ndp```: "Simple water model with 4 points and negative Drude Particle". This is a polarizable water model that is only for use with Drude simulations.
-   ```BC```: The boundary condition of the simulation. This sets what type of interface is being considered. The following are  currently implemented:
    - ```box```: A periodic  box. This represents bulk water if the size is set large enough.
    - ```slab```: An air-water slab geometry. A slab of water is initialized and a large vacuum area is added above and below.
        - **NB:**  This boundary condition also adds a harmonic constraint on the center of mass in the direction of the vacuum region. This is to stop the slab from wandering around during the simulation. Any separately biased atoms/molecules are excluded from the center of mass constraint.
    - ``` wall ```: A 12-6 Lenard-Jones wall potential is added to the z edge of the simulation. LJ parameters are set by  default to those of gold.
    - ```electrode``` (Requires LAMMPS ELECTRODE Package): An atomistic electrode with constant potential constraints is included on each z end of the simulation.  Each electrode atom has a LJ potential and a point charge that fluctuates to maintain all atoms in the electrode at a fixed  potential. Force fields currently use the lattice  constant and LJ parameters of Gold.
        - ```pot```: The potential difference between the two electrodes. This allows us to  simulate systems with an applied voltage.
        - ```eta```: The charge on each electrode atom is smeared out over a gaussian of width ```eta```. The current default value 1.805 is widely used and characterized in literature.
        - **NB:** Currently the electroneutrality constraint is always imposed. This ensures that at all times the total charge on all electrode atoms is zero. It is not generally recommended to remove this constraint as it leads to non-zero total charge in the periodic simulation which can cause uncontrolled behavior.
    - ```pol```: The polarizable MD method to be used. Currently the following are  implemented:
        - ```False```: No polarizable method is used. This is the default.
        - ```ECC```: The electronic continuum correction. An implicit method that accounts for electronic polarization by simply attenuating solute charge.
            - ```ECC```: A separate variable called ```ECC``` specifies the scaling factor for the ECC model.
        - ```Drude``` (Requires LAMMPS DRUDE Pacakage): Drude  oscillator model. Each polarizable atom is represented  by a positively charged core harmonically attached to a negatively  charged shell. The relative motion of thee core and shell are thermostatted at a low temperature. Adding these negatively charged shells requires a more involved pipeline described below.
            - ```TD```: The Drude temperature at which the relative motion is thermostatted. (See ```parameters.lmp``` for more of the thermostat  parameters).
    - ```DATADIR```: Directory to which data will be saved and which will be searched  for intermediate files. Defaults to current working directory. 
        - **Warning:** LAMMPS will override any existing calculations with the same name in this directory. Make sure that you are concious of this before running a simulation.
    - ```FFDIR```: Directory where relevant force fields are stored. Defaults to the ```FF``` directory if you  are running in the ```LAMMPS``` directory.
    - ```SEED```: The random seed used for the simulation. This is used to seed a random number generator that is in turn used to generate random seeds when required. Simulations run on the same hardware with the same ```SEED``` will produce identical output. Make sure to change this if this is not desired. Commonly, the JOBID or TASKID will be used when submitting jobs to a computational cluster or the  $RANDOM bash variable can be used to generate one on the fly.

## Applying Biases

A crucial feature of this code is the ability to apply a harmonic bias to atomic coordinates in order to facilitate umbrella sampling. 
These are currently implemented using the LAMMPS built in ```fix spring``` since this command provides sufficient flexibility for our purposes and is faster and more portable than the PLUMED pacakge.
The code for implementing the biases is stored separately in ```LAMMPS/parse_biases.lmp```. 
In addition, it is sometimes useful for post processing to construct the groups of atoms that a bias would be applied to without explicitly applying the bias.
The code for doing so is contained in ```LAMMPS/parse_biases_label.lmp```.

Three types of bias potentials are currently implemented, and are accessed with the following variables:

- ```zBias```: Biases the specified atom or molecule towards a set z value.
- ```rBias```: Biases the distance between two specified atoms or molecules.
- ```comBias```: Biases the Center of Mass of all otherwise unbiased atoms. This is turned on by default for slab simulaitons.

Atoms that are subjected to a zBias or rBias are excluded from comBias to avoid conflicting biases which could, for example, make the comBias dependent on the zBias.

As many zBiases and rBiases as desired can be applied but only one comBias can be applied. To accomodate this with LAMMPS command-line variables, this is implemented using multiple entries in a LAMMPS index array.

### Atom Specifier

The first step in setting up a bias potential is specifying which atoms or molecules the bias should apply to. 
This is done using an atom specification string.
If an atom in a molecule is specified, the bias is applied to the entire molecule.

Three options are provided for specifying the atom:

1. index (```id(m)```): Specify the atom by its LAMMPS index.
2. cation (```c(m)```): Bias the $n^{th}$ cation.
2. anion (```a(m)```): Bias the $n^{th}$ anion.

An m must be added if we wish to specify a negative value for the target z value. 
This is clunky but is necessary since we can't use a ```-``` in a command line argument.
See the second example immediately below.

Some example atom specification strings are listed below

    #Format: <id/c/a> <number>
    c 1
    am 3
    id 275 c 2

These specification strings make up part of the zBias and rBias variables.
Each zBias requires you to specify one atom while the rBias requires two.

### z Bias

The zBias variable syntax is as follows:

    -v zBias <AtomSpecifier1> <z1> <k1> <AtomSpecifier2> <z2> <k2> ...

where ```<AtomSpecifieri>``` is an atom specifier described above, ```<zi>``` is the target z value (in $\AA$) and ```<ki>``` is the spring constant (in kCal/mol/$\AA^2$) of the $i^{th}$ harmonic bias.
Both of these numbers can only be positive, so if a negative z value is desired then the atom specifier must be mopdified by adding ```m``` to the string as described above.
In this way, multiple biases can be specified by a single zBias variable.
Note that the variable zBias can only be specified once so all zBiases must be listed after a singlr ```-v zBias``` flag to the LAMMPS scripts.

For example, to run equilibration and production of an Na Cl slab holding the first Na atom at z = 7 $\AA$ and the first Cl atom at z = -5 $\AA$ both with a spring constant of 10 kCal/mol/$\AA^2$ you would use

    lmp -in run.lmp -v cation Na -v anion Cl -v BC slab -v zBias c 1 7 10 am 1 5 10

### r Bias

Specifying an rBias is very similar to a zBias but two Atom Specifiers must be provided and there is no need to apply the negative value atom specifier.
The command syntax looks like 

     -v rBias <FirstAtomSpecifier1> <SecondAtomSpecifier2> <r1> <k1> <FirstAtomSpecifier2> <SecondAtomSpecifier2> <r2> <k2> ...

with all arguments as in the zBias case.

These can be freely combined with zBiases as desired. Suppose we want to bias the first Na atom at z = 7 $\AA$ and hold the first Cl atom at a distance r = 3.5 $\AA$  from this sodium with respective spring constants of 10 and 20 kCal/mol/$\AA^2$ and we would like to do so in an electrode simulation with a 1 V applied potential difference.
This would be accomplished by tge command

    lmp -in run.lmp -v cation Na -v anion Cl -v BC electrode -v pot 1.0 -v zBias c 1 7 10 -v rBias c 1 a 1 3.5 20

### CoM Bias

The center of mass bias is a little simpler since it automatically applies to all atoms not included in a zBias or rBias and fixes the center of mass of those atoms to the origin. The only parameter is therefore the spring constant of the bias and takes the following form

    -v comBias <kCoM>

where ```<kCoM>``` is just the spring constant of the center of mass bias potential.

There is no need to include this when running a slab simulation since this automatically added. 
In other simulations it is usually unnecessary and so this variable is rarely used except for to change the spring constant of the CoM bias in a slab simulation.

## Simulation Labels

Each simulation is assigned a descriptive label that specifies at a glance the key details of the simulation. 
The label reflects the following simulation properties separated by a ```.```:

- Polarizability Model (```Drude```/```ECC```/```BLANK```)
- Boundary Condition (```box```/```slab```/```wall```/```electrode```)
- Water Model (```spce```/```tip4p```/```swm4ndp```)
- Cation Identity (```Na```)
- Anion Identity (```Cl```/```Cl2```/```CO3```)
- Applied Potential (```pot.<Potential>```) [Only for Electrode Simulations]
- Bias Potentials (See Below)

For example, for an unbiased simulation of NaCl in SPC/E water with no polarizability and an electrode boundary condition at 0.5 V applied difference the label would read

    electrode.spce.Na.Cl.pot.0.5

If instead we consider a Drude polarizable Na2CO3 simulation in swm4ndp water with a slab boundary condition the label would read

    Drude.slab.swm4ndp.Na.CO3

All Force Field files and outputs for simulations with these specifications will carry these labels making it easy to identify what conditions each simulation was run under and reducing overwriting of simulations run at different parameters.

The force field label does not include the boundary condition part of the label except for the case of electrode simulations.

### Labels for Biased Simulations

The labeling for bias simulations is a little more involved since an arbitrary number of biases of different types can be included.
Since the bias doesn't affect force field parametrization, the bias portion of the label is omitted.

A center of mass bias is not included in the labeling.

A string is added for each zBias that follows the following format:

    z.<c/a/id><n1>.<z0>.k.<k>

where ```<c/a/id>``` is the atom specifier type (note no "m" is appended, z0 will just be a negative number), ```<n>``` is the number passed to the atom specifier, ```<z0>``` is the target z value ($\AA$), and ```<k>``` is the spring constant (kCal/mol/$\AA^2$).

A similar string is added for each rBias which only differs in that two atoms must be specified

    r.<c/a/id><n1>.<c/a/id>.<n2>.<r0>.k.<k>

with all parameters defined as above.

These are concatenated in the order that they are specified with all non-CoM biases shown.

For example, suppose we have the Drude Na2CO3 simulation with slab Boundary conditions as in the second label example but we now bias the CO3 anion to z = 17 $\AA$ and the two Sodiums at $r_1$ = 3 $\AA$ and  $r_2$ = 5.5 $\AA$ respectively, all with a spring constant of k=10 kCal/mol/$\AA^2$. 
Such a simulation would have the label

    Drude.slab.swm4ndp.Na.CO3.z.a1.17.k.10.r.a1.c1.3.0.k.10.r.a1.c2.5.5.k.10

## Running Simulations

### Simulation Stages

The MD simulations proceed through 4 different stages:

1. **init:** Initialize a grid of water with ions and relax any overlaps by minimizing with a soft force field.
2. **stab:** By default, this step only runs for Drude simulations. Stabilize simulation by running a few steps with full force field and a very short timestep, resetting velocities to 0 periodically. This has been more robust than other methods for starting Drude simulations. Can be turned on by setting the variable ```nStabilizeMax``` to any integer other than ```0```.
3. **eq:** Slowly heat and then equilibrate the simulation. This is intended to be discarded and not analyzed.
4. **prod:** Production MD simulation. This is the main content of the simulation that will be analyzed.

Step 1 is contained in ```init.lmp``` while the remaining steps 2-4 are in ```run.lmp```. If desired, certain steps can be skipped by setting the ```skipProd``` and ```skipEquil``` variables to ```True``` or by setting the ```nHeat```, ```nEquil```, and ```nProd``` and ```nStabilizeMax``` variables that control the number of steps in each stage to ```0```.

**Brief Note on Biased Simulation:** Umbrella sampling biases (if being used) are applied starting in the stabilization step all the way through the production. As a result, each bias window will generally start production in a different initial condition that has already equilibrated to the bias. Note that slab simulations with a liquid vapor interfaces include a center of mass constraint on all particles that are not otherwised biased by default. This standard constraint stops the water slab center of mass from flying around the simulation and does not affect any other applied biases.

### Example Pipelines

To show how these simulations can be strung together consider simulating Na Cl with a confining Wall biazing the Chloride to be at the center of the simulation.
To initialize then run the simulation we would run the following commands in the ```LAMMPS``` directory.

    lmp -in init.lmp -v cation Na -v anion Cl -v BC slab -v DATADIR <DataDir>
    lmp -in run.lmp -v cation Na -v anion Cl -v BC slab -v zBias a 1 0.0 10.0 -v DATADIR <DataDir>

Note that we omitted the zBias commands in the init script since they are not necessary.
It would have been fine to include them, they would have just been ignored in the init script.
The relative path ```<DataDir>``` points to the directory where the simulation output will be stored.

### Drude Oscillator Set-Up

The initialization set up for Drude Oscillator simulations is a bit more involved since we first have to set up a tip4p like box of water, then add the Drude particles to the polarizable species and attach them with new bonds.
The ```polarizer.py``` script in ```SCRIPTS``` is provided by the authors of the LAMMPS DRUDE package to facilitate this process.
Before we can use it however, we need to add labels to the masses section of the init data file and remove the pair potential specifications.
To do this, we have provied the ```prep-pol-data.sh``` script which does this labeling for you.

The ```prep-pol-data.sh``` script requires a sequence of flags that lists the atom types in the order they appear. 
Polarizable atomic species are flagged just with their atom labels (e.g. ```-Na``` or ```-Cl```) which must appear in the ```FF/drude.dff``` Drude parameter file.
Molecular species must be explicitly listed in the script.
Currently only ```-swm4ndp``` and ```-CO3``` are implemented.

Put together this gives the following pipeline for running a Drude simulation from inside the ```LAMMPS``` directory

    lmp -in init.lmp -v cation Na -v anion CO3 -v BC slab -v paramfile drude_paramfile -v DATADIR <DataDir>
    
    cd <DataDir>
    
    <path/to/SCRIPTS>/prep-pol-data.sh -swm4ndp -Na -CO3 data.slab.swm4ndp.Na.CO3.init data.slab.swm4ndp.Na.CO3.prep
    <path/to/SCRIPTS>/polarizer.py -q -f <path/to/FF>/drude.dff data.slab.swm4ndp.Na.CO3.prep data.Drude.slab.swm4ndp.Na.CO3.init
    
    cd <path/to/LAMMPS>
    
    lmp -in run.lmp -v cation Na -v anion CO3 -v BC slab -v paramfile drude_paramfile -v DATADIR <DataDir> -v zBias a 1 0 10.0 -v rBias a 1 c 1 3.5 10.0 a 1 c 2 5.5 10.0

## Submit Scripts

In addition the ```.lmp``` LAMMPS inputs, the ```LAMMPS``` directory includes sample submit scripts to facilitate running these simulations on a HPC cluster or supercomputer.
These particular scripts are intended to run using SGE on a cluster that already has mpi compatible LAMMPS installed and accessible under the name lmp.
However, the scripts can be used as a starting template for other architectures or Queue Managment Systems like slurm or PBS.
For now, we will focus on the non ```-umbrella``` scripts.
These simpler submit scripts run only one job while the umbrella scripts submit a job array that scans over different biases.

These scripts require 4 positional arguments ```<cation>```, ```<anion>```, ```<BC>```, and ```<replica>```.
The first three are just the model parameters described above.
The last is a replica label (e.g. just a number) that creates a labeled data directory for these simulations to keep them separated from other versions potentially running in parallel with similar parameters.
After these 4 required arguments any number of additional flags can be passed in getting passed directly to LAMMPS.
Suppose we want to run replica1 of a Na Cl slab simulation at 400 K, then we would simply run the following commands in the LAMMPS directory on a cluster with SGE installed

    qsub sub-init.sh Na Cl slab 1 -v T 400
    qsub sub-run.sh Na Cl slab 1 -v T 400

We do not need to wait for the initialization script to conclude before submitting the main simulation script since ```sub-run.sh``` already includes a hold command that waits for the initialization to conclude before running.

In addition to the total equilibration + production ```sub-run.sh``` script, ```sub-eq.sh``` and ```sub-prod.sh``` scripts are provided that separately run the equilibration and production stage.
They are each set up with appropriate job hold commands that allow them to be submitted at the same time without waiting for jobs to conclude.
Usually, you will just want to use the combined ```sub-run.sh``` command.

**NB:** If you are interested in running Drude simulations, the preparation procedure described above will need to be run before submitting a ```sub-run.sh``` command to make sure the correct intermediate files are generated.

### Umbrella Sampling Job Arrays

The ```-umbrella``` scripts are analogous to their non-umbrella counterparts except they submit an array of jobs that scans through a range or grid of biases.
These scripts take the same 4 required arguments as above and can also be passed any number of arguments to the lammps script but must also contain a set of flags specifying the range of biases to be scanned before the arbitrary additional flags.
You must also pass qsub the ```-t``` flag to request a range of jobs.

The syntax for defining a scan over zBiases is as follows

    -z <a/c/id> <n> <k> <z0_init> <Delta_z0> <num_z0>

The first two arguments after the flag, ```<a/c/id> <n>``` are just the atom specifiers described above.
Then, the spring constant is specified by ```<k>```.
We must then specify the range of target values for the bias to be scanned over.
The next argument, ```<z0_init>```, defines the first target value.
The following, ```<Delta_z0>```, is the spacing of target values.
The final argument, ```<num_z0>``` is the number of values to scan over.

For example, the flag

    -z a 1 10.0 2.5 0.5 3

creates three simulations that bias the z value of the first anion with a spring constant of ```10.0``` and target ```z0```'s at ```2.5```, ```3.0``` and ```3.5```.

Very similar flags can be used for r bias scans, requiring two atom specifiers with all other syntax exactly as before 

    -r <a/c/id> <n1> <a/c/id> <n2> <k> <r0_init> <Delta_r0> <num_r0>

Multiple flags can be provided, sepcifying a grid of biases.
In this case, the scan will perform a nested loop over all combinations of target values.

In addition to specifying the flags, it is also necessary to request a range of task-ids sufficient to perform the desired portion of the scan.
The script creates a flattened array that iterates over the grid of all possible bias values.
The number of items in this array is equal to the product of all ```<num_z0>``` arguments provided.
This requires the addition of the ``` -t 1-<NBias>``` flag to the qsub command.

Putting this all together we can consider scanning a 400 K Na Cl simulation with a wall, biasing the Cl anion every 1 $\AA$ from -20 to 20 (41 total values) and the Na-Cl distance every 0.5 $\AA$ from 3.5 to 9.0 (12 total values).
This will require $41 \times 12 = 492$ tasks.
This can be submitted as follows 

    qsub sub-init.sh Na Cl wall 1 -v T 400
    qsub -t 1-492 sub-run-umbrella.sh Na Cl slab 1 -z a 1 10.0 -20 1 41 -r a 1 c 1 20.0 3.5 0.5 12 -v T 400