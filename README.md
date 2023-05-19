# Ion-Pairing Simulations
Umbrella Sampling Simulations of Ion Solutions in Liquid Water

Written By: Amro Dodin (Geissler & Limmer Group - UC Berkeley & LBL)

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

## Code Structure

The code is organized as follows:

- FF: Force field parameters, drude parameters, and molecule files
    - Force Fields (```ff.\<label\>.lmp```): LAMMPS scripts containing force      field parameters. Includes pair, bonded and k-space potentials.
    - Molecule Files (```\<name\>.mol```): LAMMPS molecule files. See LAMMPS [molecule](https://docs.lammps.org/molecule.html) command for more information.
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

Example usage:

    lmp -in run.lmp -v BC electrode -v pot 0.5 -v paramfile drude_paramfile

This runs equilibration and production molecular dynamics simulations with constant potential electrodes set at 0.5 V with Drude oscillators.

**NB:** If performing Drude polarizable simulations remember to pass ```drude_paramfile``` or similar specifications. The default parameters provided in ```parameters.lmp``` are not suitable for Drude oscillator simulations.

## Running Simulations

The MD simulations proceed through 4 different stages:

1. **init:** Initialize a grid of water with ions and relax any overlaps by minimizing with a soft force field.
2. **stab:** By default, this step only runs for Drude simulations. Stabilize simulation by running a few steps with full force field and a very short timestep, resetting velocities to 0 periodically. This has been more robust than other methods for starting Drude simulations. Can be turned on by setting the variable ```nStabilizeMax``` to any integer other than ```0```.
3. **eq:** Slowly heat and then equilibrate the simulation. This is intended to be discarded and not analyzed.
4. **prod:** Production MD simulation. This is the main content of the simulation that will be analyzed.

Step 1 is contained in ```init.lmp``` while the remaining steps 2-4 are in ```run.lmp```. If desired, certain steps can be skipped by setting the ```skipProd``` and ```skipEquil``` variables to ```True``` or by setting the ```nHeat```, ```nEquil```, and ```nProd``` and ```nStabilizeMax``` variables that control the number of steps in each stage to ```0```.

**Brief Note on Biased Simulation:** Umbrella sampling biases (if being used) are applied starting in the stabilization step all the way through the production. As a result, each bias window will generally start production in a different initial condition that has already equilibrated to the bias. Note that slab simulations with a liquid vapor interfaces include a center of mass constraint on all particles that are not otherwised biased by default. This standard constraint stops the water slab center of mass from flying around the simulation and does not affect any other applied biases.


### Drude Oscillator Set-Up

### Umbrella Sampling Biases

## Submit Scripts

### Umbrella Sampling Job Arrays
