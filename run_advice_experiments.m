%% Script for running all advice mechanism experiments
%
% Experiment 1: Not require advisers with full knowledge of the task
%   Setup:
%     - 8 novice agents learning together
%     - Compare team performance with advice to without advice
%   Metrics:
%     - Team iterations
%     - Team total reward
%
% Experiment 2: Distinguish between good and bad advice at each instant
%   Setup:
%     - One novice agent
%     - One expert adviser (of the same type) that provides evil advice with probability e
%   Metrics:
%     - Acceptance and rejection ratios for the advisers advice
%         - Benevolent advice vs. evil advice
%
% Experiment 3: Compatible with advisers of varying skill level and similarity
%   Setup:
%     - Part a) Varying skill
%         - One novice S-NR
%         - S-NR experts trained for 5, 20, 80, and 320 epochs
%     - Part b) Varying similarity
%         - One novice S-NR 
%         - One expert of each type (S-NR, S-R, F-NR, F-R)
%   Metrics:
%     - Adviser acceptance rates
%
% Experiment 4: Jumpstart novices with a single expert
%   Setup:
%     - 8 novices 
%     - Novices have access to each other for advice, plus one fake expert 
%       trained for X epochs
%     - For each expert a seperate test is be performed (labeled a, b, etc.)
%   Metrics:
%     - Team iterations
%     - Team total reward

clear
clc
num_sims = 10;
num_runs = 100;
version = 1;

exp1 = false;
exp1_settings.num_robots = 8;

exp2 = false;
exp2_settings.evil_advice_prob = 0.2;
exp2_settings.fake_adviser_files = {'E640'};

exp3a = false;
exp3a_settings.fake_adviser_files = {'E1'; 'E10'; 'E100'; 'E640'};

exp4 = true;
exp4_settings.num_robots = 8;
exp4_settings.fake_adviser_files = {'E10'; 'E100'};

%% Set the initial config data
% Each case will set, and unset, their params
config = Configuration();
config.advice_on = true;
config.numRobots = 1;
config.numTargets = 1;
config.a_enh_evil_advice_prob = 0;
config.a_enh_fake_advisers = false;
config.a_enh_fake_adviser_files = [];
config.a_enh_all_accept = false;
config.a_enh_all_reject = false;

%% Experiment 1
if(exp1)
    sim_name_base = ['v', num2str(version), '_experiment_1/sim_'];
    config.numRobots = exp1_settings.num_robots;
	config.numTargets = exp1_settings.num_robots;
    for i=1:num_sims        
        % Create simulation object
        Simulation=ExecutiveSimulation(config);
        % Initialize
        Simulation.initialize();
        
        % Form sim name
        sim_name = [sim_name_base, sprintf('%d', i)];
        
        % Make runs
        Simulation.consecutiveRuns(num_runs, true, sim_name);
    end
    config.numRobots = 1;
	config.numTargets = 1;
end

%% Experiment 2
if(exp2)
    sim_name_base = ['v', num2str(version), '_experiment_2/sim_'];
	config.a_enh_evil_advice_prob = exp2_settings.evil_advice_prob;
    config.a_enh_fake_advisers = true;
    config.a_enh_fake_adviser_files = exp2_settings.fake_adviser_files;
    for i=1:num_sims
        % Create simulation object
        Simulation=ExecutiveSimulation(config);
        % Initialize
        Simulation.initialize();
        
        % Form sim name
        sim_name = [sim_name_base, sprintf('%d', i)];
        
        % Make runs
        Simulation.consecutiveRuns(num_runs, true, sim_name);
    end
	config.a_enh_evil_advice_prob = 0;
    config.a_enh_fake_advisers = false;
    config.a_enh_fake_adviser_files = [];
end

%% Experiment 3a
if(exp3a)
    sim_name_base = ['v', num2str(version), '_experiment_3a/sim_'];
    config.a_enh_fake_advisers = true;
    config.a_enh_fake_adviser_files = exp3a_settings.fake_adviser_files;
    for i=1:num_sims
        % Create simulation object
        Simulation=ExecutiveSimulation(config);
        % Initialize
        Simulation.initialize();
        
        % Form sim name
        sim_name = [sim_name_base, sprintf('%d', i)];
        
        % Make runs
        Simulation.consecutiveRuns(num_runs, true, sim_name);
    end
    config.a_enh_fake_advisers = false;
    config.a_enh_fake_adviser_files = [];
end

%% Experiment 4
if(exp4)
    config.numRobots = exp4_settings.num_robots;
	config.numTargets = exp4_settings.num_robots;
    config.a_enh_fake_advisers = true;
    for j = 1:length(exp4_settings.fake_adviser_files);
        % Append a, b, c, etc. to the name using the decimal value
        sim_name_base = ['v', num2str(version), '_experiment_4', char(96 + j), '/sim_'];
        config.a_enh_fake_adviser_files = exp4_settings.fake_adviser_files(j);
        for i=1:num_sims
            % Create simulation object
            Simulation=ExecutiveSimulation(config);
            % Initialize
            Simulation.initialize();
            
            % Form sim name
            sim_name = [sim_name_base, sprintf('%d', i)];
            
            % Make runs
            Simulation.consecutiveRuns(num_runs, true, sim_name);
        end
        
    end
    config.numRobots = 1;
	config.numTargets = 1;
    config.a_enh_fake_advisers = false;
    config.a_enh_fake_adviser_files = [];
end
