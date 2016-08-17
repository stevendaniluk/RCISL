classdef Configuration < handle
    
    properties
        
        % Graphics Parameters
        show_live_graphics = false
        show_track_graphics = false;
                        
        % Primary Scenario Parameters
        max_iterations = 2000;
        numRobots    = 4;
        numObstacles = 4;
        numTargets   = 4;
        robot_Type =[ 4*pi/18      2         0.30      1; ... 
                      4*pi/18      1         0.40      2; ... 
                      4*pi/18      1         0.30      3; ... 
                      4*pi/18      2         0.40      4];    
                    % Rotation  Strength  Step Size Type Id
        target_Type = [0.2, 1; 0.2, 1];
        robot_Reach = 1;
                
        % Action and State Parameters
        num_actions = 5;
        num_state_vrbls = 5;
        state_resolution = [16, 3, 16, 16, 16];
        backup_fractional_speed = 1.0;
        look_ahead_dist = 1.5;
        
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
        
        % Individual Learning Parameters
        learning_iterations = 1;
        item_closer_reward = 0.5;
        item_further_reward = -0.3;
        robot_closer_reward = 0.5;
        robot_further_reward = -0.3;
        return_reward = 10;
        empty_reward_value = 0.0;
        reward_activation_dist = 0.17;
        
        % Policy parameters
        policy = 'softmax'; % Options: "greedy", "e-greedy", "softmax"
        e_greedy_epsilon = 0.10;
        softmax_temp = 0.05;        % Temperature for softmax distribution
        
        % Individual Q-Learning Parameters
        gamma = 0.3;            % Discount factor
        alpha_max = 0.9;        % Maximum value of learning rate
        alpha_denom = 300;      % Coefficient in alpha update equation
        alpha_power = 2;        % Coefficient in alpha update equation
        
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
        
        % Advice Parameters
        advice_on = false;                  % If advice should be used
        advice_mechanism = 'h_advice';     % Options: "advice_exchange", "h_advice"
        greedy_override = false;           % Overrides the policy with a greedy selection
        
        ha_state_resolution = 128;         % Resolution of entropy
        ha_softmax_temp = 0.10;            % Advisor selection softmax
        ha_gamma = 0.3;                    % Discount factor
        ha_alpha_max = 0.9;                % Maximum value of learning rate
        ha_alpha_denom = 5000000;          % Coefficient in alpha update equation
        ha_alpha_power = 2;                % Coefficient in alpha update equation
        
        ae_alpha = 0.85;                   % Coefficient for current average quality update
        ae_beta = 0.90;                    % Coefficient for best average quality update
        ae_delta = 0.03;                   % Coefficient for quality comparison
        ae_rho = 0.95;                     % Coefficient for quality comparison
    end
    
end

