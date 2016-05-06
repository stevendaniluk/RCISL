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

%% Make single run

tic
Simulation.run();
disp('Mission Complete.')
disp(['Number of iterations: ',num2str(Simulation.world_state_.iterations)])
toc

%% Make consecutive runs
num_runs = 50;
save_data = true;
sim_name = 'test';

% Option to load utility tables
%Simulation.loadUtilityTables();

Simulation.consecutiveRuns(num_runs, save_data, sim_name);
