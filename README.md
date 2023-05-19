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



### Drude Oscillator Set-Up

### Umbrella Sampling Biases

## Submit Scripts

### Umbrella Sampling Job Arrays
