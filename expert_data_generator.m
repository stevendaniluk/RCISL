% Expert Data Generator
%
% Script for running sims with a single agent and storing it's Q 
% tables to be used for simulating an expert agent, or using 
% virtual advisers with advice.

% Set number of epochs to train each expert
experts = [1, 10, 100, 1000];

% Place all expert data in a sub folder (empty string for no sub folder)
sub_folder = 'S-NR';

% Load and set the config
config = Configuration();
config.sim.show_live_graphics = false;
config.sim.save_simulation_data = false;
config.sim.save_IL_data = false;
config.sim.save_advice_data = false;
config.advice.enabled = false;
config.scenario.num_robots = 1;
config.scenario.num_targets = 1;
config.scenario.robot_types = [1, 1, 1, 1];

if ~exist('expert_data', 'dir')
  mkdir('expert_data');
end

for i = 1:length(experts)
  % Create simulation object and initialize
  clear Simulation;
  Simulation = ExecutiveSimulation(config);
  Simulation.initialize();
  % Form sim name
  sim_name = sprintf('expert_data_generation/E%d', experts(i));
  % Make runs
  Simulation.consecutiveRuns(experts(i), sim_name);
  
  if(isempty(sub_folder))
    out_path = fullfile('expert_data', sprintf('E%d', experts(i)));
  else
    out_path = fullfile('expert_data', sub_folder, sprintf('E%d', experts(i)));
  end
  
  % Make the folder
  if ~exist(out_path, 'dir')
    mkdir(out_path);
  end
  
  % Save the data (copy from data saved by the sim)
  q_table = Simulation.robots_.individual_learning_.q_learning_.q_table_;
  exp_table = Simulation.robots_.individual_learning_.q_learning_.exp_table_;
  save(fullfile(out_path, 'q_table'), 'q_table');
  save(fullfile(out_path, 'exp_table'), 'exp_table');
end
