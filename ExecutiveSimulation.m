classdef ExecutiveSimulation < handle
    % EXECUTIVESIMULATION - Responsible for running a complete simulation
    
    % The executive simulation class will instantiate the world, and all
    % the robots to be used, and will step through iterations of the
    % simulation, making the robots act, and update the physics. 
    % 
    % Must be provided with a configuration object, which it will then
    % pass to all other classes.
    %
    % Has capabilities to run a single run or consecutive runs, and also
    % to save the data after each run.
    % 
    % This should be the primary class used to start a simulation. The
    % miminum necessary to run a simulation is as follows:
    %
    %     config = Configuration();
    %     Simulation=ExecutiveSimulation(config);
    %     Simulation.initialize();
    %     Simulation.run();
    
    properties     
        config_ = [];           % Configration object
        robots_ = [];           % Array of all robots
        num_robots_ = [];       % From configuration
        max_iterations_ = [];   % From configuration
        world_state_ = [];      % Current world state
        sim_time_ = [];         % Duration of each simulation
        physics_ = [];          % Physics object, responsible for making changes in the worldstate
        simulation_data_ = [];  % Struct for saving metrics about each run
        team_learning_ = [];    % Object for team learning agent
        advice_database_ = [];  % Object containing advice database
        advice_data_ = [];      % Struct for saving advice performance data
        
    end
    
    methods (Access = public)
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %   Constructor
        %
        %   Loads in the configuration
        %
        %   INPUTS
        %   config = Configuration object
        
        function this = ExecutiveSimulation(config)
            this.config_ = config;
            this.simulation_data_ = struct;
            this.advice_data_ = struct;
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %   initialize
        %
        %   Performs the initialization necessary before a simulation can
        %   be started. Loads settings from the configuration, and
        %   instantiates the world state, the robots, and the physics
        %   engine.
        
        function initialize(this)
            % Set configuration parameters
            this.num_robots_ = this.config_.numRobots;
            this.max_iterations_ = this.config_.max_iterations;
            
            % Create the intial world state
            this.world_state_=WorldState(this.config_);
            
            % Create the robots, and add listener for handle request
            this.robots_ = Robot.empty(1,0);
            
            for id = 1:this.num_robots_;
                this.robots_(id, 1) = Robot(id, this.config_, this.world_state_);
                if this.num_robots_ > 1
                    addlistener(this.robots_(id, 1).individual_learning_.advice_, 'RequestRobotHandle', @(src, event)this.handleRequestRobotHandle(src));
                end
            end
                                    
            % Create the team learning
            this.team_learning_ = TeamLearning(this.config_);
                        
            %Initialize physics engine
            this.physics_ = Physics(this.config_);
            
            disp('Simulation initialized.');
            disp(['Running ', sprintf('%d', this.num_robots_), ' robots.']);
            disp(['Max iterations: ', sprintf('%d', this.max_iterations_), '.']);
            disp(' ');
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %   handleRequestRobotHandle
        %
        %   Receives requests for a robot handle and returns the
        %   ExecutiveSimulation cell containing all robot handles.
        %   Used by advice mechanism.
        
        function handleRequestRobotHandle(this, src)
            src.all_robots_ = this.robots_;
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %   loadLearningData
        %
        %   Promts user to select a file containing the utility tables, 
        %   experience tables, and team learning data to be loaded, which 
        %   will then be assigned to each robot in order.
        %   
        %   Tables must be in a single cell array.
        
        function loadLearningData(this)
            % Ask to select the file with utility tables
            disp('Please select the utility tables to be loaded');
            [file_name, path_name] = uigetfile;
            q_tables = load([path_name, file_name]);
            
            % Ask to select the file with experience tables
            disp('Please select the experience tables to be loaded');
            [file_name, path_name] = uigetfile;
            exp_tables = load([path_name, file_name]);
                                    
            for id = 1:this.num_robots_;
                this.robots_(id,1).individual_learning_.q_learning_.q_table_ = q_tables.q_tables{id, 1};
                this.robots_(id,1).individual_learning_.q_learning_.exp_table_ = exp_tables.exp_tables{id, 1};
            end
            
            if (strcmp(this.config_.task_allocation, 'l_alliance'))
                % Ask to select the file with L-Alliance data
                disp('Please select the L-Alliance data to be loaded');
                [file_name, path_name] = uigetfile;
                l_alliance_data = load([path_name, file_name]);
                
                this.team_learning_.l_alliance_.data_ = l_alliance_data.l_alliance_data;
                this.team_learning_.l_alliance_.reset();
            end
            
            disp('Utility and experience tables loaded.');
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %   run
        %   
        %   Steps throuhg iterations until all tasks are complete, or the
        %   max amount of iterations has been reached. Calls upon the robot
        %   class to get/make actions, calls upon the physics class to make
        %   the changes in the world, and uses the Graphics function for
        %   displaying the simulation.
        
        function run(this)     
            % Step through iterations
            while (this.world_state_.iterations_ < this.max_iterations_ && ~this.world_state_.GetConvergence())
                
                % Update tasks from team learning
                this.team_learning_.getTasks(this.robots_);
                % Update and learn from task allocation
                this.team_learning_.learn(this.robots_);
                
                for i=1:this.num_robots_
                    % Get the action for this robot
                    this.robots_(i,1).getAction();
                    % Make the action for this robot
                    this.robots_(i,1).act(this.physics_);
                    % Make this robot learn from its action
                    this.robots_(i,1).learn();
                end
                
                % Display live graphics, if requested in configuration
                Graphics(this.config_, this.world_state_, this.robots_);
                
                this.world_state_.iterations_ = this.world_state_.iterations_ + 1;
            end 
                        
            % Call graphics for displaying tracks, if requested in configuration
            Graphics(this.config_, this.world_state_, this.robots_);            
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %   consecutiveRuns
        %   
        %   Will consecutively call the run method, for the prescribed
        %   number of times. After each run the world/robots will be reset,
        %   but all learning data will be retained.
        %
        %   The simulation must be initialized before use
        %
        %   INPUTS:
        %   num_runs = The number of consecutive runs to be performed
        %   save_data = Boolean type to indicate if data should be saved
        %   sim_name = String with name of the test, used for saving data
        
        function consecutiveRuns(this, num_runs, sim_name)
            for run=1:num_runs
                tic
                disp(['Mission ', sprintf('%d', run), ' started.'])
                this.run();
                disp(['Mission ', sprintf('%d', run), ' complete.'])
                disp(['Number of iterations: ',sprintf('%d', this.world_state_.iterations_)])
                time = toc;
                disp(' ');
                                
                % Save the data from this run (if desired)
                if (this.config_.save_simulation_data)
                    this.updateSimData(time, run);
                end
                this.resetForNextRun();
            end
            
            % Save simulation tracking metrics (if desired)
            this.saveSimulationData(sim_name);
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %   resetForNextRun
        %
        %   Resets all the necessary data for performing consecutive runs,
        %   while maintatining learning data
        
        function resetForNextRun (this)
            % Create a new world state
            this.world_state_=WorldState(this.config_);
            
            % Reset the team learning layer
            this.team_learning_.resetForNextRun();
            
            % Reset the robots
            for id = 1:this.num_robots_;
                this.robots_(id,1).resetForNextRun(this.world_state_);
            end
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %   updateSimData
        %
        %   Will add metrics from the previous run into the class
        %   properties, to be saved later.
        %
        %   An struct is formed with:
        %       -Iterations
        %       -Time
        %       -Average Reward
        %       -Average Effort
        %
        %   INPUTS:
        %   time = Simulation time in seconds
        %   run = Run number in this simulation
        
        function updateSimData (this, time, run)            
            % Add iterations and time
            this.simulation_data_.iterations(run) = this.world_state_.iterations_;
            this.simulation_data_.time(run) = time;
            
            % Get reward and effort from robot state
            % (Need to manually reset effort counter)
            avg_reward = zeros(1, this.num_robots_);
            effort = zeros(1, this.num_robots_);
            for i = 1:this.num_robots_
                avg_reward(i) = sum(this.robots_(i, 1).individual_learning_.epoch_reward_)/this.world_state_.iterations_;
                effort(i) = this.robots_(i, 1).robot_state_.effort_;
                this.robots_(i, 1).robot_state_.effort_ = 0;
            end
            this.simulation_data_.avg_reward(run) = sum(avg_reward)/this.num_robots_;
            this.simulation_data_.avg_effort(run) = sum(effort)/this.num_robots_;
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %   saveSimulationData
        %
        %   Saves the simulation tracking metrics in the directory
        %   indicated.
        %
        %   INPUTS
        %   sim_name = Folder to save data in
        
        function saveSimulationData (this, sim_name)
            
            if(this.config_.save_simulation_data || this.config_.save_IL_data || this.config_.save_TL_data || this.config_.save_advice_data)
                if ~exist(['results/', sim_name], 'dir')
                    mkdir('results', sim_name);
                end
                config = this.config_;
                save(['results/', sim_name, '/', 'configuration'], 'config');
            end
            
            % Save simulation data
            if(this.config_.save_simulation_data)
                simulation_data = this.simulation_data_;
                save(['results/', sim_name, '/', 'simulation_data'], 'simulation_data');
            end
                        
            % Save individual learning data
            if(this.config_.save_IL_data)
                individual_learning_data = cell(this.num_robots_, 1);
                for i = 1:this.num_robots_
                    individual_learning_data{i}.state_data = this.robots_(i, 1).individual_learning_.state_data_;
                    individual_learning_data{i}.q_table = this.robots_(i, 1).individual_learning_.q_learning_.q_table_;
                    individual_learning_data{i}.exp_table = this.robots_(i, 1).individual_learning_.q_learning_.exp_table_;
                end
                save(['results/', sim_name, '/', 'individual_learning_data'], 'individual_learning_data');
            end
            
            % Save team learning data
            if(this.config_.save_TL_data)
                if (strcmp(this.config_.task_allocation, 'l_alliance'))
                    l_alliance_data = this.team_learning_.l_alliance_.data_;
                    save(['results/', sim_name, '/', 'l_alliance_data'], 'l_alliance_data');
                end
            end
            
            % Save advice data
            if(this.config_.save_advice_data)
                if (this.config_.advice_on)
                    advice_data = cell(this.num_robots_, 1);
                    for i = 1:this.num_robots_
                        advice_data{i} = this.robots_(i, 1).individual_learning_.advice_.advice_data_;
                        advice_data{i}.q_table = this.robots_(i, 1).individual_learning_.advice_.q_learning_.q_table_;
                        advice_data{i}.exp_table = this.robots_(i, 1).individual_learning_.advice_.q_learning_.exp_table_;
                    end
                    save(['results/', sim_name, '/', 'advice_data'], 'advice_data');
                end
            end
        end
                
    end
    
end

