%% Run consecutive simulations
clear
clc

num_sims = 5;
num_runs = 50;
sim_name_base = 'test/sim_';

for i=1:num_sims
  % Form configuration
  config = Configuration();
  % Create simulation object and initialize
  Simulation = ExecutiveSimulation(config);
  Simulation.initialize();
  
  % Form sim name
  sim_name = [sim_name_base, sprintf('%d', i)];
  
  % Make runs
  Simulation.consecutiveRuns(num_runs, sim_name);
end
