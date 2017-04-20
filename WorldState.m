classdef WorldState < handle
  % WORLDSTATE - Contains all information about the world.
  %
  % A single instance of WorldState will exist for each simulation, and it
  % will contain all information about the state of every object in the
  % world (i.e. pose, status, etc.). 
  %
  % All pose data contains the true pose of that object (a robto may have
  % estimated poses of each object in the world).
  %
  % All WorldState data is manipulated by other classes. The only methods
  % to interact with WorldState are the randomizeState mathod, which
  % randomizes the initial positions of all items (to be used when creating
  % a new world), and the getMissionCompletion method, which simply returns
  % true once the mission is complete.
  
  properties
    config_;     % Configuration object
    mission_;    % Structure containing data about the mission
                 %   iters - Counter for iterations
                 %   complete - Flag for if the mission is completed
                 %   targets_returned - Number of targerts return so far
    robots_;     % Structure array containing all data for each robots
                 %   x - X position (true)
                 %   y - Y position (true)
                 %   theta - Yaw angle (true)
    targets_;    % Structure array containing all data for each target
                 %   x - X position (true)
                 %   y - Y position (true)
                 %   type - String with either "light" or "heavy"
                 %   returned - Flag for if the target has been returned
    obstacles_;  % Structure array containing all data for each obstacle
                 %   x - X position (true)
                 %   y - Y position (true)
    goal_;       % Structure containing data for the goal
                 %   x - X position (true)
                 %   y - Y position (true)
    terrain_;    % Structure containing data for the rough terrain
                 %   x - X position of centre (true)
                 %   y - Y position of centre (true)
  end
  
  methods
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %   Constructor
    %
    %   Loads a configuration, then signs all loaded parameters and
    %   saves all initial parameters
    
    function this = WorldState(config)
      this.config_ = config;
      
      % Initialize mission information
      this.mission_.iters = 0;
      this.mission_.complete = false;
      this.mission_.targets_returned = 0;
      
      % Randomize the positions and orientatons for all objects
      this.randomizeState();
      
      % Initialize target properties
      for i=1:this.config_.scenario.num_targets
        % Loop back to first type, if there aren't enough defined
        index = mod(i - 1, length(this.config_.scenario.target_types)) + 1;
        this.targets_(i).type = this.config_.scenario.target_types{index};
        this.targets_(i).returned = false;
      end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %   randomizeState
    %
    %   Begin to form random positions by discritizing the world,
    %   getting all the unique positions, then selecting enough
    %   positions that are valid, and do not violate the random
    %   position padding dictated in the configuration
    
    function randomizeState(this)
      % Total potential positions
      num_x_pos = (this.config_.scenario.world_width - 2*this.config_.scenario.random_border_padding)/this.config_.scenario.grid_size - 1;
      num_y_pos = (this.config_.scenario.world_height - 2*this.config_.scenario.random_border_padding)/this.config_.scenario.grid_size - 1;
      
      % Vectors of each potential positions in each direction
      x_grid = linspace(this.config_.scenario.random_border_padding, (this.config_.scenario.world_width - this.config_.scenario.random_border_padding), num_x_pos);
      y_grid = linspace(this.config_.scenario.random_border_padding, (this.config_.scenario.world_height - this.config_.scenario.random_border_padding), num_y_pos);
      
      % Total amount of valid positions we need
      num_positions = this.config_.scenario.num_robots + this.config_.scenario.num_targets + this.config_.scenario.num_obstacles + 1;
      
      % Form empty arrays
      positions = zeros(num_x_pos * num_y_pos, 2);
      valid_positions = zeros(num_positions, 2);
      
      % Put all potential position combinations in an ordered array
      for i=1:num_x_pos
        for j=1:num_y_pos
          positions((i-1)*num_y_pos + j, 1) = x_grid(i);
          positions((i-1)*num_y_pos + j, 2) = y_grid(j);
        end
      end
      
      valid_positions_found = false;
      
      while (~valid_positions_found)
        % Take random permutations of positions in each direction
        random_positions = positions(randperm(num_x_pos * num_y_pos), :);
        
        % Loop through assigning random positions, while checking if any new random
        % positions conflict with old ones.
        index = 1;
        valid_positions(index,:) = random_positions(index,:);
        
        for i=1:num_positions
          % If we've checked all positions, break and generate
          % new ones
          if (index > num_x_pos*num_y_pos)
            break;
          end
          
          % Loop through random positions until one is valid
          position_valid = false;
          while(~position_valid)
            % Separation distance
            x_delta_dist = abs(valid_positions(1:i, 1) - random_positions(index, 1));
            y_delta_dist = abs(valid_positions(1:i, 2) - random_positions(index, 2));
            % Check the violations
            x_violations = x_delta_dist < this.config_.scenario.random_pos_padding;
            y_violations = y_delta_dist < this.config_.scenario.random_pos_padding;
            % Get instances where there are x and y violations
            violations = x_violations.*y_violations;
            
            if (sum(violations) == 0)
              position_valid = true;
              % Save our valid position
              valid_positions(i,:) = random_positions(index, :);
            end
            
            index = index + 1;
            % If we've checked all positions, break and generate
            % new ones
            if (index > num_x_pos*num_y_pos)
              break;
            end
          end
          % If we've checked all positions, break and generate
          % new ones
          if (index > num_x_pos*num_y_pos)
            break;
          end
        end
        
        % Only finish if we have enough positions, and haven't
        % surpassed the index
        if ((i == num_positions) && (index <= num_x_pos*num_y_pos))
          valid_positions_found = true;
        end
      end
      
      % Assign the random positions to robots, targets, obstacles,
      % and the goal, as well as random orientations
      index = 1;
      for i = 1:this.config_.scenario.num_robots
        this.robots_(i).x = valid_positions(index, 1);
        this.robots_(i).y = valid_positions(index, 2);
        this.robots_(i).theta = rand*2*pi;
        index = index + 1;
      end
      
      for i = 1:this.config_.scenario.num_targets
        this.targets_(i).x = valid_positions(index, 1);
        this.targets_(i).y = valid_positions(index, 2);
        index = index + 1;
      end
      
      for i = 1:this.config_.scenario.num_obstacles
        this.obstacles_(i).x = valid_positions(index, 1);
        this.obstacles_(i).y = valid_positions(index, 2);
        index = index + 1;
      end
      
      this.goal_.x = valid_positions(index, 1);
      this.goal_.y = valid_positions(index, 2);
      
      % Randomly place the rough terrain (can be placed anywhere)
      % Utilizes the previously formed random positions
      if(this.config_.scenario.terrain_on)
        terrain_valid = false;
        i = 1;
        while(~terrain_valid)
          temp_terrain_pos = random_positions(i, :);
          
          x_lower_valid = temp_terrain_pos(1) > 0.5*this.config_.scenario.terrain_size;
          x_upper_valid = (this.config_.scenario.world_width - temp_terrain_pos(1)) > 0.5*this.config_.scenario.terrain_size;
          y_lower_valid = temp_terrain_pos(2) > 0.5*this.config_.scenario.terrain_size;
          y_upper_valid = (this.config_.scenario.world_height - temp_terrain_pos(2)) > 0.5*this.config_.scenario.terrain_size;
          
          if(x_lower_valid && x_upper_valid && y_lower_valid && y_upper_valid)
            % Set the valid position
            this.terrain_.x = temp_terrain_pos(1);
            this.terrain_.y = temp_terrain_pos(2);
            break;
          end
          
          i = i + 1;
        end
      else
        this.terrain_.x = [];
        this.terrain_.y = [];
      end
      
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %   getMissionCompletion
    %
    %   Check if all the items have been returned to the goal area
    
    function complete = getMissionCompletion(this)
      % All targets must be returned, or max iterations reached
      if(this.mission_.targets_returned == this.config_.scenario.num_targets)
        this.mission_.complete = true;
        disp('Mission complete: All items returned')
      elseif(this.mission_.iters >= this.config_.scenario.max_iterations)
        this.mission_.complete = true;
        disp('Mission complete: Max iterations reached')
      end
      
      complete = this.mission_.complete;
    end
    
  end
  
end

