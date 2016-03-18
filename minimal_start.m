% Dummy code to run RCISL

clear
clc

% Configuration ID Description
%   id=XXXXXXXX, where each digit represents a parameter/catagory
%
%   Starting from the left most position (position 1)
%   1)  Inverse Reward (1=On, 2=Off)
%   2)  Advice Exchange (1=None, 2=On, 3=Aggressive)
%   3)  Particle Filter (1=None, 2=Yes)
%   4)  Crowd Sourcing (1=Yes, 2=None)
%   5)  Coop (1=On, 2=Off, 3=Cautious)
%   6)  Team Learning (1=Q-Learning, 2=L-Alliance, 3=RSLA, 4=QAQ,
%                       5=L-Alliance-old)
%   7)  Noise Level (1=None, 2=0.05m, 3=0.1m, 4=0.2m, 5=0.4m)
%   8) Number of Robots (2=3 robots, 3=8 robots, 1=12 robots)

% Required variables
configId=21122212;  % ID code, described above
max_time=15000;    % Maximum number of iterations (seconds)
show_plot=2;    % Show the plot during the simulation (2=true)

%% Create objects required to call SimulationRun.Run

% Form configuration
config = Configuration.Instance(configId);
numRobots = config.numRobots;

% Create World state object
WorldState=worldState(configId);

% Create robotList object
robotsList = robot.empty(1,0);
for i=1:numRobots
    robotsList(i,1) = robot(i,configId);
end
    
% Create SimulationRun object
SimulationRun=SimulationRun(max_time, configId);

%% Begin simulation

milliSeconds = SimulationRun.Run(robotsList, show_plot, WorldState);
