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
        simulation_data_ = [];  % Cells for saving certain metrics about each run
        team_learning_ = [];    % Object for team learning agent
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
            
            % Ask to select the file with L-Alliance data
            disp('Please select the L-Alliance data to be loaded');
            [file_name, path_name] = uigetfile;
            l_alliance_data = load([path_name, file_name]);
            
            this.team_learning_.l_alliance_.data_ = l_alliance_data.l_alliance_data;
            this.team_learning_.l_alliance_.reset();
            
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
            for i=1:num_runs
                tic
                disp(['Mission ', sprintf('%d', i), ' started.'])
                this.run();
                disp(['Mission ', sprintf('%d', i), ' complete.'])
                disp(['Number of iterations: ',sprintf('%d', this.world_state_.iterations_)])
                time = toc;
                disp(' ');
                                
                % Save the data from this run (if desired)
                if (save_data)
                    this.saveSimulationData(sim_name, time);
                end
                
                % Don't reset if it is the last run (data may be useful)
                if (i ~= num_runs)
                    this.resetForNextRun();
                end
            end
            
            % Save our learned utility tables for each robot
            this.saveLearningData(sim_name);
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
        %   saveSimulationData
        %
        %   Will save learningdata from the simulation to the results 
        %   folder. A folder will be created with the inputted sim_name, 
        %   and the current data.
        %
        %   An array is saved, where:
        %       Column 1 = Iterations
        %       Column 2 = Time
        %       Column 3 = Total Effort
        %       Column 4 = Average Reward
        %
        %   INPUTS:
        %   sim_name = String with test name, to be appended to file name
        %   time = Simulation time in seconds
        
        function saveSimulationData (this, sim_name, time)
            % Create new directory if needed
            if ~exist(['results/', sim_name], 'dir')
                mkdir('results', sim_name);
            end
            
            % Add iterations and time
            [rows, ~] = size(this.simulation_data_);
            this.simulation_data_(rows + 1, 1) = this.world_state_.iterations_;
            this.simulation_data_(rows + 1, 2) = time;
            
            % Get effort and reward from robot state
            effort = zeros(1, this.num_robots_);
            reward = zeros(1, this.num_robots_);
            for i = 1:this.num_robots_
                effort(1, i) = this.robots_(i, 1).robot_state_.effort_;
                
                % Need indices for reward values 
                reward_start = this.robots_(i, 1).individual_learning_.prev_learning_iterations_ + 1;
                reward_end = this.robots_(i, 1).individual_learning_.learning_iterations_;
                
                reward(:, i) = sum(this.robots_(i, 1).individual_learning_.reward_(reward_start:reward_end, 1))/this.world_state_.iterations_;
            end
            
            % Store effort and reward
            this.simulation_data_(rows + 1, 3) = sum(effort);
            this.simulation_data_(rows + 1, 4) = sum(reward)/this.num_robots_;
            
            % Have to make copies of variables in order to save
            config = this.config_;
            simulation_data = this.simulation_data_;
            save(['results/', sim_name, '/', 'configuration'], 'config');
            save(['results/', sim_name, '/', 'simulation_data'], 'simulation_data');
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
            
            % Get L-Alliance data array
            l_alliance_data = this.team_learning_.l_alliance_.data_;
            
            save(['results/', sim_name, '/', 'q_tables'], 'q_tables');
            save(['results/', sim_name, '/', 'exp_tables'], 'exp_tables');
            save(['results/', sim_name, '/', 'l_alliance_data'], 'l_alliance_data');
            disp('Utility tables saved.');
        end
        
    end
    
end

