classdef Configuration < handle
    
    properties
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % General Simulation Settings
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        % Graphics Parameters
        show_live_graphics = false
        show_track_graphics = false;
                        
        % Primary Scenario Parameters
        max_iterations = 2000;
        numRobots    = 1;
        numObstacles = 4;
        numTargets   = 1;
        robot_Type =[ pi*(2/9)     2         0.30      1; ... 
                      pi*(2/9)     1         0.30      2; ... 
                      pi*(2/9)     1         0.30      3; ... 
                      pi*(2/9)     2         0.30      4];    
                    % Rotation  Strength  Step Size Type Id
        target_Type = [0.2, 1; 0.2, 1];
        robot_Reach = 0.5;
                
        % Action and State Parameters
        num_actions = 4;
        num_state_vrbls = 7;
        state_resolution = [3;   % Target Type
                            3;   % Target Distance
                            5;   % Target Angle
                            3;   % Goal Distance
                            5;   % Goal Angle
                            3;   % Obstacle Distance
                            5]'; % Obstacle Angle
        look_ahead_dist = 2.0;
        backup_fractional_speed = 1.0;
        
        % World Parameters
        world_height = 10;
        world_width  = 10;
        world_depth  = 0;
        grid_size = 0.5;
        random_pos_padding = 1.0;
        random_border_padding = 1.0;
        robot_size = 0.125;
        robot_mass = 1;
        obstacle_size = 0.5;
        obstacle_mass = 0;
        target_size = 0.25;
        target_mass = 1;
        goal_size = 1;
        
        % Noise and Particle Filter Parameters
        noise_sigma = 0.0;
        particle_filer_on = true;
        particle_ResampleNoiseSTD = 0.02;
        particle_ControlStd = 0.1;
        particle_SensorStd  = 0.05;
        particle_Number = 35;
        particle_PruneNumber = 7;
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Individual Learning
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        % Individual Learning Parameters
        individual_learning_on = true;
        learning_iterations = 1;
        item_closer_reward = 0.5;
        item_further_reward = -0.3;
        robot_closer_reward = 0.3;
        robot_further_reward = -0.1;
        return_reward = 10;
        empty_reward_value = -0.01;
        reward_activation_dist = 0.15;
        
        % Expert Parameters
        expert_on = false;                   % If expert agent(s) shoudld be loaded
        expert_filename = {'2_bot_320'};    % File for each expert
        expert_id = [2];                    % Id(s) of expert agent(s)
        
        % Policy parameters
        policy = 'softmax'; % Options: "greedy", "e-greedy", "softmax"
        e_greedy_epsilon = 0.10;
        softmax_temp = 0.10;        % Temperature for softmax distribution
        
        % Individual Q-Learning Parameters
        gamma = 0.3;            % Discount factor
        alpha_max = 0.9;        % Maximum value of learning rate
        alpha_rate = 5000;      % Coefficient in alpha update equation
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Team Learning
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        % Team Learning Parameters
        task_allocation = 'fixed';  % Options: "fixed", "l_alliance"
        
        % L-Alliance Parameters
        motiv_freq = 5;             % Frequency at which motivation updates
        max_task_time = 5000;       % Maximum time on task before acquescing
        trial_time_update = 'recursive_stochastic'; % Options: "moving_average", "recursive_stochastic"
        stochastic_update_theta1 = 1.0;  % Coefficient for stochastic update
        stochastic_update_theta2 = 15.0; % Coefficient for stochastic update
        stochastic_update_theta3 = 0.3;  % Coefficient for stochastic update
        stochastic_update_theta4 = 2.0;  % Coefficient for stochastic update
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Advice
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        % General Advice Parameters
        advice_on = false;                    % If advice should be used
        advice_mechanism = 'advice_enhancement';      
            % Options: 
            %   -advice_enhancement
            %   -advice_exchange
        
        greedy_override = false;              % Overrides the policy with a greedy selection
        
        % Advice Enhancement Parameters
        a_enh_num_advisers = inf;                  % Max number of advisers to use (inf means use all available)
        a_enh_gamma = 0.3;                         % Q-learning discount factor
        a_enh_alpha_max = 0.9;                     % Q-learning maximum value of learning rate
        a_enh_alpha_rate = 20000;                  % Q-learning coefficient in alpha update equation
        a_enh_state_resolution = [100, 2, 2];      % Q-learning state resolution
        a_enh_num_actions = 2;                     % Number of possible actions for the mechanism
        a_enh_e_greedy = 0.10;                     % Probability fo selecting a random action
        a_enh_accept_rate_alpha = 0.99;            % Adviser acceptance rate update coefficient
        a_enh_evil_advice_prob = 0.0;              % Probability that an adviser will be evil
        a_enh_fake_advisers = false;               % Flag for using fake advisers (as opposed to other robots)
        a_enh_fake_adviser_files = {'E320'; 'E5'}; % Filenames for fake adviser data (fromt he expert folder)
        a_enh_all_accept = false;                  % Flag to override all actions with accept
        a_enh_all_reject = false;                  % Flag to override all actions with reject
        
        % Advice Exchange Parameters
        ae_alpha = 0.80;                      % Coefficient for current average quality update
        ae_beta = 0.95;                       % Coefficient for best average quality update
        ae_delta = 0.00;                      % Coefficient for quality comparison
        ae_rho = 1.00;                        % Coefficient for quality comparison
        
    end
    
end

