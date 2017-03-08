classdef Configuration < handle
  % CONFIGURATION - Contains all parameters for the simulation
  
  % All parameters for the simulationa re contained within the
  % configuration object, and are divided into six categories:
  %   -sim: General Simulation Settings
  %   -scenario: Scenario Definition
  %   -noise: Noise and Uncertainty
  %   -IL: Individual Learning
  %   -TL: Team Learning
  %   -advice: Advice Mechanism
  %
  % The configuration object is created once, and passed to the
  % ExecutiveSimulation constructor, which then passes it to any
  % additional classes requireding parameters.
  
  properties
    % Structure containing parameters for each category
    sim;
    scenario;
    noise;
    IL;
    TL;
    advice;
  end
  
  methods
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %   Constructor
    %
    %   All parameters are set here.
    
    function this = Configuration()
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % General Simulation Settings
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      
      % Data Saving Parameters (turn off for speed)
      this.sim.save_simulation_data = true;  % Flag for recording and saving simulation data
      this.sim.save_IL_data = false;          % Flag for recording and saving individual learning data
      this.sim.save_TL_data = false;          % Flag for recording and saving team learning data
      this.sim.save_advice_data = false;      % Flag for recording and saving advice data
      
      % Graphics Parameters
      this.sim.show_live_graphics = false;   % Display the graphics during the simluation
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % Scenario Definition
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      
      % Primary Scenario Parameters
      this.scenario.max_iterations = 4000;        % Maximum allowed iterations
      this.scenario.num_robots = 4;               % Total number of robots
      this.scenario.num_obstacles = 4;            % Total number of obstacles
      this.scenario.num_targets = 4;              % Total number of targets
      
      % World Parameters
      this.scenario.world_height = 10;               % World Y dimension [meters]
      this.scenario.world_width  = 10;               % World X dimension [meters]
      this.scenario.grid_size = 0.5;                 % Discritization of world into grid for random placement [meters]
      this.scenario.random_pos_padding = 1.0;        % Padding distance between randomly placed objects [meters]
      this.scenario.random_border_padding = 1.0;     % Padding distance between randomly placed objects and the borders [meters]
      this.scenario.robot_size = 0.125;              % Diameter of robots [meters]
      this.scenario.obstacle_size = 0.5;             % Diameter of obstacles [meters]
      this.scenario.target_size = 0.25;              % Diameter of targets [meters]
      this.scenario.goal_size = 1;                   % Diameter of collection zone [meters]
      this.scenario.terrain_on = true;               % Flag for if rough terrain is used
      this.scenario.terrain_size = 3.0;              % Square size of rough terrain [meters]
      this.scenario.terrain_fractional_speed = 0.3;  % Reduction is speed when in rough terrain
      
      % Robot Parameters
      
      % Weak and slow
      type_1.step_size = 0.30;
      type_1.rotate_size = pi*(2/9);
      type_1.strong = false;
      type_1.rugged = false;
      type_1.reach = 0.5;
      type_1.label = 'WS';
      
      % Weak and fast
      type_2.step_size = 0.40;
      type_2.rotate_size = pi*(3/9);
      type_2.strong = false;
      type_2.rugged = true;
      type_2.reach = 0.5;
      type_2.label = 'WF';
      
      % Strong and slow
      type_3.step_size = 0.30;
      type_3.rotate_size = pi*(2/9);
      type_3.strong = true;
      type_3.rugged = false;
      type_3.reach = 0.5;
      type_3.label = 'SS';
      
      % Strong and fast
      type_4.step_size = 0.40;
      type_4.rotate_size = pi*(3/9);
      type_4.strong = true;
      type_4.rugged = true;
      type_4.reach = 0.5;
      type_4.label = 'SF';
      
      this.scenario.robot_types = [type_1, type_2, type_3, type_4];
      this.scenario.target_types = {'light', 'light', 'light', 'light'};
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % Noise and Uncertainty
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      
      % Noise and Particle Filter Parameters
      this.noise.sigma = 0.0;
      this.noise.PF.enabled = true;
      this.noise.PF.resample_std = 0.02;
      this.noise.PF.control_std = 0.1;
      this.noise.PF.sensor_std  = 0.05;
      this.noise.PF.num_particles = 35;
      this.noise.PF.prune_number = 7;
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % Individual Learning
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      
      % Individual Learning Parameters
      this.IL.enabled = true;                 % Flag for if individual learning is enabled
      this.IL.learning_iterations = 1;        % Number of iterations between learning updates
      this.IL.item_closer_reward = 0.5;       % Reward for robot moving item closer to collection zone
      this.IL.item_further_reward = -0.3;     % Reward for robot moving item further from collection zone
      this.IL.robot_closer_reward = 0.3;      % Reward for robot moving close to target item
      this.IL.robot_further_reward = -0.1;    % Reward for robot moving further from target item
      this.IL.return_reward = 10;             % Reward for retuning item to collection zone
      this.IL.empty_reward_value = -0.01;     % Default reward if no other conditions met
      this.IL.reward_activation_dist = 0.10;  % Minimum distance to move to receive reward
      
      % Expert Parameters
      this.IL.expert_on = false;              % If expert agent(s) shoudld be loaded
      this.IL.expert_filename = {'E100'};     % File for each expert
      this.IL.expert_id = [2];                % Id(s) of expert agent(s)
      
      % Policy parameters
      this.IL.policy = 'softmax';             % Options: "greedy", "e-greedy", "softmax"
      this.IL.e_greedy_epsilon = 0.10;        % Probability of selecting random action
      this.IL.softmax_temp = 0.10;            % Temperature for softmax distribution
      
      % Action and State Parameters
      this.IL.num_actions = 4;                % Number of actions for a robot
      this.IL.state_resolution = ...          % Number of discritizations for each state variable
        [3;          % Goal Distance,
         5;          % Goal Angle
         3;          % Target Type
         3;          % Target Distance
         5;          % Target Angle
         3;          % Obstacle Distance
         5];         % Obstacle Angle
      if(this.scenario.terrain_on)
        % Append rough terrain state variables
        this.IL.state_resolution = [this.IL.state_resolution;
                                    3;  % Terrain distance
                                    5]; % Terrain angle
      end
      this.IL.look_ahead_dist = 2.0;          % Max distance used for state discritizations
      
      % Q-Learning Parameters
      this.IL.QL.gamma = 0.3;                 % Discount factor
      this.IL.QL.alpha_max = 0.9;             % Maximum value of learning rate
      this.IL.QL.alpha_rate = 5000;           % Coefficient in alpha update equation
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % Team Learning
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      
      % Team Learning Parameters
      this.TL.task_allocation = 'fixed';            % Options: "fixed", "l_alliance"
      
      % L-Alliance Parameters
      this.TL.LA.motiv_freq = 5;                    % Frequency at which motivation updates
      this.TL.LA.max_task_time = 5000;              % Maximum time on task before acquescing
      this.TL.LA.trial_time_update = 'stochastic';  % Options: "stochastic", "moving_avg"
      this.TL.LA.theta1 = 1.0;                      % Coefficient for stochastic update
      this.TL.LA.theta2 = 15.0;                     % Coefficient for stochastic update
      this.TL.LA.theta3 = 0.3;                      % Coefficient for stochastic update
      this.TL.LA.theta4 = 2.0;                      % Coefficient for stochastic update
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % Advice Mechanism
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      
      this.advice.enabled = false;                       % If advice should be used
      this.advice.num_advisers = inf;                    % Max number of advisers to use (inf means use all available)
      this.advice.reject_reward_bias = 1.5;              % Coefficient applied to reject reward
      this.advice.QL.gamma = 0.3;                        % Q-learning discount factor
      this.advice.QL.alpha_max = 0.9;                    % Q-learning maximum value of learning rate
      this.advice.QL.alpha_rate = 20000;                 % Q-learning coefficient in alpha update equation
      this.advice.QL.state_resolution = [100, 2, 2];     % Q-learning state resolution
      this.advice.num_actions = 3;                       % Number of possible actions for the mechanism
      this.advice.e_greedy = 0.05;                       % Probability fo selecting a random action
      this.advice.adviser_value_alpha = 0.99;            % Rate update coefficient for adviser value
      this.advice.evil_advice_prob = 0.0;                % Probability that an adviser will be evil
      this.advice.fake_advisers = false;                 % Flag for using fake advisers (as opposed to other robots)
      this.advice.fake_adviser_files = {'E100'; 'E10'};  % Filenames for fake adviser data (fromt he expert folder)
      this.advice.all_accept = false;                    % Flag to override all actions with accept
      this.advice.all_reject = false;                    % Flag to override all actions with reject
      
    end
  end
end

