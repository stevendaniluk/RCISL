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
            
            %Initialize physics engine
            this.physics_ = Physics(this.config_);
            
            disp('Simulation initialized.');
            disp(['Running ', sprintf('%d', this.num_robots_), ' robots.']);
            disp(['Max iterations: ', sprintf('%d', this.max_iterations_), '.']);
            disp(' ');
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
            while (this.world_state_.iterations < this.max_iterations_ && this.world_state_.GetConvergence() < 2)
                for i=1:this.num_robots_
                    % Get the action for this robot
                    this.robots_(i,1).getAction();
                    % Make the action for this robot
                    this.robots_(i,1).act();
                    % Run one cycle of world physics
                    this.physics_.runCycle(this.world_state_);
                    % Make this robot learn from its action
                    this.robots_(i,1).learn();
                end

                % Display live graphics, if requested in configuration
                Graphics(this.config_, this.world_state_, this.robots_);
                
                this.world_state_.iterations = this.world_state_.iterations + 1;
            end % end while 
            
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
        %   INPUTS
        %   num_runs = The number of consecutive runs to be performed
        %   save_data = Boolean type to indicate if data should be saved
        %   sim_name = String with name of the test, used for saving data
        
        function consecutiveRuns(this, num_runs, save_data, sim_name)
            % Initialize the simulation
            this.initialize();
            
            % Make the runs
            for i=1:num_runs
                tic
                disp(['Mission ', sprintf('%d', i), ' started.'])
                this.run();
                disp(['Mission ', sprintf('%d', i), ' complete.'])
                disp(['Number of iterations: ',sprintf('%d', this.world_state_.iterations)])
                toc
                disp(' ');
                                
                % Save the data from this run (if desired)
                if (save_data)
                    this.saveData(sim_name);
                end
                
                % Don't reset if it is the last run (data may be useful)
                if (i ~= num_runs)
                    this.resetForNextRun();
                end
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
            
            % Reset the robots
            for id = 1:this.num_robots_;
                this.robots_(id,1).resetForNextRun(this.world_state_);
            end
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %   saveData
        %
        %   Will save data from the simulation to the results folder. A
        %   folder will be created with the inputted sim_name, and the
        %   current data.
        %
        %   A cell array is saved, where:
        %       Column 1 = iterations
        %       Columns 2:end = Individual learning data [alpha, gamma, 
        %                       experience, quality, reward, visited states]
        %
        %   INPUTS
        %   sim_name = String with test name, to be appended to file name
        
        function saveData (this, sim_name)
            % Create new directory if needed
            if ~exist(['results/', [sim_name, '-', date]], 'dir')
                mkdir('results', [sim_name, '-', date]);
            end
            
            % Add iterations
            [rows, ~] = size(this.simulation_data_);
            this.simulation_data_{rows + 1, 1} = this.world_state_.iterations;
            
            % Add learning data for each robot
            for id = 1:this.num_robots_;
                this.simulation_data_{rows + 1, id + 1} = this.robots_(id,1).individual_learning_.q_learning_.learning_data_;
            end
            
            % Have to make copies of variables in order to save
            config = this.config_;
            simulation_data = this.simulation_data_;
            save(['results/', sim_name, '-', date, '/', 'configuration'], 'config');
            save(['results/', sim_name, '-', date, '/', 'simulation_data'], 'simulation_data');
        end
        
    end
    
end

