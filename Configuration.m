classdef Configuration < handle
    
    properties
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % General Simulation Settings
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        % Graphics Parameters
        show_live_graphics = true
        show_track_graphics = false;
                        
        % Primary Scenario Parameters
        max_iterations = 2000;
        numRobots    = 4;
        numObstacles = 4;
        numTargets   = 4;
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
        expert_on = false;                    % If expert agent(s) shoudld be loaded
        expert_filename = '1_bot';          % Folder name containing Q and experience tables
        expert_id = [1];                  % Id(s) of expert agent(s)
        
        % Policy parameters
        policy = 'softmax'; % Options: "greedy", "e-greedy", "softmax"
        e_greedy_epsilon = 0.10;
        softmax_temp = 0.10;        % Temperature for softmax distribution
        
        % Individual Q-Learning Parameters
        gamma = 0.3;            % Discount factor
        alpha_max = 0.9;        % Maximum value of learning rate
        alpha_denom = 300;      % Coefficient in alpha update equation
        alpha_power = 2;        % Coefficient in alpha update equation
        
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
        advice_mechanism = 'advice_dev';      
            % Options: 
            %   -advice_exchange
            %   -advice_dev
        
        greedy_override = false;              % Overrides the policy with a greedy selection
        
        % Advice Enhancement Parameters
        a_dev_expert_filename = 'advisor_320_epochs';
        a_dev_evil_advisor = false;
        a_dev_e_greedy_epsilon = 0.05;
        a_dev_state_resolution = [50, 2];         % Resolution of state
        a_dev_gamma = 0.3;                    % Discount factor
        a_dev_alpha_max = 0.9;                % Maximum value of learning rate
        a_dev_alpha_denom = 300;          % Coefficient in alpha update equation
        a_dev_alpha_power = 2;                % Coefficient in alpha update equation
        
        % Advice Exchange Parameters
        ae_alpha = 0.80;                      % Coefficient for current average quality update
        ae_beta = 0.95;                       % Coefficient for best average quality update
        ae_delta = 0.00;                      % Coefficient for quality comparison
        ae_rho = 1.00;                        % Coefficient for quality comparison
        
    end
    
end

