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
      this.sim.save_simulation_data = true;   % Flag for recording and saving simulation data
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
      this.scenario.grid_size = 0.1;                 % Discritization of world into grid for random placement [meters]
      this.scenario.random_pos_padding = 0.5;        % Padding distance between randomly placed objects [meters]
      this.scenario.random_border_padding = 0.5;     % Padding distance between randomly placed objects and the borders [meters]
      this.scenario.robot_size = 0.125;              % Diameter of robots [meters]
      this.scenario.obstacle_size = 1.0;             % Diameter of obstacles [meters]
      this.scenario.target_size = 0.25;              % Diameter of targets [meters]
      this.scenario.goal_size = 2.0;                 % Diameter of collection zone [meters]
      this.scenario.terrain_on = true;               % Flag for if rough terrain is used
      this.scenario.terrain_centred = true;          % Flag for placing terrain in centre of world
      this.scenario.terrain_size = 4.0;              % Square size of rough terrain [meters]
      this.scenario.terrain_fractional_speed = 0.0;  % Speed reduction in rough terrain (0.0 means cannot enter terrain)
      
      % Robot Parameters
      
      % Slow, Non-Rugged, Weak
      this.scenario.robot_defs(1).step_size = 0.20;
      this.scenario.robot_defs(1).rotate_size = pi*(1/5);
      this.scenario.robot_defs(1).strong = false;
      this.scenario.robot_defs(1).rugged = false;
      this.scenario.robot_defs(1).reach = 0.5;
      this.scenario.robot_defs(1).label = 'S-NR';
      
      % Fast, Non-Rugged, Weak
      this.scenario.robot_defs(2).step_size = 0.40;
      this.scenario.robot_defs(2).rotate_size = pi*(1/5);
      this.scenario.robot_defs(2).strong = false;
      this.scenario.robot_defs(2).rugged = false;
      this.scenario.robot_defs(2).reach = 0.5;
      this.scenario.robot_defs(2).label = 'F-NR';
      
      % Slow, Rugged, Weak
      this.scenario.robot_defs(3).step_size = 0.20;
      this.scenario.robot_defs(3).rotate_size = pi*(1/5);
      this.scenario.robot_defs(3).strong = false;
      this.scenario.robot_defs(3).rugged = true;
      this.scenario.robot_defs(3).reach = 0.5;
      this.scenario.robot_defs(3).label = 'S-R';
      
      % Fast, Rugged, Weak
      this.scenario.robot_defs(4).step_size = 0.40;
      this.scenario.robot_defs(4).rotate_size = pi*(1/5);
      this.scenario.robot_defs(4).strong = false;
      this.scenario.robot_defs(4).rugged = true;
      this.scenario.robot_defs(4).reach = 0.5;
      this.scenario.robot_defs(4).label = 'F-R';
      
      this.scenario.robot_types = [1, 2, 3, 4];
      this.scenario.target_types = {'light', 'light', 'light', 'light'};
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % Noise and Uncertainty
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      
      % Noise and Particle Filter Parameters
      this.noise.enabled = false;         % Add noise to robot state
      this.noise.sigma_trans = 0.1;       % Std Dev for translational motion
      this.noise.sigma_rot = 0.1;         % Std Dev for rotational motion
      this.noise.PF.enabled = false;      % Filter state with particle filter
      this.noise.PF.num_particles = 20;   % Particles to use in filter
      this.noise.PF.sigma_meas = 0.1;     % Std Dev of measurement likelihood
      this.noise.PF.sigma_initial = 0.1;  % Std Dev of distribution to draw initial particles from
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % Individual Learning
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      
      % Individual Learning Parameters
      this.IL.enabled = true;                % Flag for if individual learning is enabled
      this.IL.learning_iterations = 1;       % Number of iterations between learning updates
      this.IL.item_closer_reward = 5.0;      % Reward for robot moving item closer to collection zone
      this.IL.item_further_reward = 0.1;     % Reward for robot moving item further from collection zone
      this.IL.robot_closer_reward = 5.0;     % Reward for robot moving close to target item
      this.IL.robot_further_reward = 0.1;    % Reward for robot moving further from target item
      this.IL.return_reward = 50;            % Reward for retuning item to collection zone
      this.IL.empty_reward_value = 1.00;     % Default reward if no other conditions met
      this.IL.reward_activation_dist = 0.3;  % Minimum distance to move to receive reward (% of step size)
      
      % Expert Parameters
      this.IL.expert_on = false;             % If expert agent(s) shoudld be loaded
      this.IL.expert_filename = {'A', 'B'};  % Folder for each expert (in expert_data dir)
      this.IL.expert_id = [1, 2];            % Id(s) of expert agent(s)
      
      % Policy parameters
      this.IL.policy = 'GLIE';                % Options: "greedy", "e-greedy", "boltzmann", "GLIE"
      this.IL.e_greedy_epsilon = 0.10;        % Probability of selecting random action
      this.IL.boltzmann_temp = 1.0;           % Constant temperature for boltzmann distribution
      this.IL.GLIE_min_p = 0.02;              % Optional minimum allowable probability with GLIE policy
      
      % Action and State Parameters
      this.IL.num_actions = 4; % Number of actions for a robot
      goal_res = [4; 5];       % [Goal Distance; Goal Angle]
      target_res = [2; 4; 5];  % [Target Type; Target Distance; Target Angle]
      obst_res = [5; 2];       % [Obstacle Distance (per ray); Obstacle type (wall/obstacle or terrain)]
      this.IL.num_obstacle_rays = 3;      % Number of scan rays for obstacles
      this.IL.obstacle_ray_angle = pi/10;  % Angle between rays [degrees]
      this.IL.state_resolution = [goal_res;
                                  target_res;
                                  repmat(obst_res, this.IL.num_obstacle_rays, 1)];
      this.IL.look_ahead_dist = 2.0;          % Max distance used for state discritizations
      
      % Q-Learning Parameters
      this.IL.QL.gamma = 0.3;                 % Discount factor
      this.IL.QL.alpha_max = 1.0;             % Maximum value of learning rate
      this.IL.QL.alpha_rate = 1.0;            % Exponent in alpha update equation
      
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
      this.advice.enabled = false;                   % If advice should be used
      this.advice.mechanism = 'advice_enhancement';  % Options: "advice_enhancement", "advice_exchange"
      
      if(strcmp(this.advice.mechanism, 'advice_enhancement'))
        this.advice.num_advisers = inf;                    % Max number of advisers to use (inf means use all available)
        this.advice.QL.gamma = 0.3;                        % Q-learning discount factor
        this.advice.QL.alpha_max = 1.0;                    % Q-learning maximum value of learning rate
        this.advice.QL.alpha_rate = 1.0;                   % Q-learning power in alpha update equation
        this.advice.QL.state_resolution = [50, 2, 50];     % Q-learning state resolution
        this.advice.num_actions = 3;                       % Number of possible actions for the mechanism
        this.advice.e_greedy = 0.05;                       % Probability fo selecting a random action
        this.advice.accept_bias = 2.5;                     % Bias on reward signal for accepting advice
        this.advice.adviser_relevance_alpha = 0.99;        % Rate update coefficient for adviser relevance
        this.advice.evil_advice_prob = 0.0;                % Probability that an adviser will be evil
        this.advice.fake_advisers = false;                 % Flag for using fake advisers (as opposed to other robots)
        this.advice.fake_adviser_files = {'E100'; 'E10'};  % Filenames for fake adviser data (fromt he expert folder)
      elseif(strcmp(this.advice.mechanism, 'advice_exchange'))
        this.advice.alpha = 0.9;    % Coefficient for current average quality update
        this.advice.beta = 0.9;     % Coefficient for best average quality update
        this.advice.delta = 0.9;    % Coefficient for average quality comparison
        this.advice.rho = 0.9;      % Coefficient for quality sum comparison
      end
    end
  end
end

