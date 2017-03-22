%% Script for running all advice mechanism experiments
%
% Experiment 1: Use peers as advisers
%   Setup:
%     - 8 novice agents learning together
%     - Compare team performance with advice to without advice
%
% Experiment 2: Randomly subject an agent to bad advice
%   Setup:
%     - One novice agent
%     - One expert adviser (of the same type) that provides evil advice 
%       with probability e
%
% Experiment 3: Use advisers of varying skill level and similarity
%   Setup:
%     - Part a) Varying skill
%         - One novice S-NR
%         - S-NR experts trained for 10, 100, and 1000 epochs
%     - Part b) Varying similarity
%         - One novice S-NR
%         - One expert of each type (S-NR, S-R, F-NR, F-R)
%
% Experiment 4: Supplement a team of novices with an additional partially trained adviser
%   Setup:
%     - 8 novices
%     - Novices have access to each other for advice, plus one fake expert
%       trained for either 10, 100, or 1000 epochs
%     - For each expert a seperate test is be performed (labeled 1, 2, etc.)

clear
clc
num_sims = 10;
num_runs = 200;
version = 1;

% Flags and settings for each experiment:
exp1 = false;
exp1_settings.num_robots = 8;

exp2 = false;
exp2_settings.evil_advice_prob = 0.2;
exp2_settings.fake_adviser_files = {'E1000'};

exp3a = false;
exp3a_settings.fake_adviser_files = {'E1000', 'E100', 'E10'};

exp4 = false;
exp4_settings.num_robots = 8;
exp4_settings.fake_adviser_files = {'E1000', 'E100', 'E10'};

%% Set the initial config data
% Each case will set, and unset, their params
config = Configuration();
config.sim.show_live_graphics = false;
config.sim.save_simulation_data = true;
config.sim.save_IL_data = false;
config.sim.save_advice_data = true;
config.advice.enabled = true;
config.scenario.num_robots = 1;
config.scenario.num_targets = 1;
config.advice.evil_advice_prob = 0;
config.advice.fake_advisers = false;
config.advice.fake_adviser_files = [];

%% Experiment 1
if(exp1)
  sim_name_base = ['v', num2str(version), '_experiment_1/sim_'];
  config.scenario.num_robots = exp1_settings.num_robots;
  config.scenario.num_targets = exp1_settings.num_robots;
  for i=1:num_sims
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
end

%% Experiment 2
if(exp2)
  sim_name_base = ['v', num2str(version), '_experiment_2/sim_'];
  config.advice.evil_advice_prob = exp2_settings.evil_advice_prob;
  config.advice.fake_advisers = true;
  config.advice.fake_adviser_files = exp2_settings.fake_adviser_files;
  for i=1:num_sims
    % Create simulation object
    Simulation=ExecutiveSimulation(config);
    % Initialize
    Simulation.initialize();
    
    % Form sim name
    sim_name = [sim_name_base, sprintf('%d', i)];
    
    % Make runs
    Simulation.consecutiveRuns(num_runs, sim_name);
  end
  config.advice.evil_advice_prob = 0;
  config.advice.fake_advisers = false;
  config.advice.fake_adviser_files = [];
end

%% Experiment 3a
if(exp3a)
  sim_name_base = ['v', num2str(version), '_experiment_3a/sim_'];
  config.advice.fake_advisers = true;
  config.advice.fake_adviser_files = exp3a_settings.fake_adviser_files;
  for i=1:num_sims
    % Create simulation object
    Simulation=ExecutiveSimulation(config);
    % Initialize
    Simulation.initialize();
    
    % Form sim name
    sim_name = [sim_name_base, sprintf('%d', i)];
    
    % Make runs
    Simulation.consecutiveRuns(num_runs, sim_name);
  end
  config.advice.fake_advisers = false;
  config.advice.fake_adviser_files = [];
end

%% Experiment 4
if(exp4)
  config.scenario.num_robots = exp4_settings.num_robots;
  config.scenario.num_targets = exp4_settings.num_robots;
  config.advice.fake_advisers = true;
  for j = 1:length(exp4_settings.fake_adviser_files);
    % Append 1, 2, 3, etc. to the name
    sim_name_base = sprintf('v%d_experiment_4_%d/sim_', version, j);
    config.advice.fake_adviser_files = exp4_settings.fake_adviser_files(j);
    for i=1:num_sims
      % Create simulation object
      Simulation=ExecutiveSimulation(config);
      % Initialize
      Simulation.initialize();
      
      % Form sim name
      sim_name = [sim_name_base, sprintf('%d', i)];
      
      % Make runs
      Simulation.consecutiveRuns(num_runs, sim_name);
    end
    
  end
  config.scenario.num_robots = 1;
  config.scenario.num_targets = 1;
  config.advice.fake_advisers = false;
  config.advice.fake_adviser_files = [];
end
