%% Developmental script to run all variations of the advice mechanism
%
% Three cases possible:
%   -E: Expert adviser
%   -EE: Evil expert adviser
%   -N: Novice adviser
%
% For each case the the mechanism can select its own actions (learninglabel),
% they can be overridden to all be accept (acceptlabel ), or overridden to 
% all be reject (reject label).

clear
clc
num_sims = 3;
num_runs = 100;
version = 1;

num_N_robots = 3;
evil_advice_prob = 0.1;
fake_adviser_files = {'E1'; 'E10'; 'E100'};

E_accept = false;
E_reject = false;
E_learning = true;

EE_accept = false;
EE_reject = false;
EE_learning = false;

N_accept = false;
N_reject = false;
N_learning = true;

%% Set the initial config data
% Each case will set, and unset, their params
config = Configuration();
config.advice_on = true;
config.numRobots = 1;
config.numTargets = 1;
config.a_enh_evil_advice_prob = 0;
config.a_enh_fake_advisers = false;
config.a_enh_fake_adviser_files = fake_adviser_files;
config.a_enh_all_accept = false;
config.a_enh_all_reject = false;

%% Expert All Accept
if(E_accept)
    sim_name_base = ['v', num2str(version), '_E_accept/sim_'];
    config.a_enh_fake_advisers = true;
    config.a_enh_all_accept = true;
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
    config.a_enh_fake_advisers = true;
    config.a_enh_all_accept = true;
end

%% Expert All Reject
if(E_reject)
    sim_name_base = ['v', num2str(version), '_E_reject/sim_'];
    config.a_enh_fake_advisers = true;
    config.a_enh_all_reject = true;
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
    config.a_enh_all_reject = false;
end

%% Expert Learning
if(E_learning)
    sim_name_base = ['v', num2str(version), '_E_learning/sim_'];
    config.a_enh_fake_advisers = true;
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
end

%% Evil Expert All Accept
if(EE_accept)
    sim_name_base = ['v', num2str(version), '_EE_accept/sim_'];
    config.a_enh_evil_advice_prob = evil_advice_prob;
    config.a_enh_fake_advisers = true;
    config.a_enh_all_accept = true;
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
    config.a_enh_all_accept = false;
end

%% Evil Expert All Reject
if(EE_reject)
    sim_name_base = ['v', num2str(version), '_EE_reject/sim_'];
    config.a_enh_evil_advice_prob = evil_advice_prob;
    config.a_enh_fake_advisers = true;
    config.a_enh_all_reject = true;
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
    config.a_enh_all_reject = false;
end

%% Evil Expert Learning
if(EE_learning)
    sim_name_base = ['v', num2str(version), '_EE_learning/sim_'];
    config.a_enh_evil_advice_prob = evil_advice_prob;
    config.a_enh_fake_advisers = true;
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
end

%% Novice All Accept
if(N_accept)
    sim_name_base = ['v', num2str(version), '_'];
    for i = 1:num_N_robots
        sim_name_base = [sim_name_base, 'N'];
    end
    sim_name_base = [sim_name_base, '_accept/sim_'];
    config.numRobots = num_N_robots;
    config.numTargets = num_N_robots;
    config.a_enh_all_accept = true;
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
    config.a_enh_all_accept = false;
end

%% Novice All Reject
if(N_reject)
    sim_name_base = ['v', num2str(version), '_'];
    for i = 1:num_N_robots
        sim_name_base = [sim_name_base, 'N'];
    end
    sim_name_base = [sim_name_base, '_reject/sim_'];
    config.numRobots = num_N_robots;
    config.numTargets = num_N_robots;
    config.a_enh_all_reject = true;
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
    config.a_enh_all_accept = false;
end

%% Novice Learning
if(N_learning)
    sim_name_base = ['v', num2str(version), '_'];
    for i = 1:num_N_robots
        sim_name_base = [sim_name_base, 'N'];
    end
    sim_name_base = [sim_name_base, '_learning/sim_'];
    config.numRobots = num_N_robots;
    config.numTargets = num_N_robots;
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
