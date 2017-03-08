classdef Physics < handle
  % PHYSICS - Responsible for all physics in the simulation
  
  % Peforms modifications to the WorldState when robots move forward,
  % backward, rotate, or interact with an item.
  %
  % When the robot attempts to move forward or backward it will check if
  % the desired movement is valid by checking for collisions with objects
  % in the world.
  %
  % Interction involves picking up an item when close enough. Dropping
  % capability is currently not in place.
  
  properties
    config_ = [];
  end
  
  methods
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %   Constructor
    function this = Physics(config)
      this.config_ = config;
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %   interact
    %
    %   Makes a robot interact with an item. If the robot is close
    %   enough to the taget item it will pick it up.
    %
    %   INPUTS:
    %   world_state = WorldState object
    %   robot_state = RobotState object
    %   prop = Struct of robot properties
    
    function interact(~, world_state, robot_state, prop)
      % Only proceed if the robot has a target, and isn't carrying it
      if(robot_state.target_.id ~= -1 && ~robot_state.target_.carrying)
        
        % Check if the robot can carry this item
        if(~prop.strong && strcmp(world_state.targets_(robot_state.target_.id).type, 'heavy'))
          return
        end
        
        % Check proximity
        dist.x = world_state.robots_(robot_state.id_).x - world_state.targets_(robot_state.target_.id).x;
        dist.y = world_state.robots_(robot_state.id_).y - world_state.targets_(robot_state.target_.id).y;
        dist.d = sqrt(dist.x^2 + dist.y^2);
        
        % Pick up the item of close enough
        if(dist.d <= prop.reach)
          robot_state.target_.carrying = true;
        end
      end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %   MoveRobot
    %
    %   Moves a robot (and its item if it is carrying one) the
    %   inputted distance and rotation
    %
    %   INPUTS:
    %   world_state = WorldState object
    %   robot_state = RobotState object
    %   distance = Distance to move
    %   rotation = Angle to rotate
    
    function MoveRobot(this, world_state, robot_state, prop, distance, rotation)
      % First account for rough terrain and non-rugged robots
      if(this.config_.scenario.terrain_on && ~prop.rugged)
        % Check if within boundaries
        x_inside_terrain = abs(world_state.robots_(robot_state.id_).x - world_state.terrain_.x) < 0.5*this.config_.scenario.terrain_size;
        y_inside_terrain = abs(world_state.robots_(robot_state.id_).y - world_state.terrain_.y) < 0.5*this.config_.scenario.terrain_size;
        if(x_inside_terrain && y_inside_terrain)
          % Slow the movement
          distance = distance*this.config_.scenario.terrain_fractional_speed;
          rotation = rotation*this.config_.scenario.terrain_fractional_speed;
        end
      end
      
      % Can assign the new orientation, since it will always be valid
      world_state.robots_(robot_state.id_).theta = mod(world_state.robots_(robot_state.id_).theta + rotation, 2*pi);
      
      % Only perform position calculations if necessary
      if(distance ~= 0)
        % Determine the new position
        new_pt.x = world_state.robots_(robot_state.id_).x + distance*cos(world_state.robots_(robot_state.id_).theta);
        new_pt.y = world_state.robots_(robot_state.id_).y + distance*sin(world_state.robots_(robot_state.id_).theta);
        
        % Only move if its valid
        if (this.validPoint(world_state, new_pt, robot_state.id_))
          % Assign the new position
          world_state.robots_(robot_state.id_).x = new_pt.x;
          world_state.robots_(robot_state.id_).y = new_pt.y;
          
          % Move the item as well if the robot is carrying one
          if(robot_state.target_.carrying)
            % Assign the new item position
            world_state.targets_(robot_state.target_.id).x = new_pt.x;
            world_state.targets_(robot_state.target_.id).y = new_pt.y;
            
            % Check proximity of item to goal
            item_dist.x = world_state.goal_.x - world_state.targets_(robot_state.target_.id).x;
            item_dist.y = world_state.goal_.y - world_state.targets_(robot_state.target_.id).y;
            item_dist.d = sqrt(item_dist.x^2 + item_dist.y^2);
            
            % Item must be fully within the collection zone
            if ((item_dist.d + this.config_.scenario.target_size) < this.config_.scenario.goal_size)
              % Mark as returned, and unassign the item
              world_state.targets_(robot_state.target_.id).returned = true;
              world_state.mission_.targets_returned = world_state.mission_.targets_returned + 1;
              robot_state.target_.carrying = false;
              robot_state.target_.id = -1;
            end
          end
        end
      end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %   validPoint
    %
    %   Test if a new point is valid, in terms of collision,
    %   if the robot with the current id is taken and moved to the
    %   new point
    %
    %   INPUTS:
    %   world_state = WorldState object
    %   new_pt = Struct with x and y fields
    %   robot_id = ID number of robot
    
    function valid = validPoint(this, world_state, new_pt, robot_id)
      % Get size of robot
      robot_size = this.config_.scenario.robot_size;
      
      % Test X world boundary
      if ((new_pt.x - robot_size < 0) || (new_pt.x + robot_size > this.config_.scenario.world_width))
        valid = false;
        return;
      end
      
      % Test Y world boundary
      if ((new_pt.y - robot_size < 0) || (new_pt.y + robot_size > this.config_.scenario.world_height))
        valid = false;
        return;
      end
      
      % Function to determine distance of struct coord to new point
      % (used with obstacles and robots)
      new_pt_dist_fun = @(field) sqrt((field.x - new_pt.x)^2 + (field.y - new_pt.y)^2);
      
      % Test against all obstacles
      obstacle_ds = arrayfun(new_pt_dist_fun, world_state.obstacles_);
      if(sum(obstacle_ds < robot_size + this.config_.scenario.obstacle_size) > 0)
        valid = false;
        return;
      end
      
      % Check against other robots
      robots = world_state.robots_;
      
      % Ignore this robot
      robots(robot_id) = [];
      
      % Ignore robots within the collection zone (allow them to congregate)
      goal_dist_fun = @(field) sqrt((field.x - world_state.goal_.x)^2 + (field.y - world_state.goal_.y)^2);
      robot_goal_ds = arrayfun(goal_dist_fun, robots);
      robots_in_collect = find(robot_goal_ds < this.config_.scenario.goal_size);
      robots(robots_in_collect) = [];  % Ignore matlab warning here, doesn't apply to structs
      
      robot_ds = arrayfun(new_pt_dist_fun, robots);
      if(sum(robot_ds < 2*robot_size) > 0)
        valid = false;
        return;
      end
      
      % If all checks have passed, the new point is valid
      valid = true;
    end
    
  end
  
end

