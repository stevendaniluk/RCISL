classdef Configuration < handle
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
    %Configuration
    %singleton class that holds all the configuration information for
    %a running simulation
    %it is globally accessible and guarnteed to be singular
    
    
    %Some Labels used
    %v23:
    %_f (just qLearning) set with decide of 30 gamma = 0.3
    %_g (just qLearning) set with NO decide factor
    %_h_higdecide (just qLearning) set decide factor 200 (!) to test
    %_i_reallyhigh (just qLearning) set decide factor 2000 (!) to test
    %_j_Remove GetHelp & No Decide factor & gamma = 0.6
    %_k_ Remove reward for being only robot on a box (still have drop box
    %punishment)
    %_L_ corrections to commit action code that led to never dropping a box
    %_M_ added 2.5 reward for holding box, and decide factor of 200
    %_N_ same as L, with reward for holding box
    %_O8_ using acquiescence limit for QAQ and QSystem
    
    properties (Constant)

        
        % CISL / learning parameters
        cisl_MaxGridSize = 11;
        
        
        % robots
        % [rot speed  %mass(strength) %stepSize   %id ]  
        robot_Type =[ 4*pi/18        3             0.30        1; ... %strong-slow
                      4*pi/18        2             0.40        2; ... %weak-fast
                      4*pi/18        2             0.30        3; ... %weak-slow
                      4*pi/18        3             0.40        4];    %strong-fast
%        robot_Type =[ 4*pi/18        2             0.30        3; ... %weak-fast
%                      4*pi/18        2             0.30        3; ... %weak-fast
%                      4*pi/18        2             0.30        3; ... %weak-fast
%                      4*pi/18        2             0.30        3];    %weak-fast
        robot_sameStrength = [1; 2; 2; 1;]; %comparative Ids for strength
                  
                  
        robot_Reach = 1;
                    %size     %weight          %id
        target_Type =[ 0.5        1                1; ...
                       0.2        2                2];
        
        
        robot_NoiseLevel = 0;        
        particle_Used = 0;
        
        %v12 values
        %particle_ResampleNoiseMean = 0.05;
        %particle_ResampleNoiseSTD = 0.1;

        %v13 values - experementally found
        particle_ResampleNoiseSTD = 0.0015;
        particle_ControlStd = 0.001;
        particle_SensorStd  = 1;
        %0 - basic filter
        %1 - forward forcasts guess control failure
        particle_controlType = 0;

        %0- default resample, right after control, but before sensor update
        %1- resample, before everything
        %2- resample, after everything, just before reading (good for
        %pruning)
        particle_resampleType = 0;

        %0 - default - exponental drop off with distance
        %1 - linear drop off (more venrable to outliers?)
        particle_weightType = 0;
        
        
        %0 - do nothing
        %1 - stop particles from drifting outside the world
        particle_borderControlType = 0;
        
        
        %0 - do nothing
        %1 - resample particles based on best weighted previous particle
        particle_resampleSortingType = 0;
        
        %0 - do nothing
        %[0,1] - percentage weight of past particle bias
        particle_pastWeightAmount = 0;
        
        particle_Number = 20;
        particle_PruneNumber = floor(20/3);
        
        %Some general configuration parameters!
        
        %These six will get overwritten during configuration assignment
        numRobots = 12;
        numObstacles = 2;
        numTargets = 12;
        numTest = 300;
        numRun = 1;
        numIterations = 15000;
        
        simulation_NewWorldEveryTest = 0;
        simulation_NewWorldEveryRun = 1;
        simulation_NewRobotsEveryTest = 0;
        simulation_NewRobotsEveryRun = 0;
        
        
        % update motivation every X iterations
        % it doesn't need to be updated every iteration
        lalliance_motiv_freq = 15;
       
        qlearning_gammamin = 0.3;
        qlearning_gammamax = 0.3;
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % cisl_learningFrequency 
        %
        % Execute learning after every [X] actions
        % drastically slows convergence, but speeds simulation time
        % after convergence, this speeds simulation time immensely
        %
        cisl_learningFrequency = 1;
        
        I_POS = 1:3;
        I_ORIENT = 4:6;
        %XY pos and Z orientation
        I_PXY_OZ = [1 2 6];
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % simulation_Realism
        %
        % 0 realism means grid based moves and "picking up" boxes
        % 1 means robots have to 'slide' the box across the floor
        % 2 means robots can cooperate, by picking boxes up together
        % (but! with 1 they can cooperate!)
        %
        simulation_Realism = 0;

        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % world_Continuity
        %
        % 0 zero means that the world will be gridded, and actions will
        % 'snap' objects to specific places in the grid
        % 1 the world is continuous
        world_Continuity = 0;

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % world_Height world_Width world_Depth
        %
        % The dimensions of this wonderful world
        % 
        % THESE SETTING VALUES ARE NOT USED!!!!!!! (I started implementing
        % and have NOT had time to finish.
        world_Height = 14;
        world_Width = 14;
        world_Depth = 0;

        
        world_randomPaddingSize = 0.5;
        world_randomBorderSize = 1;
        world_robotSize = 0.25/2;
        world_obstacleSize = 0.5;
        world_targetSize = 0.25;
        world_goalSize = 1.0;
        world_robotMass = 1;
        world_targetMass = 1;
        world_obstacleMass = 0; 
        
        last_configInstance = ConfigurationRun();
       
    end
    
    methods (Static)
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
        function inst = Instance(id)
            %singleton implementation
            inst = Configuration.GetConfiguration(id);

        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%
        %   GetConfiguration(id)
        %   
        %   Description: 
        %   Uses id, which is determined by the GUI interface, to set all
        %   the simulation parameters
        %
        %   id=XXXXXXXX, where each digit represents a parameter/catagory
        %
        %   Starting from the left most position (position 1)
        %   1)  Inverse Reward (On/Off)
        %   2)  Advice Exchange (On, None, Aggressive)
        %   3)  Particle Filter (None, Yes)
        %   4)  Crown (None, Yes)
        %   5)  Coop (Off, On, Cautious)
        %   6)  Team Learning (Q-Learning, L-Alliance, RSLA, QAQ,
        %                       L-Alliance-old)
        %   7)  Noise Level (None, 0.05m, 0.1m, 0.2m, 0.4m)
        %   8) Number of Robots (3, 8, 12)
        %   
        %   id gets dismantled by orders of 10 to read each parameter
        %   individually, then the parameters get set in config.xxxxx
        % 
        function config = GetConfiguration(id)

            config = Configuration.last_configInstance;
            
            if(config.configId == id)
                return;
            end

            config.configId=id ;
            
            %number =  sum([robotNum noiseNum teamLearning coop crowd pf adv inv] .* [1 10 100 1000 10000 100000 1000000 10000000],2)
            
            %%
            %Setting the time limit, compressed sensing, and distance rewards
            %params first
            if(id > 10^10) 
                timeLimitOff = floor(id/(10^10));     
                id = id - timeLimitOff *((10^10));
            else
                timeLimitOff = 0;
            end
            
            if(id > 10^9)
                comsen = floor(id/(10^9));     
                id = id - comsen*((10^9));
            else
                comsen = 0;
            end
            
            if(id > 10^8)
                distrwd = floor(id/(10^8));     
                id = id - distrwd *((10^8));
            else
                distrwd = 0;
            end
            
            %Dismantle the remaining 8 igits of the id into its respective
            %parameters
            inv = floor(id/10000000);     id = id - inv*          (10000000);
            adv = floor(id/1000000);      id = id - adv*          (1000000);
            pf = floor(id/100000);        id = id - pf*           (100000);
            crowd = floor(id/10000);      id = id - crowd*        (10000);
            coop = floor(id/1000);        id = id - coop*         (1000);
            teamLearning = floor(id/100); id = id - teamLearning* (100);
            noiseNum = floor(id/10);      id = id - noiseNum*     (10);
            robotNum = floor(id/1);       id = id - robotNum*     (1);
            %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %Assign all the parameters tot heir config.xxxx values
            
            config.qlearning_rewardDistanceScale = distrwd;
            
            % Version _tst4:
            % 0.2; 0.5; 300; 500;
            config.advice_eta = 0.2; %moving average (new measurement weight)
            config.advice_delta = 0.5; %advice threshold (percent advisor is better)
            config.advice_row = 1;
            config.advice_threshold = 0;
            
            config.la_epochMax = 300;
            config.adv_epochMax = 500;
            
            %Some sim parameters need to be adjusted for the number of
            %robots used, which happens below
            if(robotNum == 2)
                disp('3 robots');
                config.numTest = 300;
                config.numRun = 1;
                config.numIterations = 2000;
                config.numRobots = 3;
                config.numObstacles = 4;
                config.numTargets = 3;    
                config.lalliance_tmax = 6000;
                config.lalliance_tmin = 5800;
                config.lalliance_failureTau = 3000;
                config.lalliance_acquiescence = 1500;
                config.lalliance_confidenceFactor = 10; %The percentage we value of distance over tau
                config.world_Height = 10;
                config.world_Width = 10;
                config.world_randomPaddingSize = 0;
                config.world_randomBorderSize = 0.1;
                config.qteam_epochMax = 1500;
                config.qteam_epochConvergeTicks = 20000;
            elseif(robotNum == 3)
                disp('8 robots');
                config.numTest = 300;
                config.numRun = 1;
                config.numIterations = 15000;
                config.numRobots = 8;
                config.numObstacles = 4;
                config.numTargets = 8;    
                config.lalliance_tmax = 18000;
                config.lalliance_tmin = 17700;
                config.lalliance_failureTau = 9000;
                config.lalliance_acquiescence = 7000;
                config.lalliance_confidenceFactor = 10; %The percentage we value of distance over tau
                config.world_Height = 10;
                config.world_Width = 10;
                config.world_randomPaddingSize = 0;
                config.world_randomBorderSize = 0.1;    
                config.qteam_epochMax = 1500;
                config.qteam_epochConvergeTicks = 20000;
            else
                disp('12 robots!');
                config.numTest = 300;
                config.numRun = 1;
                config.numIterations = 15000;
                config.numRobots = 12;
                config.numObstacles = 4;
                config.numTargets = 12;    
                config.lalliance_tmax = 18000;
                config.lalliance_tmin = 17700;
                config.lalliance_failureTau = 9000;
                config.lalliance_acquiescence = 7000;
                config.lalliance_confidenceFactor = 50; %The percentage we value of distance over tau
                config.qteam_epochMax = 1500;
                config.qteam_epochConvergeTicks = 20000;
            end %End robotNum if
            
            %%Set noise parameter
            if(noiseNum == 1 )
                config.robot_NoiseLevel = 0;
            elseif(noiseNum == 2  )
                config.robot_NoiseLevel = 0.05;
            elseif(noiseNum == 3)
                config.robot_NoiseLevel = 0.1;
            elseif (noiseNum == 4)
                config.robot_NoiseLevel = 0.2;
            elseif(noiseNum == 5)
                config.robot_NoiseLevel = 0.4;
            end %end noiseNum if
            disp(['Noise: ',num2str(config.robot_NoiseLevel)]);
            
            %%Set particle filter params
            if(pf == 2)
                disp('Partile Filter On');
                config.particle_Used = 1;
            else
                disp('Partile Filter Off');
                config.particle_Used = 0;
            end
            %config.particle_ResampleNoiseSTD = 0.1; OLD - go back if bad:
            config.particle_ResampleNoiseSTD = 0.02 + config.robot_NoiseLevel/10 ;
            config.particle_ControlStd = 0.01;
            config.particle_SensorStd  = config.robot_NoiseLevel + 0.05;
            config.particle_Number = 35;
            config.particle_PruneNumber = 7;           

            % Set team learning parameters
            % 2 = L-Alliance
            % All others removed
            if(teamLearning == 2)
                disp('L-Alliance');
                config.cisl_type= teamLearning;
                config.lalliance_useDistance = 1;
            else
                error('Improper team learning.');
            end %end teamLearning if

            %Set crowd sourcing parameters
            if(crowd == 1)
                disp('Crowdsourcing On');
                config.use_hal = 1;
            else
                disp('Crowdsourcing Off');
                config.use_hal=0;
            end %end crowd if
            
            %Set Advice Exchange parameters
            if(adv == 1)
                disp('Advice Exchange Off');
                config.advexc_on = 0;
            elseif(adv == 2)
                disp('Advice Exchange On');
                config.advexc_on = 1;
            elseif(adv == 3)
                disp('Advice Exchange More Aggressive');
                config.advexc_on = 1;
                %config.advice_eta = 0.5; %moving average (more bias local performance)
                %config.advice_delta = 0.3; %advice threshold penalty (70% advisor is better) 
                %config.advice_eta = 0.1; %moving average (more bias local performance)
                %config.advice_delta = 0; %advice threshold penalty (70% advisor is better)                
                
                %AAA#_ settings here (under aggressive Advice Exchange)
                %config.advice_eta = 0.7; %moving average (% bias towards past performance)
                %config.advice_delta = 0.3; %advice threshold (percent advisor is better)
                %config.advice_threshold = 1.3; %only take advice in a state, if their advice is much better than our own
                %config.adv_epochMax = 100;

                %BBB#_ settings here (under aggressive Advice Exchange)
                config.advice_eta = 0.5; %moving average (% bias towards past performance) [0 1[
                config.advice_delta = 0.5; %advice threshold (percent advisor is better)
                config.advice_threshold = 1.1; %only take advice in a state, if their advice is much *somewhat* better than our own
                config.advice_row = 0.9; %Learn who is good recently
                config.adv_epochMax = 75; %short epoch for fast
            end %end Advice Exchange if
            
            %Set inverse learning parameters
            if(inv == 1)
                disp('Inv Rwd On');
            else
                disp('Inv Rwd Off');
            end %end inverse learning if            
            
            %Set coop parameters
            if(coop == 1)
                disp('Physical Coop On');
                config.simulation_Realism = 2;
                config.lalliance_useCooperation = 1;
                config.lalliance_useCooperationLimit = 0;
            elseif(coop ==2)
                disp('Physical Coop Off');
                config.simulation_Realism = 0;
                config.lalliance_useCooperation = 0;
                config.lalliance_useCooperationLimit = 0;
            else
                disp('Physical Coop Cautious');
                config.simulation_Realism = 2;
                config.lalliance_useCooperation = 1;
                config.lalliance_useCooperationLimit = 1;
            end %end coop if     
            
            if(timeLimitOff == 1)
                disp('Time Limit Largeish');
               %config.numIterations = 10000000000000;
               %config.numIterations = 100000000;
                config.numIterations = 100000;
                config.lalliance_acquiescence = 20000; %long acquiescence limit                
            else
                disp('Time Limit Forced On');
                config.numIterations = 15000;
            end %end time limit if
        end %end GetConfiguration function
        
    end %end methods
    
end

