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
    target_;     % Struct containing data about the current target
                 %   x - X position (estimated)
                 %   y - Y position (estimated)
                 %   Id - Target number
                 %   carrying - Flag for if the robot is carrying the
    obstacles_;  % Struct array containing all obstacle data
                 %   x - X position (estimated)
                 %   y - Y position (estimated)
    goal_;       % Struct containing goal data
                 %   x - X position (estimated)
                 %   y - Y position (estimated)
    terrain_;    % Struct containing terrain data
                 %   x - X position of centre(estimated)
                 %   y - Y position of centre (estimated)
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
    
    function update(this, world_state)
      if(this.config_.noise.sigma == 0)
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
        for i = 1:this.config_.scenario.num_obstacles
          this.obstacles_(i).x = world_state.obstacles_(i).x;
          this.obstacles_(i).y = world_state.obstacles_(i).y;
        end
        
        % Goal data
        this.goal_.x = world_state.goal_.x;
        this.goal_.y = world_state.goal_.y;
        
        % Terrain data
        this.terrain_.x = world_state.terrain_.x;
        this.terrain_.y = world_state.terrain_.y;
      else
        % Update with particle filter
        % TODO
      end
    end
    
  end
  
end

