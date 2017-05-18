# utils
The utils directory contains a collection of script for running simulations and analyzing data.

#### DataProcessor:
A helper class for loading and plotting data. Has functionality for loading data from multiple simulations, averaging the results over all simulations, and plotting a variety of metrics.

#### advice_experiments_plotter:
Generates plots for the set of 5 experiments used to test the Preference Advice mechanism.

#### expert_data_generator:
Will run a series of single robot simulations for the defined robot types and number of runs, and will save the robot’s policy (i.e. the Q-table and experience table) in the expert_data directory.

#### minimal_start
Simple example script for running a simulation.

#### mission_perf_plotter
Generates plots for simulation time and average reward for the team.

#### reference_data_generator
Runs a series of simulations with the defined number of robots and types. Used for generating reference data to be compared against other simulation variations (e.g. with advice vs without advice)

#### run_advice_experiments
Performs the 5 experiments used for testing the Preference Advice mechanism.