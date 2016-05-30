classdef Physics
    %PHYSICS - Responsible for all physics in RCISL simulation
    
    % Peforms modifications to the worldstate when robots move forward,
    % backward, rotate, or interact with an item. 
    %
    % When the robot attempts to move forward or backward it will check if 
    % the desired movement is valid by checking for collisions with objects 
    % in the world.
    %
    % Interction involves picking up an item, or dropping an item if the
    % robot is carrying an item.
        
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
        %   Makes a robot interact with an item. If the robot is already
        %   carring an item, it will drop it. Otherwise, if it is close
        %   enough to the taget item it will pick it up.
        %
        %   INPUTS:
        %   world_state = WorldState object
        %   robot_id = ID number of robot to move
        %   target_id = ID number of assigned target
        %   acquiescence = If the robot should be forced to drop the item
  
        function interact(~, world_state, robot_id, target_id, force_drop)
            % Only proceed if the robot has a target
            if(target_id ~= 0)
                % Which robot is carrying the target item
                carrying_robot = world_state.targetProperties(target_id, world_state.tpid_carriedBy);
                
                % If we are carrying or requested to force drop, drop the
                % item. Otherwise, try to pick it up.
                if (carrying_robot == robot_id || force_drop)
                    % Drop the box
                    world_state.targetProperties(target_id, world_state.tpid_carriedBy) = 0;
                else
                    % Check proximity
                    dist = world_state.robot_pos_(robot_id,:) - world_state.target_pos_(target_id,:);
                    dist = sqrt(dist.^2);
                    dist = sum(dist);
                    robot_reach = world_state.robotProperties(robot_id,6);
                    
                    % Pick up the item of close enough
                    if(dist <= robot_reach)
                        world_state.targetProperties(target_id,world_state.tpid_carriedBy) = robot_id;
                    end
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
        %   robot_id = ID number of robot to move
        %   distance = Distance to move
        %   rotation = Angle to rotate
  
        function MoveRobot(this, world_state, robot_id, distance, rotation)
            % Can assign the new orientation, since it will always be valid
            new_orient =[ 0 0 mod(world_state.robot_orient_(robot_id,3) + rotation, 2*pi)];
            world_state.robot_orient_(robot_id,:) = new_orient;
            
            % Only perform position calculations if necessary
            if(distance ~= 0)
                % Find velocity
                new_vel = [distance*cos(new_orient(3)) distance*sin(new_orient(3)) 0];
                % Find new position
                new_pos = world_state.robot_pos_(robot_id,:) + new_vel;
                
                % Only move if its valid
                if this.validPoint(world_state, new_pos, robot_id) == 1
                    world_state.robot_pos_(robot_id,:) = new_pos;
                    world_state.robot_vel_(robot_id,:) = new_vel;
                    
                    % Only move target if the robot has one
                    target_id = world_state.robotProperties(robot_id, world_state.rpid_currentTarget);
                    if (target_id ~= 0)
                        % Check if robot is carrying item
                        carrying_item = world_state.targetProperties(target_id, world_state.tpid_carriedBy) == robot_id;
                        
                        % Check if robot is capable of moving the item
                        robot_type = world_state.robotProperties(robot_id, 5);
                        box_type = world_state.targetProperties(target_id, 3);
                        if (((box_type == 2) && (robot_type == 1) || box_type == 1))
                            can_carry = true;
                        else
                            can_carry = false;
                        end
                        
                        % Move box if appropriate
                        if (carrying_item && can_carry)
                            % Assign position and velocities
                            world_state.target_pos_(target_id,:) = new_pos;
                            world_state.target_vel_(target_id,:) = new_vel;
                            
                            % Check proximity of target to goal
                            target_dist_to_goal = world_state.goal_pos_ - world_state.target_pos_(target_id, :);
                            target_dist_to_goal = sqrt(sum(target_dist_to_goal.^2));
                            
                            % Mark as returned if close enough
                            if ((target_dist_to_goal + world_state.target_size_) < world_state.goal_size_)
                                world_state.targetProperties(target_id, world_state.tpid_isReturned) = 1;
                                world_state.targetProperties(target_id, world_state.tpid_carriedBy) = 0;
                            end
                        else
                            world_state.target_vel_(target_id,:) = 0;
                        end
                    end
                else
                    world_state.robot_vel_(robot_id,:) = 0;
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
        %   new_point = Vector [X, Y, Z] with new point coordinates
        %   robot_id = ID number of robot
  
        function valid = validPoint(~, world_state, new_point, robot_id)
            % Get size of robot
            robot_size = world_state.robot_size_;
            
            %Test X world boundary
            if ((new_point(1) - robot_size < 0) || (new_point(1) + robot_size > world_state.world_width_))
                valid = false; 
                return; 
            end
            
            %Test Y world boundary
            if ((new_point(2) - robot_size < 0) || (new_point(2) + robot_size > world_state.world_height_))
                valid = false; 
                return; 
            end
            
            % Test Z world boundary
            if ((new_point(3) < 0) || (new_point(3)  > world_state.world_depth_))
                valid = false; 
                return; 
            end
            
            % Get distances to obstacles
            obs_dist = bsxfun(@minus,world_state.obstacle_pos_, new_point);
            obs_dist = sqrt(obs_dist(:,1).^2 + obs_dist(:,2).^2 + obs_dist(:,3).^2);
            [min_obs_dist, ~] = min(obs_dist);
            
            % Check for collision with obstacles
            if min_obs_dist < robot_size + world_state.obstacle_size_
                valid = false;
                return;
            end
            
            % Get distances to other robots (must remove this robot from
            % array of distances)
            robot_dist = bsxfun(@minus,world_state.robot_pos_, new_point);
            robot_dist(robot_id, :) = [];
            
            if(~isempty(robot_dist))
                robot_dist = sqrt(robot_dist(:,1).^2 + robot_dist(:,2).^2 + robot_dist(:,3).^2);
                [min_robot_dist, ~] = min(robot_dist);
                
                % Check for collision with other robots
                if min_robot_dist < robot_size + world_state.robot_size_
                    valid = false;
                    return;
                end
            end
            
            % Get distance to other targets
            target_dist = bsxfun(@minus,world_state.target_pos_, new_point);
            
            % Don't check against items being carried or returned
            returned_items = (world_state.targetProperties(:,1) ~= 0);
            carried_items = (world_state.targetProperties(:,world_state.ID_CARRIED_BY) ~= 0);
            void_items = (returned_items + carried_items)~= 0;
            target_dist(void_items, :) = [];
            
            if(~isempty(target_dist))
                target_dist = sqrt(target_dist(:,1).^2 + target_dist(:,2).^2 + target_dist(:,3).^2);
                [min_target_dist, closest_target] = min(target_dist) ;
                
                % Check if the robot is within the boundaries of the item
                % (for cases when it drops an item)
                coincident = world_state.robot_pos_(robot_id,:) - world_state.target_pos_(closest_target,:);
                coincident = sqrt(sum(coincident.^2)) < world_state.target_size_;
                
                % Check for collision with targets (must allow for the case
                % when a robot drops an item, making the distance zero)
                if ((min_target_dist < (robot_size + world_state.target_size_)) && ~coincident)
                    valid = false;
                    return;
                end
            end
            
            % If all chacks have passed, the new point is valid
            valid = true;
        end

    end
    
end

