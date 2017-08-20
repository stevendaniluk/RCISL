%% Script for running all RCISL advice experiments
%
% 4 robots are used for each test (Slow-Weak, Slow-Strong,
% (Fast-Weak, and Fast-Strong).
%
% Simulations are run with, and without advice for the following cases:
%   -No noise
%   -Noise with 0.05m, 0.20m, and 0.40m standard deviation
%   -Noise with 0.05m, 0.20m, and 0.40m standard deviations and a particle
%    filter for state estimation

% General sim Parameters
test_name = 'test';
num_sims = 10;          % Number of times to repeat the simulation
num_runs = 200;         % Number of consecutive runs to perform
sim_start_num = 1;      % Index to start numbering simulations
noise_levels = [0.05, 0.20, 0.40];

% Which tests to run
test.no_noise = false;
test.advice_no_noise = false;
test.noise = false;
test.advice_noise = true;
test.noise_pf = false;
test.advice_noise_pf = false;

% Form default configuration
base_config = Configuration();
base_config.sim.save_simulation_data = true;
base_config.sim.save_advice_data = true;
base_config.sim.show_live_graphics = false;
base_config.scenario.terrain_on = false;
base_config.scenario.max_iterations = 6000;
base_config.scenario.num_robots = 4;
base_config.scenario.num_targets = 4;
base_config.scenario.robot_types = [1, 5, 2, 6];
base_config.scenario.target_types = {'light', 'heavy', 'light', 'heavy'};

base_config.noise.enabled = false;
base_config.noise.sigma_rot = 0.0;
base_config.noise.PF.enabled = false;
base_config.noise.PF.num_particles = 100;
base_config.noise.PF.resample_percent = 0.75;
base_config.noise.PF.random_percentage = 0.10;
base_config.noise.PF.random_sigma = 1.0;

base_config.noise.PF.sigma_control_lin = 0.01;
base_config.noise.PF.sigma_control_ang = 0.0;
base_config.noise.PF.sigma_meas = 0.5; 

base_config.TL.task_allocation = 'l_alliance';
base_config.TL.LA.max_task_time = 1500;

base_config.advice.enabled = false;
base_config.advice.accept_bias = 4.0;

%% No noise, no advice
if(test.no_noise)
  sim_name_base = sprintf('%s_no_noise', test_name);
  config = base_config;
  parfor i = sim_start_num:(sim_start_num + num_sims - 1)
    % Create simulation object, initialize, and run
    Simulation = ExecutiveSimulation(config);
    Simulation.initialize();
    sim_name = fullfile(sim_name_base, sprintf('sim_%d', i));
    Simulation.consecutiveRuns(num_runs, sim_name);
  end
end

%% No noise, with advice
if(test.advice_no_noise)
  sim_name_base = sprintf('%s_advice_no_noise', test_name);
  config = base_config;
  config.advice.enabled = true;
  parfor i = sim_start_num:(sim_start_num + num_sims - 1)
    % Create simulation object, initialize, and run
    Simulation = ExecutiveSimulation(config);
    Simulation.initialize();
    sim_name = fullfile(sim_name_base, sprintf('sim_%d', i));
    Simulation.consecutiveRuns(num_runs, sim_name);
  end
end

%% Noise with each noise level, no advice
if(test.noise)
  for noise_index = 1:length(noise_levels)
    sim_name_base = sprintf('%s_noise_%.2f', test_name, noise_levels(noise_index));
    config = base_config;
    config.noise.enabled = true;
    config.noise.sigma_trans = noise_levels(noise_index);
    config.noise.PF.sigma_meas = noise_levels(noise_index);
    config.noise.PF.sigma_initial = noise_levels(noise_index);
    
    parfor i = sim_start_num:(sim_start_num + num_sims - 1)
      % Create simulation object, initialize, and run
      Simulation = ExecutiveSimulation(config);
      Simulation.initialize();
      sim_name = fullfile(sim_name_base, sprintf('sim_%d', i));
      Simulation.consecutiveRuns(num_runs, sim_name);
    end
    
  end
end

%% Noise with each noise level, with advice
if(test.advice_noise)
  for noise_index = 1:length(noise_levels)
    sim_name_base = sprintf('%s_advice_noise_%.2f', test_name, noise_levels(noise_index));
    config = base_config;
    config.advice.enabled = true;
    config.noise.enabled = true;
    config.noise.sigma_trans = noise_levels(noise_index);
    config.noise.PF.sigma_meas = noise_levels(noise_index);
    config.noise.PF.sigma_initial = noise_levels(noise_index);
    
    parfor i = sim_start_num:(sim_start_num + num_sims - 1)
      % Create simulation object, initialize, and run
      Simulation = ExecutiveSimulation(config);
      Simulation.initialize();
      sim_name = fullfile(sim_name_base, sprintf('sim_%d', i));
      Simulation.consecutiveRuns(num_runs, sim_name);
    end
    
  end
end
  
%% Noise with each noise level and a particle filter, no advice
if(test.noise_pf)
  for noise_index = 1:length(noise_levels)
    sim_name_base = sprintf('%s_noise_%.2f_pf', test_name, noise_levels(noise_index));
    config = base_config;
    config.noise.enabled = true;
    config.noise.sigma_trans = noise_levels(noise_index);
    config.noise.PF.sigma_meas = noise_levels(noise_index);
    config.noise.PF.sigma_initial = noise_levels(noise_index);
    config.noise.PF.random_sigma = 2*noise_levels(noise_index);
    config.noise.PF.enabled = true;
    
    parfor i = sim_start_num:(sim_start_num + num_sims - 1)
      % Create simulation object, initialize, and run
      Simulation = ExecutiveSimulation(config);
      Simulation.initialize();
      sim_name = fullfile(sim_name_base, sprintf('sim_%d', i));
      Simulation.consecutiveRuns(num_runs, sim_name);
    end
    
  end
end
  
%% Noise with each noise level and a particle filter, with advice
if(test.advice_noise_pf)
  for noise_index = 1:length(noise_levels)
    sim_name_base = sprintf('%s_advice_noise_%.2f_pf', test_name, noise_levels(noise_index));
    config = base_config;
    config.advice.enabled = true;
    config.noise.enabled = true;
    config.noise.sigma_trans = noise_levels(noise_index);
    config.noise.PF.sigma_meas = noise_levels(noise_index);
    config.noise.PF.sigma_initial = noise_levels(noise_index);
    config.noise.PF.random_sigma = 2*noise_levels(noise_index);
    config.noise.PF.enabled = true;
    
    parfor i = sim_start_num:(sim_start_num + num_sims - 1)
      % Create simulation object, initialize, and run
      Simulation = ExecutiveSimulation(config);
      Simulation.initialize();
      sim_name = fullfile(sim_name_base, sprintf('sim_%d', i));
      Simulation.consecutiveRuns(num_runs, sim_name);
    end
    
  end
end
