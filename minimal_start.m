% Dummy code to run RCISL

clear
clc

%% Create and initialize the simulation

% % Form configuration
config = Configuration();
    
% Create simulation object 
Simulation=ExecutiveSimulation(config);

%% Make single run

% Initialize
Simulation.initialize();

tic
Simulation.run();
disp('Mission Complete.')
disp(['Number of iterations: ',num2str(Simulation.world_state_.iterations)])
toc

%% Make consecutive runs
% num_runs = 2;
% save_data = true;
% sim_name = 'test_1';
% 
% Simulation.consecutiveRuns(config, num_runs, save_data, sim_name);
