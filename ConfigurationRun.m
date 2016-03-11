classdef ConfigurationRun < handle
    
    properties
        
        configId = 0;
        
        numRobots    = 0;
        numObstacles = 0;
        numTargets   = 0;
        numTest = 0;
        numRun  = 0;
        numIterations = 0;
        
        simulation_NewWorldEveryTest = 0;
        simulation_NewWorldEveryRun = 0;
        simulation_NewRobotsEveryTest = 0;
        simulation_NewRobotsEveryRun = 0;        
        world_Height = 0;
        world_Width  = 0;
        world_Depth  = 0;
        cisl_MaxGridSize = 0;
        robot_Type =[];    
        robot_sameStrength = []; 
        robot_Reach = 0;
        target_Type =[];

        qteam_epochMax = 200;
        qteam_epochConvergeTicks = 0;

        adv_epochMax = 20;
        la_epochMax = 300;

        robot_NoiseLevel = 0;        
        particle_Used = 0;
        particle_ResampleNoiseSTD = 0.0015;
        particle_ControlStd = 0.001;
        particle_SensorStd  = 1;
        particle_controlType = 0;
        particle_resampleType = 0;
        particle_weightType = 0;
        particle_borderControlType = 0;
        particle_resampleSortingType = 0;
        particle_pastWeightAmount = 0;
        
        particle_Number = 0;
        particle_PruneNumber = 0;
        
        
        advexc_on = 0;
        
        simulation_Realism = 0;
        world_Continuity = 0;
        
        % OLD Implementation
        % lalliance_doStochasticLearning = 0;

        % New implementation.
        %
        lalliance_motiv_freq = 1;
        lalliance_theta = 5;
        lalliance_motivation_Threshold = 0.0001;
        lalliance_movingAverageKeep = 0.6;

        lalliance_convergeAttempts = 70;
        lalliance_convergeSlope = 0.15;
        lalliance_useDistance = 1;

        %tauType = 1 - Moving Average
        lalliance_tauType = 1;


        %default to using only the slow impatience rate
        lalliance_useFast = 1;

        %Do we store taus for cooperation?
        lalliance_useCooperation = 0;

        %Do we automatically calculate taus?
        lalliance_calculateTau = 1;
        lalliance_tauCounter = 0;
        lalliance_tmax = 7000;
        lalliance_tmin = 4000;
        lalliance_failureTau = 7000;
        lalliance_acquiescence = 3000;
        lalliance_confidenceFactor = 0;
        lalliance_useCooperationLimit = 0;
        

        %Eta: moving average calc
        % avg = avg*(1-eta) + measurment*eta
        advice_eta = 0.9;
        
        %Delta: when to take advice, comparing our current to advisors avg
        %if(averageQual < advisorAvgOfAvgQual (1 - delta);
        advice_delta = 0.0;
        
        advice_row = 1;
        advice_threshold = 0;% threshold*ourExpectedIndividualReward <= theirExpectedIndividualReward  --> take advice
        
        %Amount of task types, and if we learn about each TASK or it's TYPE
        % (it's intractable to assume each task as independent)
        lalliance_updateByTaskType = 1;

        cisl_learningFrequency = 1;
        cisl_TriggerDistance = 1.7;
        cisl_type = 1;
        cisl_decideFactor = 0;
        
        qlearning_gammamin = 0;
        qlearning_gammamax = 0;
        qlearning_alphaDenom = 30;
        qlearning_alphaPower = 1;
        qlearning_rewardDistanceScale = 0;
        
        
        world_randomPaddingSize = 0;
        world_randomBorderSize = 0;
        world_robotSize = 0;
        world_obstacleSize = 0;
        world_targetSize = 0;
        world_goalSize = 0;
        world_robotMass = 0;
        world_targetMass = 0;
        world_obstacleMass = 0; 
        
        qsystem_commitActionLength = 0;
        
        compressed_sensingOn = 0;
        use_hal = 0;
        
    end
    
    
    methods

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
        function this = ConfigurationRun()
            
            this.numRobots = Configuration.numRobots;
            this.numObstacles = Configuration.numObstacles;
            this.numTargets = Configuration.numTargets;
            this.numRun = Configuration.numRun;
            this.simulation_NewWorldEveryTest = Configuration.simulation_NewWorldEveryTest;
            this.simulation_NewRobotsEveryTest = Configuration.simulation_NewRobotsEveryTest;
            this.world_Height = Configuration.world_Height;
            this.world_Width = Configuration.world_Width;
            this.world_Depth = Configuration.world_Depth;
            this.cisl_MaxGridSize = Configuration.cisl_MaxGridSize;
            this.robot_Type = Configuration.robot_Type;    %strong-fast
            this.robot_sameStrength = Configuration.robot_sameStrength; %comparative Ids for strength
            this.robot_Reach = Configuration.robot_Reach;
            this.target_Type = Configuration.target_Type ;
            this.robot_NoiseLevel = Configuration.robot_NoiseLevel;        
            this.particle_Used = Configuration.particle_Used ;
            this.particle_ResampleNoiseSTD = Configuration.particle_ResampleNoiseSTD;
            this.particle_ControlStd = Configuration.particle_ControlStd ;
            this.particle_SensorStd  = Configuration.particle_SensorStd  ;
            this.particle_controlType = Configuration.particle_controlType ;
            this.particle_resampleType = Configuration.particle_resampleType ;
            this.particle_weightType = Configuration.particle_weightType ;
            this.particle_borderControlType = Configuration.particle_borderControlType ;
            this.particle_resampleSortingType = Configuration.particle_resampleSortingType;
            this.particle_pastWeightAmount = Configuration.particle_pastWeightAmount ;
            this.particle_Number = Configuration.particle_Number ;
            this.particle_PruneNumber = Configuration.particle_PruneNumber ;
            this.world_Continuity = Configuration.world_Continuity ;
            this.numTest = Configuration.numTest;
            this.numIterations = Configuration.numIterations;
            this.simulation_NewWorldEveryRun = Configuration.simulation_NewWorldEveryRun;
            this.simulation_NewRobotsEveryRun = Configuration.simulation_NewRobotsEveryRun;
            this.simulation_Realism  = Configuration.simulation_Realism;
            this.lalliance_motiv_freq = Configuration.lalliance_motiv_freq;
            this.cisl_learningFrequency = Configuration.cisl_learningFrequency; 
            this.qlearning_gammamin = Configuration.qlearning_gammamin;
            this.qlearning_gammamax = Configuration.qlearning_gammamax;
          
            this.world_randomPaddingSize = Configuration.world_randomPaddingSize;
            this.world_randomBorderSize = Configuration.world_randomBorderSize;
            this.world_robotSize = Configuration.world_robotSize;
            this.world_obstacleSize = Configuration.world_obstacleSize;
            this.world_targetSize = Configuration.world_targetSize ;
            this.world_goalSize = Configuration.world_goalSize ;
            this.world_robotMass = Configuration.world_robotMass ;
            this.world_targetMass = Configuration.world_targetMass ;
            this.world_obstacleMass = Configuration.world_obstacleMass ; 
            
            
        end
    end
    
end

