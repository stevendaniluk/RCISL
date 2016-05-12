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
                
        % Action Parameters
        boxForce = 0.05;
        action_angle = [0; 90; 180; 270];
        num_actions = 7;
        num_state_vrbls = 5;
        num_state_bits = 4;
        
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
        min_utility_threshold = 0.01;
        item_closer_reward = 0.5;
        item_further_reward = -0.3;
        robot_closer_reward = 0.5;
        robot_further_reward = -0.3;
        return_reward = 10;
        empty_reward_value = 0.0;
        reward_activation_dist = 0.0;
        reward_distance_scale = 0.17;
        
        % Policy parameters
        policy = 'e-greedy'; % Options: "greedy", "e-greedy", "softmax", "justins"
        e_greedy_epsilon = 0.1;
        softmax_temp = 0.25;
        
        % Q-Learning Parameters
        gamma = 0.3;
        alpha_denom = 30;
        alpha_power = 1;
        
        % L-Alliance Parameters
        lalliance_convergeAttempts = 70;
        lalliance_convergeSlope = 0.15;
        lalliance_useDistance = 1;
        lalliance_calculateTau = 1; %Do we automatically calculate taus?
        lalliance_tmax = 6000;
        lalliance_tmin = 5800;
        lalliance_failureTau = 3000;
        lalliance_acquiescence = 1500;
        lalliance_confidenceFactor = 10;
        lalliance_useCooperationLimit = 0;
        lalliance_useFast = 1; %default to using only the slow impatience rate
        lalliance_useCooperation = 0; %Do we store taus for cooperation?
        lalliance_motiv_freq = 15;
        lalliance_theta = 5;
        lalliance_motivation_Threshold = 0.0001;
        lalliance_movingAverageKeep = 0.6;
        lalliance_tauType = 1; %tauType = 1 - Moving Average
        %Amount of task types, and if we learn about each TASK or it's TYPE
        % (it's intractable to assume each task as independent)
        lalliance_updateByTaskType = 1;
        la_epochMax = 300;
        
        % Advice Exchange Parameters
        advexc_on = 0;
        adv_epochMax = 500;
        %Eta: moving average calc
        % avg = avg*(1-eta) + measurment*eta
        advice_eta = 0.2;
        %Delta: when to take advice, comparing our current to advisors avg
        %if(averageQual < advisorAvgOfAvgQual (1 - delta);
        advice_delta = 0.5;
        advice_row = 1;
        advice_threshold = 0;% threshold*ourExpectedIndividualReward <= theirExpectedIndividualReward  --> take advice
                
    end
    
end

