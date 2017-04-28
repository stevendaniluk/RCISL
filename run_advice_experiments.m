%% Script for running all advice mechanism experiments
%
% Experiment 1: Homogeneous peers as advisers
%   Setup:
%     - 4 novice S-NR robots
%
% Experiment 2: Heterogeneous peers as advisers
%   Setup:
%     - 1 robots of each type (S-NR, F-NR, S-R, F-R)
%
% Experiment 3: Expert advisers of varying skill level
%   Setup:
%     - 1 novice S-NR robot, 
%     - Virtual expert advisers trained for 10, 100, 1000 epochs
%
% Experiment 4: Expert advisers of varying capabilities
%   Setup:
%     - 1 novice S-R robot, 
%     - Virtual expert S-NR, F-NR, S-R, and F-R advisers trained for 1000 epochs
%
% Experiment 5: Supplement a team of novices with an expert adviser
%   Setup:
%     - 4 novice S-NR robots
%     - Novices have access to peers for advice, plus one virtual expert
%       adviser trained for either 10, 100, or 1000 epochs
%     - For each expert a seperate test is be performed (labeled 1, 2, etc.)

clear
clc
num_sims = 10;
num_runs = 200;
version = 1;

% Flags and settings for each experiment:
exp1 = false;
exp1_settings.num_robots = 4;
exp1_settings.robot_types = [1, 1, 1, 1];

exp2 = false;
exp2_settings.num_robots = 4;
exp2_settings.robot_types = [1, 2, 3, 4];

exp3 = false;
exp3_settings.robot_types = 3;
exp3_settings.fake_adviser_files = {'S-R/E100', 'S-R/E100', 'S-R/E10'};

exp4 = false;
exp4_settings.robot_types = 3;
exp4_settings.fake_adviser_files = {'S-NR/E100', 'F-NR/E100', 'S-R/E100', 'F-R/E100'};

exp5 = false;
exp5_settings.num_robots = 4;
exp5_settings.robot_types = [1, 1, 1, 1];
exp5_settings.fake_adviser_files = {'S-NR/E100', 'S-NR/E10', 'S-NR/E1'};
exp5_settings.sim_labels = {'E100', 'E10', 'E1'};

%% Set the initial config data
% Each case will set, and unset, their params
config = Configuration();
config.sim.show_live_graphics = false;
config.sim.save_simulation_data = true;
config.sim.save_IL_data = false;
config.sim.save_advice_data = true;
config.advice.enabled = true;
config.advice.mechanism = 'advice_enhancement';
config.scenario.num_robots = 1;
config.scenario.num_targets = 1;
config.scenario.robot_types = [1, 1, 1, 1];
config.advice.evil_advice_prob = 0;
config.advice.fake_advisers = false;
config.advice.fake_adviser_files = [];

%% Experiment 1
if(exp1)
  sim_name_base = ['v', num2str(version), '_experiment_1/sim_'];
  config.scenario.num_robots = exp1_settings.num_robots;
  config.scenario.num_targets = exp1_settings.num_robots;
  config.scenario.robot_types = exp1_settings.robot_types;
  parfor i=1:num_sims
    % Create simulation object
    Simulation=ExecutiveSimulation(config);
    % Initialize
    Simulation.initialize();
    
    % Form sim name
    sim_name = [sim_name_base, sprintf('%d', i)];
    
    % Make runs
    Simulation.consecutiveRuns(num_runs, sim_name);
  end
  config.scenario.num_robots = 1;
  config.scenario.num_targets = 1;
  config.scenario.robot_types = [1, 1, 1, 1];
end

%% Experiment 2
if(exp2)
  sim_name_base = ['v', num2str(version), '_experiment_2/sim_'];
  config.scenario.num_robots = exp2_settings.num_robots;
  config.scenario.num_targets = exp2_settings.num_robots;
  config.scenario.robot_types = exp2_settings.robot_types;
  
  parfor i=1:num_sims
    Simulation=ExecutiveSimulation(config);
    Simulation.initialize();
    sim_name = [sim_name_base, sprintf('%d', i)];
    Simulation.consecutiveRuns(num_runs, sim_name);
  end
  
  config.scenario.num_robots = 1;
  config.scenario.num_targets = 1;
  config.scenario.robot_types = [1, 1, 1, 1];
end

%% Experiment 3
if(exp3)
  sim_name_base = ['v', num2str(version), '_experiment_3/sim_'];
  config.scenario.robot_types = exp3_settings.robot_types;
  config.advice.fake_advisers = true;
  config.advice.fake_adviser_files = exp3_settings.fake_adviser_files;
  
  parfor i=1:num_sims
    Simulation=ExecutiveSimulation(config);
    Simulation.initialize();
    sim_name = [sim_name_base, sprintf('%d', i)];
    Simulation.consecutiveRuns(num_runs, sim_name);
  end
  
  config.scenario.robot_types = [1, 1, 1, 1];
  config.advice.fake_advisers = false;
  config.advice.fake_adviser_files = [];
end

%% Experiment 4
if(exp4)
  sim_name_base = ['v', num2str(version), '_experiment_4/sim_'];
  config.scenario.robot_types = exp4_settings.robot_types;
  config.advice.fake_advisers = true;
  config.advice.fake_adviser_files = exp4_settings.fake_adviser_files;
  
  parfor i=1:num_sims
    Simulation=ExecutiveSimulation(config);
    Simulation.initialize();
    sim_name = [sim_name_base, sprintf('%d', i)];
    Simulation.consecutiveRuns(num_runs, sim_name);
  end
  
  config.scenario.robot_types = [1, 1, 1, 1];
  config.advice.fake_advisers = false;
  config.advice.fake_adviser_files = [];
end

%% Experiment 5
if(exp5)
  config.scenario.num_robots = exp5_settings.num_robots;
  config.scenario.num_targets = exp5_settings.num_robots;
  config.scenario.robot_types = exp5_settings.robot_types;
  config.advice.fake_advisers = true;
  for j = 1:length(exp5_settings.fake_adviser_files);
    % Append label to the name
    sim_name_base = sprintf('v%d_experiment_5_%s/sim_', version, exp5_settings.sim_labels{j});
    config.advice.fake_adviser_files = exp5_settings.fake_adviser_files(j);
    
    parfor i=1:num_sims
      Simulation=ExecutiveSimulation(config);
      Simulation.initialize();
      sim_name = [sim_name_base, sprintf('%d', i)];
      Simulation.consecutiveRuns(num_runs, sim_name);
    end
    
  end
  config.scenario.num_robots = 1;
  config.scenario.num_targets = 1;
  config.scenario.robot_types = [1, 1, 1, 1];
  config.advice.fake_advisers = false;
  config.advice.fake_adviser_files = [];
end
