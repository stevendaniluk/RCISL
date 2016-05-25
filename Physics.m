classdef Physics
    %PHYSICS - Responsible for all physics in RCISL simulation
        
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
  
        function interact(~, world_state, robot_id, target_id, acquiescence)
            % Only proceed if the robot has a target
            if(target_id ~= 0)
                % Which robot is carrying the target item
                carrying_robot = world_state.targetProperties(target_id, world_state.tpid_carriedBy);
                
                % If we are carrying or requested to acquiesce, drop the
                % item. Otherwise, try to pick it up.
                if (carrying_robot == robot_id || acquiescence == -1)
                    % Drop the box
                    world_state.targetProperties(target_id, world_state.tpid_carriedBy) = 0;
                else
                    % Check proximity
                    posDiff = world_state.robot_pos_(robot_id,:) - world_state.target_pos_(target_id,:);
                    posDiff = sqrt(posDiff.^2);
                    posDiff = sum(posDiff);
                    robotReach = world_state.robotProperties(robot_id,6);
                    
                    % Pick up the item of close enough
                    if(posDiff <= robotReach)
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
                if this.validPoint(world_state, new_pos, world_state.TYPE_ROBOT, robot_id, 1, 0) == 1
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
        %   if the object with the current id and type is taken
        %   and moved toward the newPoint.
  
        function valid = validPoint(this, world_state, newPoint,type,id,doCollide,partnerId)
            %find the size to be used
            myRobot1 = 0;
            myRobot2 = 0;
            
            % Assign sizes if we are a robot, obstacle, or target
            if type == 1
                % Obstacle
                mySize = world_state.obstacle_size_;
                myVelocity = world_state.obstacle_vel_(id,:);
                myPos = world_state.obstacle_pos_(id,:);
                myMass = world_state.obstacle_mass_;
                myStrength = 1;
            elseif type == 2
                % Robot
                mySize = world_state.robot_size_;
                myVelocity = world_state.robot_vel_(id,:);
                myPos = world_state.robot_pos_(id,:);
                myMass = world_state.robot_mass_;
                myStrength = world_state.robotProperties(id,3);
            elseif type == 3
                % Target
                mySize = world_state.target_size_;
                myVelocity = world_state.target_vel_(id,:);
                myPos = world_state.target_pos_(id,:);
                myMass = world_state.target_mass_;
                myStrength = 1;

                if(world_state.groupPickup == 1)
                    myRobot1 = world_state.targetProperties(id,world_state.ID_CARRIED_BY);
                    myRobot2 = world_state.targetProperties(id,world_state.ID_CARRIED_BY_2);
                end
            end
            
            %Test X world boundary
            if ((newPoint(1) - mySize < 0) || (newPoint(1) + mySize > world_state.world_width_))
                valid=0; 
                return; 
            end
            %Test Y world boundary
            if ((newPoint(2) - mySize < 0) || (newPoint(2) + mySize > world_state.world_height_))
                valid=0; 
                return; 
            end
            % Test Z world boundary
            if ((newPoint(3) < 0) || (newPoint(3)  > world_state.world_depth_))
                valid=0; 
                return; 
            end
            
            %Test against Obstacles
            obsDist = bsxfun(@minus,world_state.obstacle_pos_, newPoint);
            
            if  type == 1 ; obsDist(id,:) = [100 100 100]; end; 
            obsDist = obsDist(:,1).^2 + obsDist(:,2).^2 + obsDist(:,3).^2;
            obsDist = sqrt(obsDist);
            [minDist,closestObstacleId] = min(obsDist);

            %Test against Robots (other robots)
            robDist = bsxfun(@minus,world_state.robot_pos_, newPoint);
            if(partnerId > 0)
                robDist(partnerId,:)  = robDist(partnerId,:) + 400;
            end
            
            if(world_state.groupPickup == 1)
                %dont consider bumping into attached robots
                if(myRobot1 > 0)
                    robDist(myRobot1,:)  = robDist(myRobot1,:) + 200;
                end
                if(myRobot2 > 0)
                    robDist(myRobot2,:)  = robDist(myRobot2,:) + 300;
                end
            end
            
            if type==2 ; robDist(id,:) = [100 100 100]; end;
            robDist = robDist(:,1).^2 + robDist(:,2).^2 + robDist(:,3).^2;
            robDist = sqrt(robDist);
            [minDistRobot,closestRobotId] = min(robDist);

            %Test against Targets
            targetDist = bsxfun(@minus,world_state.target_pos_, newPoint);
            if  type == 3 ; targetDist(id,:) = [100 100 100]; end; 

            %next lines "moves" targets that are returned.
            targetDist = bsxfun(@plus,targetDist, (abs(world_state.targetProperties(:,1)).*100));

            %next lines "moves" targets that are being carried.
            if(world_state.boxPickup == 1 || world_state.groupPickup == 1)
                targetDist = bsxfun(@plus,targetDist, (abs(world_state.targetProperties(:,world_state.ID_CARRIED_BY)).*100));

            end
            if(world_state.groupPickup == 1) 
                targetDist = bsxfun(@plus,targetDist, (abs(world_state.targetProperties(:,world_state.ID_CARRIED_BY_2)).*100));                
            end            
            
            targetDist = targetDist(:,1).^2 + targetDist(:,2).^2 + targetDist(:,3).^2;
            targetDist = sqrt(targetDist);
            [minTargetDist,closestTargetId] = min(targetDist) ;            
            
            if minDist < mySize + world_state.obstacle_size_
                valid = 0;
                %preform a collision and update the velocities
                physicsArray1 = [world_state.obstacle_pos_(closestObstacleId,:) world_state.obstacle_vel_(closestObstacleId,:) world_state.obstacle_size_ world_state.obstacle_mass_];
                physicsArray2 = [myPos myVelocity mySize myMass];
                [physicsArray1,physicsArray2] = this.Collide(physicsArray1,physicsArray2);   
                if (doCollide == 1)
                    world_state.obstacle_pos_(closestObstacleId,:) = physicsArray1(1:3);
                    world_state.obstacle_vel_(closestObstacleId,:) = physicsArray1(4:6);
                end
                myPos = physicsArray2(1:3);
                myVelocity = physicsArray2(4:6);
                return;
            end
            
            if minDistRobot < mySize + world_state.robot_size_
                valid = 0;
                %preform a collision and update the velocities
                physicsArray1 = [world_state.robot_pos_(closestRobotId,:) world_state.robot_vel_(closestRobotId,:) world_state.robot_size_ world_state.robot_mass_];
                physicsArray2 = [myPos myVelocity mySize myMass];
                [physicsArray1,physicsArray2] = this.Collide(physicsArray1,physicsArray2);
                if(doCollide == 1)
                    world_state.robot_pos_(closestRobotId,:) = physicsArray1(1:3);
                    world_state.robot_vel_(closestRobotId,:) = physicsArray1(4:6);
                end
                myPos = physicsArray2(1:3);
                myVelocity = physicsArray2(4:6);
            
                return;
            end
            
            if minTargetDist < mySize + world_state.target_size_
                valid = 0;                
                %preform a collision and update the velocities
                boxMass = world_state.targetProperties(closestTargetId,2);
                
                %Alter weights so a weak robot can't budge a heavy box
                robotType = world_state.robotProperties(id,5);
                boxType = world_state.targetProperties(closestTargetId,3);
                if(boxType == 2) 
                    %if the box is heavy
                    if(robotType == 2 || robotType == 3) 
                        %And you are weak, and can't budge it
                        valid = 0;
                        return;    
                    end
                end

                physicsArray1 = [world_state.target_pos_(closestTargetId,:) world_state.target_vel_(closestTargetId,:) world_state.target_size_ boxMass];
                physicsArray2 = [myPos myVelocity mySize myMass*myStrength];
                [physicsArray1,physicsArray2] = this.Collide(physicsArray1,physicsArray2);
                if(doCollide == 1)
                    world_state.target_pos_(closestTargetId,:) = physicsArray1(1:3);
                    world_state.target_vel_(closestTargetId,:) = physicsArray1(4:6);
                end
                myPos = physicsArray2(1:3);
                myVelocity = physicsArray2(4:6);
                
                return;
            end
            valid = 1;
            
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Collide
        %   
        %   Collide a set of two similar objects
  
        function [phyResult1,phyResult2]= Collide(~,physicsArray1,physicsArray2)
            %first lets get complete vectors
            pa1 = physicsArray1;
            pa2 = physicsArray2;
            %first lets find the vector between them, from 1->2
            b = pa2(1:3) - pa1(1:3);
            
            if(sum(b,2) == 0)
                b = [1 0 0];
            end
            
            %velocities and mass
            v1 = pa1(4:6);
            v2 = pa2(4:6);
            m1 = pa1(8);
            m2 = pa2(8);
            if(m1 == 0)
                m1 = 10000;
            end
            if(m2 == 0)
                m2 = 10000;
            end

            b = b(:)./sqrt(b(1)^2 + b(2) ^2 + b(3) ^2);

            v1a = ((v1*b)*b)';
            v1b = v1 - v1a;

            v2a = ((v2*b)*b)';
            v2b = v2 - v2a;

            vf1a = ((m1 -  m2).*v1a + 2*(m2.*v2a))./(m1+m2);

            vf2a = ((m2 -  m1).*v2a + 2*(m1.*v1a))./(m1+m2);
            vf1 = vf1a+ v1b;
            vf2 = vf2a+ v2b;
            if(m1 == 0)
                vf1 = 0;
            end
            if(m2 == 0)
                vf2 = 0;
            end
            
            phyResult1 = [physicsArray1(1:3) vf1 physicsArray1(7:8)];
            phyResult2 = [physicsArray2(1:3) vf2 physicsArray2(7:8)];

        end

    end
    
end

