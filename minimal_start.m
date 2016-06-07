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
save_data = true;
sim_name = 'test';

Simulation.consecutiveRuns(num_runs, save_data, sim_name);

%% Run consecutive simulations with X runs
num_sims = 10;
num_runs = 300;
save_data = true;
sim_name_base = 'test';

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
