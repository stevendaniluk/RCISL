% Reference Data Generator
%
% Script for running sims with a set number of agents, and
% their performance data. To be used as reference data when
% evaluating algorithm improvements.

% Settings
num_robots = [1, 2, 4, 8];  % Number of robots for each case
robot_types = [1, 1, 1, 1]; % Types of robots to use
label = 'S-NR';             % Label to append to name (e.g. "S-NR"
num_runs = 200;             % Number of runs for each sim
num_sims = 10;              % Number simulations to perform

% Load and set the config
config = Configuration();
config.sim.show_live_graphics = false;
config.sim.save_simulation_data = true;
config.sim.save_IL_data = false;
config.sim.save_advice_data = false;
config.advice.enabled = false;
config.scenario.robot_types = robot_types;

ref_dir = fullfile('results', 'ref');
if ~exist(ref_dir, 'dir')
  mkdir(ref_dir);
end

for i = 1:length(num_robots)
  % Set the number of robots and targets
  config.scenario.num_robots = num_robots(i);
  config.scenario.num_targets = num_robots(i);
  
  % Make sure there is a folder to save to
  set_name = sprintf('%dN-%s', num_robots(i), label);
  set_dir = fullfile(ref_dir, set_name);
  if ~exist(set_dir, 'dir')
    mkdir(set_dir);
  end
  
  parfor j = 1:num_sims
    % Create simulation object and initialize
    Simulation = ExecutiveSimulation(config);
    Simulation.initialize();
    % Form sim name
    sim_name = fullfile('ref', set_name, sprintf('sim_%d', j));
    % Make runs
    Simulation.consecutiveRuns(num_runs, sim_name);
  end
end
