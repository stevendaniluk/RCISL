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
  %     Simulation = ExecutiveSimulation(config);
  %     Simulation.initialize();
  %     Simulation.run();
  
  properties
    config_;           % Configration object
    robots_;           % Array of Robot objetcs
    world_state_;      % WorldState object, with data about the world
    physics_;          % Physics object, responsible for making changes in the worldstate
    team_learning_;    % TeamLearning object
    simulation_data_;  % Struct for saving metrics about each run
    advice_data_;      % Struct for saving advice performance data
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
      % Create the intial world state
      this.world_state_ = WorldState(this.config_);
      
      % Create the robots, and add listener for handle request
      this.robots_ = Robot.empty(1, 0);
      
      for id = 1:this.config_.scenario.num_robots;
        this.robots_(id, 1) = Robot(id, this.config_, this.world_state_);
        if(this.config_.advice.enabled)
          addlistener(this.robots_(id, 1).individual_learning_.advice_, 'RequestRobotHandle', @(src, event)this.handleRequestRobotHandle(src));
        end
      end
      
      % Create the team learning
      this.team_learning_ = TeamLearning(this.config_);
      
      % Initialize physics engine
      this.physics_ = Physics(this.config_);
      
      disp('Simulation initialized.');
      disp(['Running ', sprintf('%d', this.config_.scenario.num_robots), ' robots.']);
      disp(['Max iterations: ', sprintf('%d', this.config_.scenario.max_iterations), '.']);
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
      src.robot_handles_ = this.robots_;
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
      while (~this.world_state_.getMissionCompletion())
        % Update tasks from team learning
        this.team_learning_.getTasks(this.robots_, this.world_state_);
        % Update and learn from task allocation
        this.team_learning_.learn(this.robots_, this.world_state_);
        
        % Make robot actions and learn
        for i=1:this.config_.scenario.num_robots
          this.robots_(i,1).act(this.world_state_, this.physics_);
        end
        
        % Display live graphics, if requested in configuration
        Graphics(this.config_, this.world_state_, this.robots_);
        
        this.world_state_.mission_.iters = this.world_state_.mission_.iters + 1;
      end
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
        disp(['Number of iterations: ',sprintf('%d', this.world_state_.mission_.iters)])
        time = toc;
        disp(' ');
        
        % Save the data from this run (if desired)
        if (this.config_.sim.save_simulation_data)
          this.updateSimData(time, run);
        end
        this.resetForNextRun();
      end
      
      % Save simulation tracking metrics (if desired)
      this.saveData(sim_name);
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %   resetForNextRun
    %
    %   Resets all the necessary data for performing consecutive runs,
    %   while maintatining learning data
    
    function resetForNextRun (this)
      % Create a new world state
      this.world_state_ = WorldState(this.config_);
      
      % Reset the team learning layer
      this.team_learning_.resetForNextRun();
      
      % Reset the robots
      for id = 1:this.config_.scenario.num_robots;
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
      this.simulation_data_.iterations(run) = this.world_state_.mission_.iters;
      this.simulation_data_.time(run) = time;
      
      % Get reward and effort from robot state
      avg_reward = zeros(1, this.config_.scenario.num_robots);
      effort = zeros(1, this.config_.scenario.num_robots);
      for i = 1:this.config_.scenario.num_robots
        avg_reward(i) = sum(this.robots_(i, 1).individual_learning_.epoch_reward_)/this.world_state_.mission_.iters;
        effort(i) = this.robots_(i, 1).effort_;
      end
      this.simulation_data_.avg_reward(run) = sum(avg_reward)/this.config_.scenario.num_robots;
      this.simulation_data_.avg_effort(run) = sum(effort)/this.config_.scenario.num_robots;
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %   saveData
    %
    %   Saves all simulation tracking metrics in the directory
    %   indicated.
    %
    %   INPUTS
    %   sim_name = Folder to save data in
    
    function saveData (this, sim_name)
      % Save configuration data
      if(this.config_.sim.save_simulation_data || this.config_.sim.save_IL_data || this.config_.sim.save_TL_data || this.config_.sim.save_advice_data)
        if ~exist(['results/', sim_name], 'dir')
          mkdir('results', sim_name);
        end
        config = this.config_;
        save(['results/', sim_name, '/', 'configuration'], 'config');
      end
      
      % Save simulation data
      if(this.config_.sim.save_simulation_data)
        simulation_data = this.simulation_data_;
        save(['results/', sim_name, '/', 'simulation_data'], 'simulation_data');
      end
      
      % Save individual learning data
      if(this.config_.sim.save_IL_data)
        individual_learning_data = cell(this.config_.scenario.num_robots, 1);
        for i = 1:this.config_.scenario.num_robots
          individual_learning_data{i}.state_data = this.robots_(i, 1).individual_learning_.state_data_;
          individual_learning_data{i}.q_table = this.robots_(i, 1).individual_learning_.q_learning_.q_table_;
          individual_learning_data{i}.exp_table = this.robots_(i, 1).individual_learning_.q_learning_.exp_table_;
        end
        save(['results/', sim_name, '/', 'individual_learning_data'], 'individual_learning_data');
      end
      
      % Save team learning data
      if(this.config_.sim.save_TL_data)
        if (strcmp(this.config_.TL.task_allocation, 'l_alliance'))
          l_alliance_data = this.team_learning_.l_alliance_.data_;
          save(['results/', sim_name, '/', 'l_alliance_data'], 'l_alliance_data');
        end
      end
      
      % Save advice data
      if(this.config_.sim.save_advice_data)
        if (this.config_.advice.enabled)
          advice_data = cell(this.config_.scenario.num_robots, 1);
          for i = 1:this.config_.scenario.num_robots
            advice_data{i} = this.robots_(i, 1).individual_learning_.advice_.advice_data_;
            if(strcmp(this.config_.advice.mechanism, 'advice_enhancement'))
              advice_data{i}.q_table = this.robots_(i, 1).individual_learning_.advice_.q_learning_.q_table_;
              advice_data{i}.exp_table = this.robots_(i, 1).individual_learning_.advice_.q_learning_.exp_table_;
            end
          end
          save(['results/', sim_name, '/', 'advice_data'], 'advice_data');
        end
      end
    end
    
  end
  
end

