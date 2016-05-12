classdef Physics
    %PHYSICS - Responsible for all physics in RCISL simulation
    
    % HAS NOT BEEN REVIEWED YET
    
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
        %   runCycle
        %   
        %   Run one cycle of the physics engine.
  
        function runCycle(this, world_state)
            %deal with inst velocity
            %next lines "moves" targets that are being carried.
        
            %apply friction
            decay = 0;
            numRobots = this.config_.numRobots;
            for i=1:numRobots
                newPos = world_state.robot_pos_(i,:) + world_state.robot_vel_(i,:);
                
                carrierOther = 0;
                carrierMe = 0;
                
                if(world_state.groupPickup == 1 && world_state.robotProperties(i,1)> 0)
                    tid = world_state.robotProperties(i,1);
                    % assign the current robot and helper
                    if(world_state.targetProperties(tid,world_state.ID_CARRIED_BY) ==i)
                        carrierMe =world_state.targetProperties(tid,world_state.ID_CARRIED_BY) ;
                        carrierOther =world_state.targetProperties(tid,world_state.ID_CARRIED_BY_2) ;
                    else
                        carrierMe =world_state.targetProperties(tid,world_state.ID_CARRIED_BY_2) ;
                        carrierOther =world_state.targetProperties(tid,world_state.ID_CARRIED_BY) ;
                    end
                end
                
                if this.ValidPoint(world_state, newPos,world_state.TYPE_ROBOT,i,1,carrierOther) == 1 

                    if(world_state.groupPickup == 1 && world_state.robotProperties(i,1)> 0)
                        
                        weakPushingStrong = 0;
                        
                        if(carrierMe > 0)
                        % If you have a box, we want to know if you are weak
                        % pushing a heavy box
                            robotType = world_state.robotProperties(carrierMe,5);
                            boxType = world_state.targetProperties(tid ,3);
                            if(boxType == 2) 
                                %if the box is heavy
                                if(robotType == 2 || robotType == 3) 
                                    %And you are weak, and can't budge it
                                    weakPushingStrong = 1;
                                end
                            end
                        end

                        
                        if(carrierMe == i)
                                %apparently, the the box position is valid
                                if(carrierOther == 0)
                                    if(weakPushingStrong==0)
                                        world_state.target_pos_(world_state.robotProperties(i,1),:) = newPos + [0.01 0.01 0];
                                        world_state.robot_pos_(i,:) = newPos;
                                    end
                                else
                                    %Move helper, if we have one
                                    world_state.target_pos_(world_state.robotProperties(i,1),:) = newPos + [0.01 0.01 0];                                         
                                    world_state.robot_pos_(i,:) = newPos;
                                    world_state.robot_pos_(carrierOther,:) = newPos;
                                end
                            
                        else
                             world_state.robot_pos_(i,:) = newPos;
                        end
                    else
                        world_state.robot_pos_(i,:) = newPos;
                    end
                    
                end                
                world_state.robot_vel_(i,:) = world_state.robot_vel_(i,:)*decay;
            end
            
            numTargets = this.config_.numTargets;
            if(world_state.groupPickup == 0)
                for i=1:numTargets
                    newPos = world_state.target_pos_(i,:) + world_state.target_vel_(i,:);
                    if(world_state.boxPickup == 1 )
                        if(world_state.targetProperties(i,world_state.ID_CARRIED_BY) ~= 0)
                            robId = world_state.targetProperties(i,world_state.ID_CARRIED_BY);
                            newPos = world_state.robot_pos_(robId,:) + [0.01 0.01 0];
                            world_state.target_pos_(i,:) = newPos;
                        end
                        
                    end
                    
                    if(world_state.groupPickup == 1 )
                        %only test for collision if you are NOT being
                        %carried, otherwise it's a waste of time
                        if(world_state.targetProperties(i,world_state.ID_CARRIED_BY) == 0 ...
                                && world_state.targetProperties(i,world_state.ID_CARRIED_BY_2) == 0)
                            if this.ValidPoint(world_state, newPos,world_state.TYPE_TARGET,i,1,0) == 1
                                world_state.target_pos_(i,:) = newPos;
                            end
                        end
                    else
                        if this.ValidPoint(world_state, newPos,world_state.TYPE_TARGET,i,1,0) == 1
                            world_state.target_pos_(i,:) = newPos;
                        end
                        
                    end
                    world_state.target_vel_(i,:) = world_state.target_vel_(i,:)*decay;
                end
            end
            
            %see if a box is magically returned
            targetDistanceToGoal = bsxfun(@minus,world_state.target_pos_,world_state.goal_pos_);
            targetDistanceToGoal = targetDistanceToGoal.^2;
            targetDistanceToGoal = sum(targetDistanceToGoal,2);
            targetDistanceToGoal = sqrt(targetDistanceToGoal);
            targetDistanceToGoalBarrier = targetDistanceToGoal - (world_state.target_size_ + world_state.goal_size_);
            i = 1;
            numTargets = size(targetDistanceToGoal,1);
            
            %targetDistanceToGoalBarrier(2)
            while i <= numTargets
                if(targetDistanceToGoalBarrier(i) < -world_state.target_size_)
                    world_state.targetProperties(i) = 1;
                    %if the box is being carried, we drop it here.
                    if(world_state.boxPickup == 1 || world_state.groupPickup == 1)
                        world_state.targetProperties(i,world_state.ID_CARRIED_BY) = 0;
                    end    
                    if(world_state.groupPickup == 1)
                        world_state.targetProperties(i,world_state.ID_CARRIED_BY_2) = 0;
                    end    
                    
                end
                i = i + 1;
            end
            
            targetsReturned = sum(world_state.targetProperties(:,1));
            if targetsReturned == numTargets
                world_state.converged_ = world_state.converged_ +1;
                if(world_state.converged_ > 2)
                    world_state.converged_ = 2;
                end
            end
            
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   MoveTarget
        %   
        %   Apply power, given by a robot, to a target
        %   in a certain direction, relative to the robot,
        %   all using a certain powerAngle (distance, angle).
  
        function MoveTarget(~, world_state, robotId, targetId, powerAngle)
            %make sure distance is close enough
            if(targetId == 0)
                return;
            end
            
            robotType = world_state.robotProperties(robotId,5);
            boxType = world_state.targetProperties(targetId,3);
            
            if( world_state.groupPickup ==0)
                if(boxType == 2) 
                    % heavy box
                    if(robotType == 2 || robotType == 3)
                        %weak robot
                        return;    
                    end
                end
            end
            
            posDiff = world_state.robot_pos_(robotId,:) - world_state.target_pos_(targetId,:);
            posDiff = sqrt(posDiff.^2);
            posDiff = sum(posDiff);
            robotReach = world_state.robotProperties(robotId,6);
            
            if(posDiff <= robotReach)
                if(world_state.boxPickup == 1)
                    if(powerAngle == -1) %if we are dropping the box
                        world_state.targetProperties(targetId,world_state.ID_CARRIED_BY) = 0;
                    else
                        world_state.targetProperties(targetId,world_state.ID_CARRIED_BY) = robotId;
                    end
                    
                elseif(world_state.groupPickup == 1)
                    %If we are not gripping the box:
                    if(powerAngle ~= -1) 
                        
                        if(world_state.targetProperties(targetId,world_state.ID_CARRIED_BY_2) ~= robotId)
                            if(world_state.targetProperties(targetId,world_state.ID_CARRIED_BY) == 0)
                                world_state.targetProperties(targetId,world_state.ID_CARRIED_BY) = robotId; %grip slot 1
                            else
                                if(world_state.targetProperties(targetId,world_state.ID_CARRIED_BY) ~= robotId)
                                    if(world_state.targetProperties(targetId,world_state.ID_CARRIED_BY_2) == 0)
                                        world_state.targetProperties(targetId,world_state.ID_CARRIED_BY_2) = robotId; %slot 2
                                    end
                                end
                            end
                        end

                    else
                        if (world_state.targetProperties(targetId,world_state.ID_CARRIED_BY) == robotId)  
                            world_state.targetProperties(targetId,world_state.ID_CARRIED_BY) = 0;
                        end
                        if (world_state.targetProperties(targetId,world_state.ID_CARRIED_BY_2) == robotId)  
                            world_state.targetProperties(targetId,world_state.ID_CARRIED_BY_2) = 0;
                        end
                        % Move away 
                        newPos = world_state.target_pos_(targetId,1:3);
                        if(this.ValidPoint(world_state, newPos+ [0.5 0.5 0],world_state.TYPE_ROBOT,robotId,0,0))
                            world_state.robot_pos_(robotId,1:3) = newPos+ [0.5 0.5 0];
                        elseif(this.ValidPoint(world_state, newPos+ [-0.5 0.5 0],world_state.TYPE_ROBOT,robotId,0,0))
                            world_state.robot_pos_(robotId,1:3) = newPos+ [-0.5 0.5 0];
                        elseif(this.ValidPoint(world_state, newPos+ [0.5 -0.5 0],world_state.TYPE_ROBOT,robotId,0,0))
                            world_state.robot_pos_(robotId,1:3) = newPos+ [0.5 -0.5 0];
                        elseif(this.ValidPoint(world_state, newPos+ [-0.5 -0.5 0],world_state.TYPE_ROBOT,robotId,0,0))
                            world_state.robot_pos_(robotId,1:3) = newPos+ [-0.5 -0.5 0];
                        end
                    end
                else
                    
                    targetMass = world_state.targetProperties(targetId,2);
                    robotStrength = world_state.robotProperties(robotId,3);
                    amount = powerAngle(1);
                    angle = powerAngle(2);
                    amount = amount*robotStrength/targetMass;
                    addVelocity = [amount*cos(angle ) amount*sin(angle ) 0];

                    world_state.target_vel_(targetId,:) = addVelocity;
                end
            end
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   MoveRobot
        %   
        %   Move the robot forward a certain amount and with a
        %   certain amount of rotation.
  
        function MoveRobot(this, world_state, id, distance, rotation)
            
            % Add rotation ot orentation, and convert to be within [0,2Pi] 
            newOrient =[ 0 0 mod(world_state.robot_orient_(id,3) + rotation, 2*pi)];
            
            %find a new velocity
            addVelocity = [distance*cos(newOrient(3)) distance*sin(newOrient(3)) 0];
            currentVelocity = world_state.robot_vel_(id,:);
            
            %increase velocity up to a maximum instantly
            for i=1:2
                %if we are going very slow, or backwards, speed up as much
                %as possible
                if abs(currentVelocity(i) + addVelocity(i)) <= abs(addVelocity(i))
                    currentVelocity(i) = currentVelocity(i) + addVelocity(i);
                %if we are going slower than our max, and can use a boost -
                %go to max speed
                elseif abs(currentVelocity(i) + addVelocity(i)) > abs(addVelocity(i)) && ...
                    abs(currentVelocity(i)) < abs(addVelocity(i))
                    currentVelocity(i) = addVelocity(i) ;
                end
            end
            
            % Assign the new position and orientation
            world_state.robot_orient_(id,:) = newOrient;
            world_state.robot_vel_(id,:) = currentVelocity;
            
            % Find new point, and check if its valid
            new_point = world_state.robot_pos_(id,:);
            valid = this.ValidPoint(world_state, new_point, world_state.TYPE_ROBOT, id, 0, 0);
            
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   ValidPoint
        %   
        %   Test if a new point is valid, in terms of collision,
        %   if the object with the current id and type is taken
        %   and moved toward the newPoint.
  
        function valid = ValidPoint(this, world_state, newPoint,type,id,doCollide,partnerId)
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

