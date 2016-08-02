classdef Configuration < handle
    
    properties
        
        % Graphics Parameters
        show_live_graphics = true;
        show_track_graphics = false;
                        
        % Primary Scenario Parameters
        max_iterations = 15000;
        numRobots    = 3;
        numObstacles = 4;
        numTargets   = 3;
        robot_Type =[ 4*pi/18   3   0.30    1; ... 
                      4*pi/18   2   0.40    2; ... 
                      4*pi/18   2   0.30    3; ... 
                      4*pi/18   3   0.40    4];    
                           %size   %weight   %id
        target_Type =[ 0.2      1       1; ...
                       0.2      1       1];
        robot_sameStrength = [1; 2; 2; 1]; %comparative Ids for strength
        robot_Reach = 1;
                
        % Action and State Parameters
        num_actions = 5;
        num_state_vrbls = 5;
        num_state_bits = [4, 1, 4, 4, 4];
        backup_fractional_speed = 0.0;
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
        simulation_Realism = 0;
        
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
        empty_reward_value = -0.01;
        reward_activation_dist = 0.17;
        
        % Policy parameters
        policy = 'softmax'; % Options: "greedy", "e-greedy", "softmax"
        e_greedy_epsilon = 0.10;
        softmax_temp = 0.10;        % Temperature for softmax distribution
        
        % Q-Learning Parameters
        gamma = 0.3;            % Discount factor
        alpha_max = 0.9;        % Maximum value of learning rate
        alpha_denom = 30;       % Coefficient in alpha update equation
        alpha_power = 1;        % Coefficient in alpha update equation
        
        % Team Learning Parameters
        task_allocation = 'fixed';  % Options: "fixed", "l_alliance"
        
        % L-Alliance Parameters
        motiv_freq = 5;             % Frequency at which motivation updates
        max_task_time = 2000;       % Maximum time on task before acquescing
        trial_time_update = 'recursive_stochastic'; % Options: "moving_average", "recursive_stochastic"
        stochastic_update_theta1 = 1.0; % Coefficient for stochastic update
        stochastic_update_theta2 = 0.9; % Coefficient for stochastic update
        stochastic_update_theta3 = 1.0; % Coefficient for stochastic update
        stochastic_update_theta4 = 2.5; % Coefficient for stochastic update
        
        % Advice Exchange Parameters
        advexc_on = 0;
        
    end
    
end

