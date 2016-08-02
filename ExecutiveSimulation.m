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
            
            % Create the robots
            this.robots_ = Robot.empty(1,0);
            for id = 1:this.num_robots_;
                this.robots_(id,1) = Robot(id, this.config_, this.world_state_);
            end
            
            % Create the team learning
            this.team_learning_ = TeamLearning(this.config_);
            
            % Create the advice mechanism (if required)
            if (this.config_.advice_on)
                this.advice_database_ = AdviceDatabase(this.config_, this.robots_);
            end
            
            %Initialize physics engine
            this.physics_ = Physics(this.config_);
            
            disp('Simulation initialized.');
            disp(['Running ', sprintf('%d', this.num_robots_), ' robots.']);
            disp(['Max iterations: ', sprintf('%d', this.max_iterations_), '.']);
            disp(' ');
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
                this.robots_(id,1).individual_learning_.q_learning_.quality_.q_table_ = q_tables.q_tables{id, 1};
                this.robots_(id,1).individual_learning_.q_learning_.quality_.exp_table_ = exp_tables.exp_tables{id, 1};
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
        
        function consecutiveRuns(this, num_runs, save_data, sim_name)
            for run=1:num_runs
                tic
                disp(['Mission ', sprintf('%d', run), ' started.'])
                this.run();
                disp(['Mission ', sprintf('%d', run), ' complete.'])
                disp(['Number of iterations: ',sprintf('%d', this.world_state_.iterations_)])
                time = toc;
                disp(' ');
                                
                % Save the data from this run (if desired)
                if (save_data)
                    this.saveSimulationData(sim_name, time, run);
                end
                
                % Don't reset if it is the last run (data may be useful)
                if (run ~= num_runs)
                    this.resetForNextRun();
                end
            end
            
            if (save_data)
                % Save our learned utility tables for each robot
                this.saveLearningData(sim_name);
            end
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
            
            % Reset the advice (if necessary)
            if (this.config_.advice_on)
                this.advice_database_.epochFinished();
            end
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %   saveSimulationData
        %
        %   Will save data from the simulation to the results 
        %   folder. A folder will be created with the inputted sim_name, 
        %   and the current data.
        %
        %   An structu is saved with:
        %       -Iterations
        %       -Time
        %       -Total Effort
        %       -Average Reward
        %
        %   INPUTS:
        %   sim_name = String with test name, to be appended to file name
        %   time = Simulation time in seconds
        %   run = Run number in this simulation
        
        function saveSimulationData (this, sim_name, time, run)
            % Create new directory if needed
            if ~exist(['results/', sim_name], 'dir')
                mkdir('results', sim_name);
            end
            
            % Add iterations and time
            this.simulation_data_.iterations(run) = this.world_state_.iterations_;
            this.simulation_data_.time(run) = time;
            
            % Get effort and reward from robot state
            total_effort = zeros(1, this.num_robots_);
            avg_reward = zeros(1, this.num_robots_);
            total_reward = zeros(1, this.num_robots_);
            for i = 1:this.num_robots_
                total_effort(1, i) = this.robots_(i, 1).robot_state_.effort_;
                
                % Need indices for reward values 
                reward_start = this.robots_(i, 1).individual_learning_.prev_learning_iterations_ + 1;
                reward_end = this.robots_(i, 1).individual_learning_.learning_iterations_;
                
                avg_reward(:, i) = sum(this.robots_(i, 1).individual_learning_.reward_data_(reward_start:reward_end, 1))/this.world_state_.iterations_;
                total_reward(1, i) = sum(this.robots_(i, 1).individual_learning_.reward_data_(reward_start:reward_end, 1));
            end
            
            % Store effort and reward
            this.simulation_data_.avg_reward(run) = sum(avg_reward)/this.num_robots_;
            if (run <= 1)
                this.simulation_data_.total_effort(run) = sum(total_effort);
                this.simulation_data_.total_reward(run) = sum(total_reward);
            else
                this.simulation_data_.total_effort(run) = this.simulation_data_.total_effort(run - 1) + sum(total_effort);
                this.simulation_data_.total_reward(run) = this.simulation_data_.total_reward(run - 1) + sum(total_reward);
            end
            
            % Have to make copies of variables in order to save
            config = this.config_;
            simulation_data = this.simulation_data_;
            save(['results/', sim_name, '/', 'configuration'], 'config');
            save(['results/', sim_name, '/', 'simulation_data'], 'simulation_data');
            
            % Get advice tracking metrics (if used)
            if (this.config_.advice_on)
                for i = 1:this.num_robots_
                    this.advice_data_.advised_actions(i, run) = this.robots_(i, 1).individual_learning_.advice_.advised_actions_;
                    this.advice_data_.total_actions(i, run) = this.robots_(i, 1).individual_learning_.advice_.total_actions_;
                    this.advice_data_.advised_actions_ratio(i, run) = this.robots_(i, 1).individual_learning_.advice_.advised_actions_ / ...
                        this.robots_(i, 1).individual_learning_.advice_.total_actions_;
                    this.advice_data_.cond_a_true_count(i, run) = this.robots_(i, 1).individual_learning_.advice_.cond_a_true_count_;
                    this.advice_data_.cond_b_true_count(i, run) = this.robots_(i, 1).individual_learning_.advice_.cond_b_true_count_;
                    this.advice_data_.cond_c_true_count(i, run) = this.robots_(i, 1).individual_learning_.advice_.cond_c_true_count_;
                end
                advice_data = this.advice_data_;
                save(['results/', sim_name, '/', 'advice_data'], 'advice_data');
            end
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %   saveLearningData
        %
        %   Saves the utility table and experience for each robot into a 
        %   cell array, as well as the team learning data
        %
        %   INPUTS
        %   sim_name = String with test name, to be appended to file name
        
        function saveLearningData (this, sim_name)
            % Add utility table for each robot to cell array
            q_tables = cell(this.num_robots_, 1);
            exp_tables = cell(this.num_robots_, 1);
            for id = 1:this.num_robots_;
                q_tables{id} = this.robots_(id,1).individual_learning_.q_learning_.quality_.q_table_;
                exp_tables{id} = this.robots_(id,1).individual_learning_.q_learning_.quality_.exp_table_;
            end
            
            if (strcmp(this.config_.task_allocation, 'l_alliance'))
                % Get L-Alliance data array
                l_alliance_data = this.team_learning_.l_alliance_.data_;
                save(['results/', sim_name, '/', 'l_alliance_data'], 'l_alliance_data');
                
            end
            
            save(['results/', sim_name, '/', 'q_tables'], 'q_tables');
            save(['results/', sim_name, '/', 'exp_tables'], 'exp_tables');
            disp('Utility tables saved.');
        end
        
    end
    
end

