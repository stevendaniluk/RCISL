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
    %   and getting a list of all possible unique positions. Features are
    %   added in the following fashion:
    %     -Place the terrain first, restricting it to be within the world
    %      boundaries (plus padding), then remove any possible positions
    %      from the list that are too close to or within the terrain
    %     -Place goal zone, ensuring none of the goal area is within the
    %      rough terrain, and it is within world bounds, then remove any
    %      possible positions from the list that are inside or too close to
    %      the goal area
    %     -Place each obstacle, checkign that it is not too close to
    %      terrain or goal area, then remove any positions from the list
    %      that are too close too the obstacle
    %     -Place each robot at a random position (all remaining positions
    %      are valid, then remove that position from the list, as well as
    %      positions too close to the robot
    %     -Place each item at a random position (all remaining positions
    %      are valid, then remove that position from the list, as well as
    %      positions too close to the item
    
    function randomizeState(this)
      % Total potential positions
      num_x_pos = (this.config_.scenario.world_width - 2*this.config_.scenario.random_border_padding)/this.config_.scenario.grid_size - 1;
      num_y_pos = (this.config_.scenario.world_height - 2*this.config_.scenario.random_border_padding)/this.config_.scenario.grid_size - 1;
      
      % Vectors of each potential positions in each direction
      x_grid = linspace(this.config_.scenario.random_border_padding, (this.config_.scenario.world_width - this.config_.scenario.random_border_padding), num_x_pos);
      y_grid = linspace(this.config_.scenario.random_border_padding, (this.config_.scenario.world_height - this.config_.scenario.random_border_padding), num_y_pos);
      
      % Form empty arrays
      positions = zeros(num_x_pos * num_y_pos, 2);
      
      % Put all potential position combinations in an ordered array
      for i=1:num_x_pos
        for j=1:num_y_pos
          positions((i-1)*num_y_pos + j, 1) = x_grid(i);
          positions((i-1)*num_y_pos + j, 2) = y_grid(j);
        end
      end
      
      attempt_count = 0;
      valid_positions_found = false;
      while (~valid_positions_found)
        if(attempt_count > 10)
          warning('Unable to find valid combination of positions for all scenario features. Try adjusting padding size');
          return;
        end
        attempt_count = attempt_count + 1;
        
        % Take random permutations of positions in each direction
        random_positions = positions(randperm(num_x_pos * num_y_pos), :);
        
        % Defualt to true, will set false if violations occur
        valid_positions_found = true;
        
        % Place the rough terrain first
        if(this.config_.scenario.terrain_on)
          if(this.config_.scenario.terrain_centred)
            this.terrain_.x = 0.5*this.config_.scenario.world_width;
            this.terrain_.y = 0.5*this.config_.scenario.world_height;
          else
            terrain_valid = false;
            i = 1;
            while(~terrain_valid)
              temp_terrain_pos = random_positions(i, :);
              
              x_lower_valid = temp_terrain_pos(1) > (0.5*this.config_.scenario.terrain_size + this.config_.scenario.random_border_padding);
              x_upper_valid = (this.config_.scenario.world_width - this.config_.scenario.random_border_padding - temp_terrain_pos(1)) > 0.5*this.config_.scenario.terrain_size;
              y_lower_valid = temp_terrain_pos(2) > (0.5*this.config_.scenario.terrain_size + this.config_.scenario.random_border_padding);
              y_upper_valid = (this.config_.scenario.world_height - this.config_.scenario.random_border_padding - temp_terrain_pos(2)) > 0.5*this.config_.scenario.terrain_size;
              
              if(x_lower_valid && x_upper_valid && y_lower_valid && y_upper_valid)
                % Set the valid position
                this.terrain_.x = temp_terrain_pos(1);
                this.terrain_.y = temp_terrain_pos(2);
                
                % Remove position from list
                random_positions(i, :) = [];
                terrain_valid = true;
              end
              
              i = i + 1;
            end
          end
          
          % Remove any positions inside the terrain
          invalid_positions = [];
          for i = 1:length(random_positions)
            dx = random_positions(i, 1) - this.terrain_.x;
            dy = random_positions(i, 2) - this.terrain_.y;
            ds = sqrt(dx^2 + dy^2);
            inside = ds < (0.5*this.config_.scenario.terrain_size + this.config_.scenario.random_pos_padding);
            
            if(inside)
              invalid_positions(end + 1) = i; %#ok<AGROW>
            end
          end
          random_positions(invalid_positions, :) = [];
          
        else
          this.terrain_.x = [];
          this.terrain_.y = [];
        end
        
        % Check that some positions are left
        if(isempty(random_positions))
          attempt_count = attempt_count + 1;
          valid_positions_found = false;
          continue;
        end
        
        % Set the goal position
        goal_valid = false;
        i = 1;
        while(~goal_valid)
          temp_goal_pos = random_positions(i, :);
          
          if(this.config_.scenario.terrain_on)
            % Check if any part of goal zone is within terrain
            dx = temp_goal_pos(1) - this.terrain_.x;
            dy = temp_goal_pos(2) - this.terrain_.y;
            ds = sqrt(dx^2 + dy^2);
            inside = ds < (0.5*this.config_.scenario.terrain_size + 0.5*this.config_.scenario.goal_size + this.config_.scenario.random_pos_padding);
            
            if(inside)
              i = i + 1;
              continue;
            end
          end
          
          % Check that position is within world bounds
          a = (temp_goal_pos(1) - 0.5*this.config_.scenario.goal_size) > 0;
          b = (temp_goal_pos(1) + 0.5*this.config_.scenario.goal_size) < this.config_.scenario.world_width;
          c = (temp_goal_pos(2) - 0.5*this.config_.scenario.goal_size) > 0;
          d = (temp_goal_pos(2) + 0.5*this.config_.scenario.goal_size) < this.config_.scenario.world_height;
          in_bounds = (a && b && c && d);
          if(~in_bounds)
            i = i + 1;
            continue;
          end
          
          % Set the valid position
          this.goal_.x = temp_goal_pos(1);
          this.goal_.y = temp_goal_pos(2);
          
          % Remove position from list
          random_positions(i, :) = [];
          
          goal_valid = true;
        end
        
        % Remove any positions inside the goal area
        invalid_positions = [];
        for i = 1:length(random_positions)
          dx = random_positions(i, 1) - this.goal_.x;
          dy = random_positions(i, 2) - this.goal_.y;
          ds = sqrt(dx^2 + dy^2);
          inside = ds < 0.5*this.config_.scenario.goal_size + this.config_.scenario.random_pos_padding;
          
          if(inside)
            invalid_positions(end + 1) = i; %#ok<AGROW>
          end
        end
        random_positions(invalid_positions, :) = [];
        
        % Set the position for each obstacle
        for j = 1:this.config_.scenario.num_obstacles
          % Check that some positions are left
          if(isempty(random_positions))
            attempt_count = attempt_count + 1;
            valid_positions_found = false;
            continue;
          end
          
          obstacle_valid = false;
          i = 1;
          while(~obstacle_valid)
            temp_obst_pos = random_positions(i, :);
            
            if(this.config_.scenario.terrain_on)
              % Check if the obstacle is too close to the terrain
              dx = temp_obst_pos(1) - this.terrain_.x;
              dy = temp_obst_pos(2) - this.terrain_.y;
              ds = sqrt(dx^2 + dy^2);
              inside = ds < (0.5*this.config_.scenario.terrain_size + 0.5*this.config_.scenario.obstacle_size + this.config_.scenario.random_pos_padding);
              
              if(inside)
                i = i + 1;
                continue;
              end
            end
            
            % Check that position is within world bounds
            a = (temp_obst_pos(1) - 0.5*this.config_.scenario.obstacle_size - this.config_.scenario.random_border_padding) > 0;
            b = (temp_obst_pos(1) + 0.5*this.config_.scenario.goal_size) < (this.config_.scenario.world_width - this.config_.scenario.random_border_padding);
            c = (temp_obst_pos(2) - 0.5*this.config_.scenario.goal_size - this.config_.scenario.random_border_padding) > 0;
            d = (temp_obst_pos(2) + 0.5*this.config_.scenario.goal_size) < (this.config_.scenario.world_height - this.config_.scenario.random_border_padding);
            in_bounds = (a && b && c && d);
            if(~in_bounds)
              i = i + 1;
              continue;
            end
            
            % Set the valid position
            this.obstacles_(j).x = temp_obst_pos(1);
            this.obstacles_(j).y = temp_obst_pos(2);
            
            % Remove position from list
            random_positions(i, :) = [];
            
            % Remove any positions inside the obstacle area
            % (only items and robots left after this, so account for robot
            % radius)
            invalid_positions = [];
            for i = 1:length(random_positions)
              dx = random_positions(i, 1) - this.obstacles_(j).x;
              dy = random_positions(i, 2) - this.obstacles_(j).y;
              ds = sqrt(dx^2 + dy^2);
              inside = ds < (this.config_.scenario.obstacle_size + this.config_.scenario.random_pos_padding);
              
              if(inside)
                invalid_positions(end + 1) = i; %#ok<AGROW>
              end
            end
            random_positions(invalid_positions, :) = [];
            
            
            obstacle_valid = true;
          end
        end
        
        % Roll through all robots and assign positions
        % (every position will be valid now)
        for j = 1:this.config_.scenario.num_robots
          % Check that some positions are left
          if(isempty(random_positions))
            attempt_count = attempt_count + 1;
            valid_positions_found = false;
            continue;
          end
          
          this.robots_(j).x = random_positions(1, 1);
          this.robots_(j).y = random_positions(1, 2);
          this.robots_(j).theta = rand*2*pi;
          
          % Remove position from list
          random_positions(1, :) = [];
          
          % Remove any positions too close to robot
          invalid_positions = [];
          for i = 1:length(random_positions)
            dx = random_positions(i, 1) - this.robots_(j).x;
            dy = random_positions(i, 2) - this.robots_(j).y;
            ds = sqrt(dx^2 + dy^2);
            inside = ds < 0.5*this.config_.scenario.robot_size + this.config_.scenario.random_pos_padding;
            
            if(inside)
              invalid_positions(end + 1) = i; %#ok<AGROW>
            end
          end
          random_positions(invalid_positions, :) = [];
        end
        
        % Roll through all targets and assign positions
        % (every position will be valid now)
        for j = 1:this.config_.scenario.num_targets
          % Check that some positions are left
          if(isempty(random_positions))
            attempt_count = attempt_count + 1;
            valid_positions_found = false;
            continue;
          end
          
          this.targets_(j).x = random_positions(1, 1);
          this.targets_(j).y = random_positions(1, 2);
          
          % Remove position from list
          random_positions(1, :) = [];
          
          % Remove any positions too close to target
          invalid_positions = [];
          for i = 1:length(random_positions)
            dx = random_positions(i, 1) - this.robots_(j).x;
            dy = random_positions(i, 2) - this.robots_(j).y;
            ds = sqrt(dx^2 + dy^2);
            inside = ds < 0.5*this.config_.scenario.target_size + this.config_.scenario.random_pos_padding;
            
            if(inside)
              invalid_positions(end + 1) = i; %#ok<AGROW>
            end
          end
          random_positions(invalid_positions, :) = [];
        end        
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

