% Expert Data Generator
%
% Script for running sims with a single agent and storing it's Q 
% tables to be used for simulating an expert agent, or using 
% virtual advisers with advice.

% Set number of epochs to train each expert
experts = [1, 2, 5, 10, 50, 100, 1000];

% Load and set the config
config = Configuration();
config.sim.show_live_graphics = false;
config.sim.save_simulation_data = true;
config.sim.save_IL_data = true;
config.sim.save_advice_data = false;
config.advice.enabled = false;
config.scenario.num_robots = 1;
config.scenario.num_targets = 1;

if ~exist('expert_data', 'dir')
  mkdir('expert_data');
end

for i = 1:length(experts)
  % Create simulation object and initialize
  Simulation = ExecutiveSimulation(config);
  Simulation.initialize();
  % Form sim name
  sim_name = sprintf('expert_data_generation/E%d', experts(i));
  % Make runs
  Simulation.consecutiveRuns(experts(i), sim_name);
  
  % Make the folder
  if ~exist(fullfile('expert_data', sprintf('E%d', experts(i))), 'dir')
    mkdir(fullfile('expert_data', sprintf('E%d', experts(i))));
  end
  
  % Save the data (copy from data saved by the sim)
  load(fullfile('results', 'expert_data_generation', sprintf('E%d', experts(i)), 'individual_learning_data.mat'));
  q_table = individual_learning_data{1}.q_table;
  exp_table = individual_learning_data{1}.exp_table;
  save(fullfile('expert_data', sprintf('E%d', experts(i)), 'q_table'), 'q_table');
  save(fullfile('expert_data', sprintf('E%d', experts(i)), 'exp_table'), 'exp_table');
end
