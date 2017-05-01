classdef RobotState < handle
  % ROBOTSTATE - Contains all robot specific state data for one robot
  
  % One instance of RobotState will exist for each robot in the simulation.
  % It contains the state data for the robot itself, as well as all other
  % objects in the world as perceived by the robot (i.e. their poses
  % are estimated, and may differ from the true positions in WorldState).
  %
  % All data is updated within this class through the udpate method, with
  % the exception of the target Id and carrying flag, which are updated in
  % the TeamLearning class.
  
  properties    
    config_;     % Configuration object
    id_;         % Id number for this robot
    pose_;       % Struct containing all pose data for the robot
                 %   x - X position
                 %   y - Y position
                 %   theta - Yaw angle
                 %   pf - Particle filter
    target_;     % Struct containing data about the current target
                 %   x - X position (estimated)
                 %   y - Y position (estimated)
                 %   Id - Target number
                 %   carrying - Flag for if the robot is carrying the
                 %   pf - Particle filter
    obstacles_;  % Struct array containing all obstacle data
                 %   x - X position (estimated)
                 %   y - Y position (estimated)
                 %   pf - Particle filter
    goal_;       % Struct containing goal data
                 %   x - X position (estimated)
                 %   y - Y position (estimated)
                 %   pf - Particle filter
    terrain_;    % Struct containing terrain data
                 %   x - X position of centre(estimated)
                 %   y - Y position of centre (estimated)
                 %   pf - Particle filter
  end
  
  methods
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %   Constructor
    %
    %   INPUTS
    %   id = Robot ID number
    %   config = Configuration object
    %   world_state = WorldState object
    
    function this = RobotState(id, config, world_state)
      this.id_ = id;
      this.config_ = config;
      
      % Initialize pose to true pose
      this.pose_.x = world_state.robots_(this.id_).x;
      this.pose_.y = world_state.robots_(this.id_).y;
      this.pose_.theta = world_state.robots_(this.id_).theta;
      
      % Initialize target data
      this.target_.id = -1;
      this.target_.carrying = false;
      this.target_.x = NaN;
      this.target_.y = NaN;
      
      % Initialize obstacle data (use true position)
      for i = 1:this.config_.scenario.num_obstacles
        this.obstacles_(i).x = world_state.obstacles_(i).x;
        this.obstacles_(i).y = world_state.obstacles_(i).y;
      end
      
      % Initialize goal data (use true position)
      this.goal_.x = world_state.goal_.x;
      this.goal_.y = world_state.goal_.y;
      
      % Initialize terrain data (use true position)
      this.terrain_.x = world_state.terrain_.x;
      this.terrain_.y = world_state.terrain_.y;
      
      if(this.config_.noise.enabled && this.config_.noise.PF.enabled)
        % Initialize a particle filter for every thing being estimated
        % (target's PF gets initialized with task changes)
        this.pose_.pf = ParticleFilter(this.config_);
        this.pose_.pf.initialize(this.pose_);
        
        this.target_.pf = ParticleFilter(this.config_);
        
        this.goal_.pf = ParticleFilter(this.config_);
        this.goal_.pf.initialize(this.goal_);
        
        for i = 1:this.config_.scenario.num_obstacles
          this.obstacles_(i).pf = ParticleFilter(this.config_);
          this.obstacles_(i).pf.initialize(this.obstacles_(i));
        end
        
        if(this.config_.scenario.terrain_on)
          this.terrain_.pf = ParticleFilter(this.config_);
          this.terrain_.pf.initialize(this.terrain_);
        end
      end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %   update
    %
    %   Updates all state data. When noise is not present, the state is
    %   updated fromt he true state data contained in the WorldState
    %   object. When noise is present, the state data is updated with
    %   estimates from the particle filter.
    %
    %   INPUTS
    %   world_state = WorldState object
    %   control = Structure with trans and rotate fields for robot motion
    
    function update(this, world_state, prev_pose)
      if(~this.config_.noise.enabled)
        % Update from the true state in world_state
        
        % Robot pose
        this.pose_.x = world_state.robots_(this.id_).x;
        this.pose_.y = world_state.robots_(this.id_).y;
        this.pose_.theta = world_state.robots_(this.id_).theta;
        
        % Target data
        if(this.target_.id ~= -1)
          this.target_.x = world_state.targets_(this.target_.id).x;
          this.target_.y = world_state.targets_(this.target_.id).y;
        else
          this.target_.x = NaN;
          this.target_.y = NaN;
          this.target_.carrying = false;
        end
        
        % Obstacle data
        this.obstacles_ = world_state.obstacles_;
        
        % Goal data
        this.goal_.x = world_state.goal_.x;
        this.goal_.y = world_state.goal_.y;
        
        % Terrain data
        this.terrain_.x = world_state.terrain_.x;
        this.terrain_.y = world_state.terrain_.y;
      else
        % Add noise to each position, then estimate the state (if the
        % particle filter is being used
        
        % Noisy pose dta
        pose_noise.x = normrnd(world_state.robots_(this.id_).x, this.config_.noise.sigma_trans);
        pose_noise.y = normrnd(world_state.robots_(this.id_).y, this.config_.noise.sigma_trans);
        pose_noise.theta = normrnd(world_state.robots_(this.id_).theta, this.config_.noise.sigma_rot);
        
        % Noisy target data
        if(this.target_.id ~= -1)
          target_noise.x = normrnd(world_state.targets_(this.target_.id).x, this.config_.noise.sigma_trans);
          target_noise.y = normrnd(world_state.targets_(this.target_.id).y, this.config_.noise.sigma_trans);
        end
        
        % Noisy obbstacle data
        obstacles_noise = struct([]);
        for i = 1:this.config_.scenario.num_obstacles
          obstacles_noise(i).x = normrnd(world_state.obstacles_(i).x, this.config_.noise.sigma_trans);
          obstacles_noise(i).y = normrnd(world_state.obstacles_(i).y, this.config_.noise.sigma_trans);
        end
        
        % Noisy goal data
        goal_noise.x = normrnd(world_state.goal_.x, this.config_.noise.sigma_trans);
        goal_noise.y = normrnd(world_state.goal_.y, this.config_.noise.sigma_trans);
        
        % Noisy terrain data
        if(this.config_.scenario.terrain_on)
          terrain_noise.x = normrnd(world_state.terrain_.x, this.config_.noise.sigma_trans);
          terrain_noise.y = normrnd(world_state.terrain_.y, this.config_.noise.sigma_trans);
        end        
        
        if(this.config_.noise.PF.enabled)
          % Update with the state with the particle filter
          
          % Find control based on relative movement
          control.x = world_state.robots_(this.id_).x - prev_pose.x;
          control.y = world_state.robots_(this.id_).y - prev_pose.y;
          control.theta = world_state.robots_(this.id_).theta - prev_pose.theta;
          
          % Filtered pose data
          pose = this.pose_.pf.update(control, pose_noise);
          this.pose_.x = pose.x;
          this.pose_.y = pose.y;
          this.pose_.theta = pose.theta;
          
          % Everything else is static (except carried target), so zero controls
          null_control.x = 0;
          null_control.y = 0;
          
          % Filtered target data
          if(this.target_.id ~= -1)
            % Handle filter initialization for when task changes
            if(~this.target_.pf.initialized_)
              this.target_.pf.initialize(world_state.targets_(this.target_.id));
            end
            
            % Must account for the target moving when carrying it
            if(this.target_.carrying)
              target = this.target_.pf.update(control, target_noise);
            else
              target = this.target_.pf.update(null_control, target_noise);
            end
            
            this.target_.x = target.x;
            this.target_.y = target.y;
          end
          
          % Filtered goal data
          goal = this.goal_.pf.update(null_control, goal_noise);
          this.goal_.x = goal.x;
          this.goal_.y = goal.y;
          
          % Filtered obstacle data
          for i = 1:this.config_.scenario.num_obstacles
            obstacle = this.obstacles_(i).pf.update(null_control, obstacles_noise(i));
            this.obstacles_(i).x = obstacle.x;
            this.obstacles_(i).y = obstacle.y;
            if(isnan(obstacle.x) || isnan(obstacle.y))
              1+1;
            end
            
          end
          
          % Filtered terrain data
          if(this.config_.scenario.terrain_on)
            terrain = this.terrain_.pf.update(null_control, terrain_noise);
            this.terrain_.x = terrain.x;
            this.terrain_.y = terrain.y;
          end
        else
          % No filtering, so set the state as the noisy data
          
          % Noisy pose data
          this.pose_.x = pose_noise.x;
          this.pose_.y = pose_noise.y;
          this.pose_.theta = pose_noise.theta;
          
          % Noisy target data
          if(this.target_.id ~= -1)
            this.target_.x = target_noise.x;
            this.target_.y = target_noise.y;
          end
          
          % Noisy goal data
          this.goal_.x = goal_noise.x;
          this.goal_.y = goal_noise.y;
          
          % Noisy obstacle data
          for i = 1:this.config_.scenario.num_obstacles
            this.obstacles_(i).x = obstacles_noise(i).x;
            this.obstacles_(i).y = obstacles_noise(i).y;
          end
          
          % Noisy terrain data
          if(this.config_.scenario.terrain_on)
            this.terrain_.x = terrain_noise.x;
            this.terrain_.y = terrain_noise.y;
          end
        end
      end
    end
    
  end
  
end

