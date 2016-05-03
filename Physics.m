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
        %   runCycle
        %   
        %   Run one cycle of the physics engine.
        %   HAS NOT BEEN REVIEWED YET
  
        function runCycle(~, world_state)
            %deal with inst velocity
            %next lines "moves" targets that are being carried.
        
            %apply friction
            decay = 0;
            numRobots = size(world_state.robotPos,1);
            for i=1:numRobots
                newPos = world_state.robotPos(i,:) + world_state.robotVelocity(i,:);
                
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
                
                if world_state.ValidPoint(newPos,world_state.TYPE_ROBOT,i,1,carrierOther) == 1 

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
                                        world_state.targetPos(world_state.robotProperties(i,1),:) = newPos + [0.01 0.01 0];
                                        world_state.robotPos(i,:) = newPos;
                                    end
                                else
                                    %Move helper, if we have one
                                    world_state.targetPos(world_state.robotProperties(i,1),:) = newPos + [0.01 0.01 0];                                         
                                    world_state.robotPos(i,:) = newPos;
                                    world_state.robotPos(carrierOther,:) = newPos;
                                end
                            
                        else
                             world_state.robotPos(i,:) = newPos;
                        end
                    else
                        world_state.robotPos(i,:) = newPos;
                    end
                    
                end                
                world_state.robotVelocity(i,:) = world_state.robotVelocity(i,:)*decay;
            end
            
            numTargets = size(world_state.targetPos,1);
            if(world_state.groupPickup == 0)
                for i=1:numTargets
                    newPos = world_state.targetPos(i,:) + world_state.targetVelocity(i,:);
                    if(world_state.boxPickup == 1 )
                        if(world_state.targetProperties(i,world_state.ID_CARRIED_BY) ~= 0)
                            robId = world_state.targetProperties(i,world_state.ID_CARRIED_BY);
                            newPos = world_state.robotPos(robId,:) + [0.01 0.01 0];
                            world_state.targetPos(i,:) = newPos;
                        end
                        
                    end
                    
                    if(world_state.groupPickup == 1 )
                        %only test for collision if you are NOT being
                        %carried, otherwise it's a waste of time
                        if(world_state.targetProperties(i,world_state.ID_CARRIED_BY) == 0 ...
                                && world_state.targetProperties(i,world_state.ID_CARRIED_BY_2) == 0)
                            if world_state.ValidPoint(newPos,world_state.TYPE_TARGET,i,1,0) == 1
                                world_state.targetPos(i,:) = newPos;
                            end
                        end
                    else
                        if world_state.ValidPoint(newPos,world_state.TYPE_TARGET,i,1,0) == 1
                            world_state.targetPos(i,:) = newPos;
                        end
                        
                    end
                    world_state.targetVelocity(i,:) = world_state.targetVelocity(i,:)*decay;
                end
            end
            
            %see if a box is magically returned
            targetDistanceToGoal = bsxfun(@minus,world_state.targetPos,world_state.goalPos);
            targetDistanceToGoal = targetDistanceToGoal.^2;
            targetDistanceToGoal = sum(targetDistanceToGoal,2);
            targetDistanceToGoal = sqrt(targetDistanceToGoal);
            targetDistanceToGoalBarrier = targetDistanceToGoal - (world_state.targetSize + world_state.goalSize);
            i = 1;
            numTargets = size(targetDistanceToGoal,1);
            
            %targetDistanceToGoalBarrier(2)
            while i <= numTargets
                if(targetDistanceToGoalBarrier(i) < -world_state.targetSize)
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
                world_state.converged = world_state.converged +1;
                if(world_state.converged > 2)
                    world_state.converged = 2;
                end
            end
            
        end

        
    end
    
end

