% Dummy code to run RCISL

clear
clc

%% Create and initialize the simulation

% % Form configuration
config = Configuration();
    
% Create simulation object 
Simulation=ExecutiveSimulation(config);

% Initialize
Simulation.initialize();

% Option to load utility tables
%Simulation.loadLearningData();

%% Make single run

tic
Simulation.run();
disp('Mission Complete.')
disp(['Number of iterations: ',num2str(Simulation.world_state_.iterations_)])
toc

%% Make consecutive runs
num_runs = 50;
save_data = false;
sim_name = 'test';

Simulation.consecutiveRuns(num_runs, save_data, sim_name);

%% Run consecutive simulations with X runs
num_sims = 1;
num_runs = 150;
save_data = true;
sim_name_base = 'test_v2_320_advisor/sim_';

for i=1:num_sims    
    % Form configuration
    config = Configuration();
    % Create simulation object
    Simulation=ExecutiveSimulation(config);
    % Initialize
    Simulation.initialize();
    
    % Form sim name
    sim_name = [sim_name_base, sprintf('%d', i)];
    
    % Make runs
    Simulation.consecutiveRuns(num_runs, save_data, sim_name);
end

%% Consecutive simulations with different config settings
num_sims = 20;
num_runs = 150;
save_data = true;
config = Configuration();
config.a_dev_evil_advisor = false;

config.a_dev_expert_filename = 'advisor_5_epochs';
sim_name_base = 'a_dev_v2_5_advisor/sim_';
for i=1:num_sims    
    % Create simulation object
    Simulation=ExecutiveSimulation(config);
    % Initialize
    Simulation.initialize();
    % Form sim name
    sim_name = [sim_name_base, sprintf('%d', i)];
    % Make runs
    Simulation.consecutiveRuns(num_runs, save_data, sim_name);
end

config.a_dev_expert_filename = 'advisor_10_epochs';
sim_name_base = 'a_dev_v2_10_advisor/sim_';
for i=1:num_sims    
    % Create simulation object
    Simulation=ExecutiveSimulation(config);
    % Initialize
    Simulation.initialize();
    % Form sim name
    sim_name = [sim_name_base, sprintf('%d', i)];
    % Make runs
    Simulation.consecutiveRuns(num_runs, save_data, sim_name);
end

config.a_dev_expert_filename = 'advisor_20_epochs';
sim_name_base = 'a_dev_v2_20_advisor/sim_';
for i=1:num_sims    
    % Create simulation object
    Simulation=ExecutiveSimulation(config);
    % Initialize
    Simulation.initialize();
    % Form sim name
    sim_name = [sim_name_base, sprintf('%d', i)];
    % Make runs
    Simulation.consecutiveRuns(num_runs, save_data, sim_name);
end

config.a_dev_expert_filename = 'advisor_40_epochs';
sim_name_base = 'a_dev_v2_40_advisor/sim_';
for i=1:num_sims    
    % Create simulation object
    Simulation=ExecutiveSimulation(config);
    % Initialize
    Simulation.initialize();
    % Form sim name
    sim_name = [sim_name_base, sprintf('%d', i)];
    % Make runs
    Simulation.consecutiveRuns(num_runs, save_data, sim_name);
end

config.a_dev_expert_filename = 'advisor_80_epochs';
sim_name_base = 'a_dev_v2_80_advisor/sim_';
for i=1:num_sims    
    % Create simulation object
    Simulation=ExecutiveSimulation(config);
    % Initialize
    Simulation.initialize();
    % Form sim name
    sim_name = [sim_name_base, sprintf('%d', i)];
    % Make runs
    Simulation.consecutiveRuns(num_runs, save_data, sim_name);
end

config.a_dev_expert_filename = 'advisor_160_epochs';
sim_name_base = 'a_dev_v2_160_advisor/sim_';
for i=1:num_sims    
    % Create simulation object
    Simulation=ExecutiveSimulation(config);
    % Initialize
    Simulation.initialize();
    % Form sim name
    sim_name = [sim_name_base, sprintf('%d', i)];
    % Make runs
    Simulation.consecutiveRuns(num_runs, save_data, sim_name);
end

config.a_dev_expert_filename = 'advisor_320_epochs';
sim_name_base = 'a_dev_v2_320_advisor/sim_';
for i=1:num_sims    
    % Create simulation object
    Simulation=ExecutiveSimulation(config);
    % Initialize
    Simulation.initialize();
    % Form sim name
    sim_name = [sim_name_base, sprintf('%d', i)];
    % Make runs
    Simulation.consecutiveRuns(num_runs, save_data, sim_name);
end

config.a_dev_expert_filename = 'advisor_320_epochs';
config.a_dev_evil_advisor = true;
sim_name_base = 'a_dev_v2_320_advisor_evil/sim_';
for i=1:num_sims    
    % Create simulation object
    Simulation=ExecutiveSimulation(config);
    % Initialize
    Simulation.initialize();
    % Form sim name
    sim_name = [sim_name_base, sprintf('%d', i)];
    % Make runs
    Simulation.consecutiveRuns(num_runs, save_data, sim_name);
end



