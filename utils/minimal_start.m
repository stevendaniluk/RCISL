% Simple script for starting a simulation
%
% This is intended to be an example for how to perform simulations.
%
% The ExecutiveSimulation object carries out the actual simulation, and
% requires a Configuration object to define all the necessary parameters.
% The simulation runs are performed through calling the consecutiveRuns 
% method. Data for each simulation is saved inside the "results" directory.

% Parameters
num_sims = 2;            % Number of times to repeat the simulation
num_runs = 100;          % Number fo consecutive runs to perform
sim_name_base = 'test';  % Folder to save simulation data in
sim_start_num = 1;       % Index to start numbering simulations

for i = sim_start_num:(sim_start_num + num_sims - 1)
  % Form configuration
  config = Configuration();
  
  % Create simulation object and initialize
  Simulation = ExecutiveSimulation(config);
  Simulation.initialize();
  
  % Form sim name
  sim_name = fullfile(sim_name_base, sprintf('sim_%d', i));
  
  % Make runs
  Simulation.consecutiveRuns(num_runs, sim_name);
end
