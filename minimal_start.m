% Dummy code to run RCISL

clear all
clc

%% Create objects required to call SimulationRun.Run

show_plot=2;    % Show the plot during the simulation (2=true)

% Form configuration
config = Configuration();

% Create World state object
WorldState=worldState(config);

% Create robotList object
robotsList = robot.empty(1,0);
for i=1:config.numRobots;
    robotsList(i,1) = robot(i,config);
end
    
% Create SimulationRun object
SimulationRun=SimulationRun(config);

%% Begin simulation
tic
iterations = SimulationRun.Run(robotsList, show_plot, WorldState);
disp('Mission Complete.')
disp(['Number of iterations: ',num2str(iterations)])
toc
