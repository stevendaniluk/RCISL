% Expert Data Generator
%
% Script for running sims with a single agent and storing it's Q
% tables to be used for simulating an expert agent, or using
% virtual advisers with advice.

% Set number of epochs to train each expert
types = [1, 2, 3, 4];
type_names = {'S-NR', 'F-NR', 'S-R', 'F-R'};  % Place all expert data in a sub folder (empty string for no sub folder)
experts = [1, 10, 100, 1000];

% Load and set the config
config = Configuration();
config.sim.show_live_graphics = false;
config.sim.save_simulation_data = false;
config.sim.save_IL_data = false;
config.sim.save_advice_data = false;
config.advice.enabled = false;
config.scenario.num_robots = 1;
config.scenario.num_targets = 1;

if ~exist('expert_data', 'dir')
  mkdir('expert_data');
end

for j = 1:max(1, length(type_names))
  config.scenario.robot_types = types(j);
  
  for i = 1:length(experts)
    % Create simulation object and initialize
    Simulation = ExecutiveSimulation(config);
    Simulation.initialize();
    % Form sim name
    sim_name = sprintf('expert_data_generation/E%d', experts(i));
    % Make runs
    Simulation.consecutiveRuns(experts(i), sim_name);
    
    if(isempty(type_names))
      out_path = fullfile('expert_data', sprintf('E%d', experts(i)));
    else
      out_path = fullfile('expert_data', type_names{j}, sprintf('E%d', experts(i)));
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
end
