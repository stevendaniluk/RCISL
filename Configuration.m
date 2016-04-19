classdef Configuration < handle
    
    properties
        
        % Primary Scenario Parameters
        numRobots    = 3;
        numObstacles = 4;
        numTargets   = 3;
        numIterations = 15000;
        robot_Type =[ 4*pi/18   3   0.30    1; ... %strong-slow
                      4*pi/18   2   0.40    2; ... %weak-fast
                      4*pi/18   2   0.30    3; ... %weak-slow
                      4*pi/18   3   0.40    4];    %strong-fast
                     %size   %weight   %id
        target_Type =[ 0.5      1       1; ...
                       0.2      2       2];
        robot_sameStrength = [1; 2; 2; 1;]; %comparative Ids for strength
        robot_Reach = 1;
        
        % Action Parameters
        boxForce = 0.05;
        rotationSize = pi/4;
        stepSize =0.1;
        angle = [0; 90; 180; 270];
        
        % World Parameters
        world_Height = 10;
        world_Width  = 10;
        world_Depth  = 0;
        world_randomPaddingSize = 0;
        world_randomBorderSize = 0.1;
        world_robotSize = 0.125;
        world_obstacleSize = 0.5;
        world_targetSize = 0.25;
        world_goalSize = 1;
        world_robotMass = 1;
        world_obstacleMass = 0;
        simulation_Realism = 0;

        % CISCL Parameters
        cisl_learningFrequency = 1;
        cisl_TriggerDistance = 1.7;
        cisl_decideFactor = 0;
        cisl_MaxGridSize = 11;
        
        % Q-Learning Parameters
        qlearning_gamma = 0.3;
        qlearning_alphaDenom = 30;
        qlearning_alphaPower = 1;
        qlearning_rewardDistanceScale = 0;
        arrBits = 20;
        targetReward = 10;
        actionsAmount = 7;
        
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
        
        % Noise and Particle Filter Parameters
        robot_NoiseLevel = 0;
        particle_Used = 0;
        particle_ResampleNoiseSTD = 0.02;
        particle_ControlStd = 0.1;
        particle_SensorStd  = 0.05;
        particle_Number = 35;
        particle_PruneNumber = 7;
        
    end
    
end

