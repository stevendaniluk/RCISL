classdef worldState < handle
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % 
    %   worldState
    %   
    %   World State is in charge of the physical simulation
    %   it maintains the ground truth for the world,
    %   and performs all needed physics simulation
    %   
    % Notes (to do items summary)
    % X show robot types on playback (masses change line thickness)
    % X show target types
    % X stop robot when box returned right away
    % - pull team configuration into config file
    % - pull random vs repeat test into config file
    
    % (don't do this) Physical implementation When turn, consider validity of turn
    % X Add same phyiscal transformations for a cooperating robot
    % X Add permission of weak robot to grip
    % X Add filter such that the task can move if two weak robots work
    % X together
    % L-Alliance uses new Team Taus
    % Individual learning uses Assisting robot info
    % Scale reward by distance traveled
    % Assigned robot can pass through unrelated task
    % Advice Exchange can be turned off
    % 7 targets
    % Add "only cooperate if" condition
    % Add "don't save performance if" condition
    
    % Individual changes - Reward for selecting a task
    % Reward divided by the amount of cooperators (Makes it cautious)
    % CANT have more than one robot on a task
    % Change results label (change Cautious -> On for individual)
    
    properties
        
        %todo - rename milliseconds -> iterations
        %this variable represents time steps
        milliseconds = 0;

        %Robot position [x y z]
        robotPos = [];
        obstaclePos = [];
        targetPos = [];
        goalPos = [];

        %Robot position [rx ry rz]
        robotOrient = [];
        obstacleOrient = [];
        targetOrient = [];  
        goalOrient = [];

        %Robot position [x y z]
        robotVelocity = [];
        obstacleVelocity = [];
        targetVelocity = [];
        goalVelocity = [];
        

        % Robot Properties 
        % [ currentTarget rotationStep mass              
        % robotType reach] 
        robotProperties = [];
        rpid_currentTarget = 1;
        rpid_rotationStep = 2;
        rpid_mass = 3;
        rpid_typeId = 4;
        rpid_reachId = 5;
        
        % Target Properties       
        % [ isReturned weight                 
        %   type(1/2) carriedBy           
        %   size lastRobotToCarry]
        targetProperties = [];
        tpid_isReturned = 1;
        tpid_weight = 2;
        tpid_type12 = 3;
        tpid_carriedBy = 4;
        tpid_size = 5;
        tpid_lastRobotToCarry = 6;

        %Is this world all 'finished' == 1
        converged = 0;
        
        
        
        % The 'inital' properties are used to reset the world
        % after a simulation is performed
        % {Begin
        robotPos_inital = [];
        robotVelocity_inital = [];
        robotOrient_inital = [];
        robotProperties_inital = [];
        
        obstaclePos_inital = [];
        obstacleVelocity_inital = [];
        obstacleOrient_inital = [];

        targetPos_inital = [];
        targetVelocity_inital = [];
        targetOrient_inital = [];        
        targetProperties_inital = [];        
        goalPos_inital = [];

        randomPaddingSize_inital = 0;
        randomBorderSize_inital = 0;
        robotSize_inital = 0;
        obstacleSize_inital = 0;
        targetSize_inital = 0;
        goalSize_inital = 0;
        robotMass_inital = 0;
        targetMass_inital = 0;
        obstacleMass_inital = 0; 
        WIDTH_inital = 0;  
        HEIGHT_inital = 0; 
        DEPTH_inital = 0;  
        
        % } Inital properties end
        
       
        % Some constant world parameters. 
        % (These are redefined by a configuration file!)
        randomPaddingSize = 0.5;
        randomBorderSize = 1;
        robotSize = 0.25/2;
        obstacleSize = 0.5;
        targetSize = 0.25;
        goalSize = 1.0;
        robotMass = 1;
        targetMass = 1;
        obstacleMass = 0; 
        WIDTH = 0;  %world x
        HEIGHT = 0; %world y
        DEPTH = 0;  %world z

        %the amount of dimensions
        CONST_DIMENSION = 3;
        
        %types in the world. Not currently used effectively
        TYPE_OBSTACLE = 1;
        TYPE_ROBOT = 2;
        TYPE_TARGET = 3;
        
        ID_CARRIED_BY = 4;
        ID_CARRIED_BY_2 = 7;
        
        % Configures whether or not the boxes may be 
        % 'Picked Up'
        boxPickup = 0;
        groupPickup = 0;
        
        % The list of the robots in the world
        s_robotTeam = [];
        
    end
    
    methods

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   worldState Constructor
        %   
        %   The constructor uses a configuration file
        %   to build the world
        %   
        %   
        function this = worldState(configId)
            %TODO - Rafactor so all objects are in one array and handeled
            %at the same time. It's very silly to have three seperate
            %idendical data structures. damn you past justin!

            %TODO - rafactor so positions AND orientations are stored in
            %one vector, not two.

            c = Configuration.Instance(configId);
            this.WIDTH = c.world_Height;
            this.HEIGHT = c.world_Width;
            this.DEPTH = c.world_Depth;

            
            
            % randomize all the positions and orientatons for all objects
            this.randomizeState(c.numRobots, c.numObstacles,c.numTargets,configId);
          
            
            % save the inital configurations
            % {begin save
            this.obstaclePos_inital =  this.obstaclePos;
            this.obstacleOrient_inital  = this.obstacleOrient ;
            this.obstacleVelocity_inital  = this.obstacleVelocity ;
            
            this.robotPos_inital  =  this.robotPos;
            this.robotOrient_inital  = this.robotOrient;
            this.robotVelocity_inital  = this.robotVelocity;
            this.robotProperties_inital = this.robotProperties;

            this.targetPos_inital  =  this.targetPos;
            this.targetOrient_inital  = this.targetOrient ;
            this.targetVelocity_inital  = this.targetVelocity;
            this.targetProperties_inital = this.targetProperties;

            this.goalPos_inital  = this.goalPos;
            %} end save 
            
            this.randomPaddingSize_inital = this.randomPaddingSize;
            this.randomBorderSize_inital = this.randomBorderSize;
            this.robotSize_inital = this.robotSize;
            this.obstacleSize_inital = this.obstacleSize;
            this.targetSize_inital = this.targetSize;
            this.goalSize_inital = this.goalSize;
            this.robotMass_inital = this.robotMass;
            this.targetMass_inital = this.targetMass;
            this.obstacleMass_inital = this.obstacleMass; 
            this.WIDTH_inital = this.WIDTH;  %world x
            this.HEIGHT_inital = this.HEIGHT; %world y
            this.DEPTH_inital = this.DEPTH;  %world z

            
            % set the realism level accordingly
            % at the first realism level, we let the boxes be 'picked up'
            % by a robot. At later sim levels this is not the case.
            this.boxPickup =0;
            this.groupPickup =0;
            
            if(c.simulation_Realism == 0)
                this.boxPickup = 1;
            end
            if(c.simulation_Realism == 2)
                this.groupPickup = 1;
            end 
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   reset
        %   
        %   If it is needed, the world can be reset
        %   the inital properties for the world
        %   will be recovered.
        %
        %   Although unused, this function allows the 
        %   entire simulation to be run many times under
        %   different utility functions
        %
        function reset(this)

            this.milliseconds = 0;
            this.obstaclePos =  this.obstaclePos_inital;
            this.obstacleOrient  = this.obstacleOrient_inital ;
            this.obstacleVelocity  = this.obstacleVelocity_inital ;
            
            this.robotPos  =  this.robotPos_inital;
            this.robotOrient  = this.robotOrient_inital ;
            this.robotVelocity  = this.robotVelocity_inital ;
            this.robotProperties = this.robotProperties_inital;
            
            this.targetPos  =  this.targetPos_inital;
            this.targetOrient  = this.targetOrient_inital ;
            this.targetVelocity = this.targetVelocity_inital;
            this.targetProperties = this.targetProperties_inital;
            this.converged = 0;
            this.goalPos  = this.goalPos_inital;       
            
        end

        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Save
        %   
        %   Save the simulation so we can track
        %   the way the world was over many experiments
        %   
        function save(this,filename)
            simMilliseconds = this.milliseconds;
            simObstaclePos = this.obstaclePos;
            simObstacleOrient = this.obstacleOrient;
            simObstacleVelocity = this.obstacleVelocity;
            
            simRobotPos = this.robotPos;
            simRobotOrient = this.robotOrient;
            simRobotVelocity = this.robotVelocity;
            simRobotProperties = this.robotProperties;
            
            simTargetPos = this.targetPos;
            simTargetOrient = this.targetOrient;
            simTargetVelocity = this.targetVelocity;
            simTargetProperties = this.targetProperties;
            
            simConverged = this.converged;
            simGoalPos = this.goalPos;       

            if exist(Name, 'file') == 2
                save(strcat('C:\justin\Dropbox\CISL\CISL_Run\status\',filename), 'simMilliseconds','-append');
            else
                save(strcat('C:\justin\Dropbox\CISL\CISL_Run\status\',filename), 'simMilliseconds');
            end
            
            save(strcat('C:\justin\Dropbox\CISL\CISL_Run\status\',filename), 'simObstaclePos','-append');
            save(strcat('C:\justin\Dropbox\CISL\CISL_Run\status\',filename), 'simObstacleOrient','-append');
            save(strcat('C:\justin\Dropbox\CISL\CISL_Run\status\',filename), 'simObstacleVelocity','-append');
            
            save(strcat('C:\justin\Dropbox\CISL\CISL_Run\status\',filename), 'simRobotPos','-append');
            save(strcat('C:\justin\Dropbox\CISL\CISL_Run\status\',filename), 'simRobotOrient','-append');
            save(strcat('C:\justin\Dropbox\CISL\CISL_Run\status\',filename), 'simRobotVelocity','-append');
            save(strcat('C:\justin\Dropbox\CISL\CISL_Run\status\',filename), 'simRobotProperties','-append');
            
            
            save(strcat('C:\justin\Dropbox\CISL\CISL_Run\status\',filename), 'simTargetPos','-append');
            save(strcat('C:\justin\Dropbox\CISL\CISL_Run\status\',filename), 'simTargetOrient','-append');
            save(strcat('C:\justin\Dropbox\CISL\CISL_Run\status\',filename), 'simTargetVelocity','-append');
            save(strcat('C:\justin\Dropbox\CISL\CISL_Run\status\',filename), 'simTargetProperties','-append');

            save(strcat('C:\justin\Dropbox\CISL\CISL_Run\status\',filename), 'simConverged','-append');
            save(strcat('C:\justin\Dropbox\CISL\CISL_Run\status\',filename), 'simGoalPos','-append');
        end
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   randomizeState
        %   
        %   Shuffle all of the world objects so the environment
        %   is all crazy and wacky.
        %   
        %   Those robots are going to be so confused!   
        %
        function randomState = randomizeState(this,numRobots, numObstacles,numTargets,configId)
            
            c = Configuration.Instance(configId);
            
            this.obstaclePos = zeros(numObstacles,3);
            this.obstacleOrient = [zeros(numObstacles,2) rand(numObstacles,1)*2*pi];
            this.obstacleVelocity = zeros(numObstacles,3);
            
            this.robotPos = zeros(numRobots,3);
            this.robotOrient = zeros(numRobots,3);
            this.robotVelocity = zeros(numRobots,3);

            % 
            robotTypes = c.robot_Type;
            
            % robotProperties [     currentTarget       rotationStep
            % mass      speedStep typeId reachId  advisorId ]
            this.robotProperties = [zeros(numRobots,1) ones(numRobots,1)*0.5 ones(numRobots,1) ones(numRobots,2) ...
                ones(numRobots,1)*c.robot_Reach zeros(numRobots,1)];
            numTypes = size(robotTypes);
            numTypes = numTypes(1);

            %rpid_currentTarget = 1;
            %rpid_rotationStep = 2;
            %rpid_mass = 3;
            %rpid_typeId = 4;
            %rpid_reachId = 5;            
            
            i = 1;
            arr = [this.rpid_rotationStep this.rpid_mass ...
                this.rpid_typeId this.rpid_reachId ];                        

            while i <= numRobots
                for j=1:numTypes
                    if(i <= numRobots)
                        this.robotProperties(i,arr) = robotTypes(j,:); 
                        i = i + 1;
                    end
                end
            end
            
            this.targetPos = zeros(numTargets,3);
            this.targetOrient = [zeros(numTargets,2) rand(numTargets,1)*2*pi];
            this.targetVelocity = zeros(numTargets,3);
            
            targetTypes = c.target_Type;
            numTypes = size(targetTypes);
            numTypes = numTypes(1);            

            this.targetProperties = [zeros(numTargets,1) 0.5*ones(numTargets,1) ones(numTargets,1) zeros(numTargets,1) ones(numTargets,1)*0.5 zeros(numTargets,1) zeros(numTargets,1)];
            
            i = 1;
            while i <= numTargets
                for j=1:numTypes
                    if(i <= numTargets)
 
                        this.targetProperties(i,this.tpid_weight) = targetTypes(j,2); %weight
                        this.targetProperties(i,this.tpid_type12) = targetTypes(j,3); %type
                        this.targetProperties(i,this.tpid_size) = targetTypes(j,1); %size
                        i = i + 1;
                    end
                end
            end

            
            this.goalPos = [0 0 0];

            
            %GetRandomPositions(this,borderSize,paddingSize)
            randomPositions = this.GetRandomPositions(...
                this.randomBorderSize,this.randomPaddingSize);
            
            %assign the random (non conflicting) locations, that meet
            %several awesome criteria
            preOffset = 0;
            for i=1:numObstacles,        
                this.obstaclePos(i,:) = [randomPositions(i+preOffset,:) 0];
            end
            
            preOffset = numObstacles;
            for i=1:numRobots,        
                this.robotPos(i,:) = [randomPositions(i+preOffset,:) 0];
            end
            
            preOffset = numObstacles+numRobots;

            for i=1:numTargets,        
                this.targetPos(i,:) = [randomPositions(i+preOffset,:) 0];
            end
            i = i+1;
            this.goalPos = [randomPositions(i+preOffset,:) 0];
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   GetGoalPos
        %   
        %   Return the position of the goal in 
        %   World space
        %   
        %   
        function val = GetGoalPos(this)
            (DEPRECATED) %This will crash when run
           val = this.goalPos;
        end
        function SetRobotAdvisor(this,robotId,advisorId)
            this.robotProperties(robotId,7) = advisorId;
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   GetRobotPos
        %   
        %   Return the robot (X,Y,Z) 
        %   
        %   
        %   
        function val = GetRobotPos(this,id )
           val = this.robotPos(id,:);
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   GetConvergence
        %   
        %   Have all the foraging targets been returned?
        %   
        %   
        %   
        function conv = GetConvergence(this)
            conv = this.converged;
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   GetRobotOrient
        %   
        %   Orientation of the robot
        %   
        %   
        %   
        function val = GetRobotOrient(this,id )
           val = this.robotOrient(id,:);
        end        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   SetRobotPos
        %   
        %   Set the position of the robot. 
        %   
        %   
        %   
        function val = SetRobotPos(this,posIn,id)
           this.robotPos(id,:) = posIn;
           val = 1;
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   SetRobotOrient
        %   
        %   Set the orientation for the robot
        %   
        %   
        %   
        function val = SetRobotOrient(this,newOrient,id)
            %TODO - capture assignment errors here.
            this.robotOrient(id,:) = newOrient;
            val = 1;
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   RobotCollide
        %   
        %   Description 
        %   
        %   
        %   
%{
        function collide = RobotCollide(this,newPoint,type,id)
            (DEPRECATED)
            %find the size to be used
            if type == 1
                mySize = this.obstacleSize;
            elseif type == 2
                mySize = this.robotSize;
            else %type == 3
                mySize = this.targetSize;
            end

            %Test against Robots (other robots)
            robDist = bsxfun(@minus,this.robotPos, newPoint);
            if type==2 ; robDist(id) = []; end; 
            robDist = robDist(:,1).^2 + robDist(:,2).^2 + robDist(:,3).^2;
            robDist = sqrt(robDist);
            minDistRobot = min(robDist);

            %Test against Targets
            targetDist = bsxfun(@minus,this.targetPos, newPoint);
            if  type == 3 ; targetDist(id) = []; end; 
            targetDist = targetDist(:,1).^2 + targetDist(:,2).^2 + targetDist(:,3).^2;
            targetDist = sqrt(targetDist);
            minTargetDist = min(targetDist);
            
            collide = 1;
        
        end
 %}
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   ValidPoint
        %   
        %   Test if a new point is valid, in terms of collision,
        %   if the object with the current id and type is taken
        %   and moved toward the newPoint.
        %   
        %   
        function valid = ValidPoint(this,newPoint,type,id,doCollide,partnerId)
            %find the size to be used
            myRobot1 = 0;
            myRobot2 = 0;
            myTargetId = 0;
            
            if type == 1
                mySize = this.obstacleSize;
                myVelocity = this.obstacleVelocity(id,:);
                myPos = this.obstaclePos(id,:);
                myMass = this.obstacleMass;
                myStrength = 1;
                
            elseif type == 2
                mySize = this.robotSize;
                myVelocity = this.robotVelocity(id,:);
                myPos = this.robotPos(id,:);
                myMass = this.robotMass;
                myStrength = this.robotProperties(id,3);
                
                if(this.groupPickup == 1)
                    myTargetId = this.robotProperties(id,1);
                    if(myTargetId >0)
                        if(this.targetProperties(myTargetId,this.ID_CARRIED_BY) ~= id && ...
                            this.targetProperties(myTargetId,this.ID_CARRIED_BY_2) ~= id)
                            myTargetId = 0;
                        end
                    end
                end
                
            else %type == 3
                mySize = this.targetSize;
                myVelocity = this.targetVelocity(id,:);
                myPos = this.targetPos(id,:);
                myMass = this.targetMass;
                myStrength = 1;

                if(this.groupPickup == 1)
                    myRobot1 = this.targetProperties(id,this.ID_CARRIED_BY);
                    myRobot2 = this.targetProperties(id,this.ID_CARRIED_BY_2);
                end
                
            end
            
            %Test against world boundaries
            if newPoint(1) - mySize < 0; valid=0; return; end;
            if newPoint(2) - mySize < 0; valid=0; return; end;
            if newPoint(3) < 0; valid=0; return; end;
            
            if newPoint(1) + mySize > this.WIDTH; valid=0; return; end;
            if newPoint(2) + mySize > this.HEIGHT; valid=0; return; end;
            if newPoint(3)  > this.DEPTH; valid=0; return; end;
            
            
            %Test against Obstacles
            obsDist = bsxfun(@minus,this.obstaclePos, newPoint);
            if  type == 1 ; obsDist(id,:) = [100 100 100]; end; 
            obsDist = obsDist(:,1).^2 + obsDist(:,2).^2 + obsDist(:,3).^2;
            obsDist = sqrt(obsDist);
            [minDist,closestObstacleId] = min(obsDist);

            %Test against Robots (other robots)
            robDist = bsxfun(@minus,this.robotPos, newPoint);
            if(partnerId > 0)
                robDist(partnerId,:)  = robDist(partnerId,:) + 400;
            end
            
            if(this.groupPickup == 1)
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
            targetDist = bsxfun(@minus,this.targetPos, newPoint);
            if  type == 3 ; targetDist(id,:) = [100 100 100]; end; 

            %next lines "moves" targets that are returned.
            targetDist = bsxfun(@plus,targetDist, (abs(this.targetProperties(:,1)).*100));

            %next lines "moves" targets that are being carried.
            if(this.boxPickup == 1 || this.groupPickup == 1)
                targetDist = bsxfun(@plus,targetDist, (abs(this.targetProperties(:,this.ID_CARRIED_BY)).*100));

            end
            if(this.groupPickup == 1) 
                targetDist = bsxfun(@plus,targetDist, (abs(this.targetProperties(:,this.ID_CARRIED_BY_2)).*100));
                %targetDist = bsxfun(@plus,targetDist, (abs(this.targetProperties(myTargetId ,this.ID_CARRIED_BY_2)).*100));
                
            end            
            
            targetDist = targetDist(:,1).^2 + targetDist(:,2).^2 + targetDist(:,3).^2;
            targetDist = sqrt(targetDist);
            [minTargetDist,closestTargetId] = min(targetDist) ;            
            
            if minDist < mySize + this.obstacleSize
                valid = 0;
                %closestId = find(obsDist, minDist, 'first');

                %preform a collision and update the velocities
                physicsArray1 = [this.obstaclePos(closestObstacleId,:) this.obstacleVelocity(closestObstacleId,:) this.obstacleSize this.obstacleMass];
                physicsArray2 = [myPos myVelocity mySize myMass];
                [physicsArray1,physicsArray2] = this.Collide(physicsArray1,physicsArray2);   
                if (doCollide == 1)
                    this.obstaclePos(closestObstacleId,:) = physicsArray1(1:3);
                    this.obstacleVelocity(closestObstacleId,:) = physicsArray1(4:6);
                end
                myPos = physicsArray2(1:3);
                myVelocity = physicsArray2(4:6);
                return;
            end
            
            if minDistRobot < mySize + this.robotSize
                valid = 0;
                %closestId = find(robDist, minDistRobot, 'first');

                %preform a collision and update the velocities
                physicsArray1 = [this.robotPos(closestRobotId,:) this.robotVelocity(closestRobotId,:) this.robotSize this.robotMass];
                physicsArray2 = [myPos myVelocity mySize myMass];
                [physicsArray1,physicsArray2] = this.Collide(physicsArray1,physicsArray2);
                if(doCollide == 1)
                    this.robotPos(closestRobotId,:) = physicsArray1(1:3);
                    this.robotVelocity(closestRobotId,:) = physicsArray1(4:6);
                end
                myPos = physicsArray2(1:3);
                myVelocity = physicsArray2(4:6);
            
                return;
            end
            
            if minTargetDist < mySize + this.targetSize
                valid = 0;
                %closestId = find(targetDist, minTargetDist, 'first');
                
                %preform a collision and update the velocities
                boxMass = this.targetProperties(closestTargetId,2);
                
                %Alter weights so a weak robot can't budge a heavy box
                robotType = this.robotProperties(id,5);
                boxType = this.targetProperties(closestTargetId,3);
                if(boxType == 2) 
                    %if the box is heavy
                    if(robotType == 2 || robotType == 3) 
                        %And you are weak, and can't budge it
                        valid = 0;
                        return;    
                    end
                end

                physicsArray1 = [this.targetPos(closestTargetId,:) this.targetVelocity(closestTargetId,:) this.targetSize boxMass];
                physicsArray2 = [myPos myVelocity mySize myMass*myStrength];
                [physicsArray1,physicsArray2] = this.Collide(physicsArray1,physicsArray2);
                if(doCollide == 1)
                    this.targetPos(closestTargetId,:) = physicsArray1(1:3);
                    this.targetVelocity(closestTargetId,:) = physicsArray1(4:6);
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
        %   
        %   
        %   
        function [phyResult1,phyResult2]= Collide(this,physicsArray1,physicsArray2)
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

          %  b = [0 1 0];
            b = b(:)./sqrt(b(1)^2 + b(2) ^2 + b(3) ^2);

            v1a = ((v1*b)*b)';
            v1b = v1 - v1a;

            v2a = ((v2*b)*b)';
            v2b = v2 - v2a;

            %mo1a = v1a*m1;
            %mo2a = v2a*m2;

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
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   AssignRobot
        %   
        %   Assign a certain robot to a specific task
        %           
        function AssignFreeRobot(this,targetId)
            freeRobots = this.robotProperties(:,1) == 0;
            
            [amount,index] = max(freeRobots);
            if(amount >0)
                if(this.robotProperties(index(1),1) == 0)
                    %disp('helper assigned');
                    this.UpdateRobotTarget(index(1),targetId);
                end
            end
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   MoveTarget
        %   
        %   Apply power, given by a robot, to a target
        %   in a certain direction, relative to the robot,
        %   all using a certain powerAndle (distance, angle).
        %   
        %   
        function targetVelocity = MoveTarget(this,robotId,targetId,powerAngle)
            
            %TODO - code these
            if(powerAngle >= -10 )
                       -10;   % target closest box
                       -20;   % target second closest box
                       -30;   % grip a box
                       -40;   % stop gripping a box / targeting a box
            end

            %make sure distance is close enough
            if(targetId == 0)
                targetVelocity = [0 0 0];
                return;
            end
            
            robotType = this.robotProperties(robotId,5);
            boxType = this.targetProperties(targetId,3);
            
            if( this.groupPickup ==0)
                if(boxType == 2) 
                    % heavy box
                    if(robotType == 2 || robotType == 3)
                        %weak robot
                        targetVelocity = [0 0 0];
                        return;    
                    end
                end
            end
            
            posDiff = this.robotPos(robotId,:) - this.targetPos(targetId,:);
            posDiff = sqrt(posDiff.^2);
            posDiff = sum(posDiff);
            robotReach = this.robotProperties(robotId,6);
            
            if(posDiff <= robotReach)
                if(this.boxPickup == 1)
                    if(powerAngle == -1) %if we are dropping the box
                        this.targetProperties(targetId,this.ID_CARRIED_BY) = 0;
                    else
                        this.targetProperties(targetId,this.ID_CARRIED_BY) = robotId;
                    end
                    
                elseif(this.groupPickup == 1)
                    %If we are not gripping the box:
                    if(powerAngle ~= -1) 
                        
                        if(this.targetProperties(targetId,this.ID_CARRIED_BY_2) ~= robotId)
                            if(this.targetProperties(targetId,this.ID_CARRIED_BY) == 0)
                                this.targetProperties(targetId,this.ID_CARRIED_BY) = robotId; %grip slot 1
                            else
                                if(this.targetProperties(targetId,this.ID_CARRIED_BY) ~= robotId)
                                    if(this.targetProperties(targetId,this.ID_CARRIED_BY_2) == 0)
                                        this.targetProperties(targetId,this.ID_CARRIED_BY_2) = robotId; %slot 2
                                    end
                                end
                            end
                        end

                    else
                        %disp([strcat(num2str(robotId),' dropping task: ',num2str(targetId))])
                        if (this.targetProperties(targetId,this.ID_CARRIED_BY) == robotId)  
                            this.targetProperties(targetId,this.ID_CARRIED_BY) = 0;
                        end
                        if (this.targetProperties(targetId,this.ID_CARRIED_BY_2) == robotId)  
                            this.targetProperties(targetId,this.ID_CARRIED_BY_2) = 0;
                        end
                        % Move away 
                        newPos = this.targetPos(targetId,1:3);
                        if(this.ValidPoint(newPos+ [0.5 0.5 0],this.TYPE_ROBOT,robotId,0,0))
                            this.robotPos(robotId,1:3) = newPos+ [0.5 0.5 0];
                        elseif(this.ValidPoint(newPos+ [-0.5 0.5 0],this.TYPE_ROBOT,robotId,0,0))
                            this.robotPos(robotId,1:3) = newPos+ [-0.5 0.5 0];
                        elseif(this.ValidPoint(newPos+ [0.5 -0.5 0],this.TYPE_ROBOT,robotId,0,0))
                            this.robotPos(robotId,1:3) = newPos+ [0.5 -0.5 0];
                        elseif(this.ValidPoint(newPos+ [-0.5 -0.5 0],this.TYPE_ROBOT,robotId,0,0))
                            this.robotPos(robotId,1:3) = newPos+ [-0.5 -0.5 0];
                        end
                        
                        
                    end
                else
                    
                    targetMass = this.targetProperties(targetId,2);
                    robotStrength = this.robotProperties(robotId,3);
                    amount = powerAngle(1);
                    angle = powerAngle(2);
                    amount = amount*robotStrength/targetMass;
                    addVelocity = [amount*cos(angle ) amount*sin(angle ) 0];

                    this.targetVelocity(targetId,:) = addVelocity;
                end
            end
            targetVelocity = this.targetVelocity(targetId,:);
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   MoveRobot
        %   
        %   Move the robot forward a certain amount and with a
        %   certain amount of rotation.
        %   
        %   
        function [orientVelocity, currentVelocity] = MoveRobot(this,id,amount,rotation)
            %find a new orientation 
            newOrient =[ 0 0 mod(this.robotOrient(id,3) + rotation,2*pi)];
            
            %find a new velocity
            addVelocity = [amount*cos(newOrient(3)) amount*sin(newOrient(3)) 0];
            currentVelocity = this.robotVelocity(id,:);
            
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
            
            this.SetRobotOrient(newOrient,id);

            this.robotVelocity(id,:) = currentVelocity;
            orientVelocity = [0 0 rotation];
        end
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   UpdateRobotTarget
        %   
        %   set the RobotId of a certain target to be
        %   equal to id.
        %   
        %   
        function UpdateRobotTarget(this,id,targetId)
            this.robotProperties(id,1) = targetId;
            if(targetId > 0 )
                assigned = this.robotProperties(:,1) == targetId;
                totalOnTask = sum(assigned);
                if(totalOnTask >2)
                    assigned
                    id
                    targetId
                    disp('Too many robots on a task!');
                    %rolled back gracefully
                    this.robotProperties(id,1) = 0;
                else
                    this.targetProperties(targetId,this.tpid_lastRobotToCarry) = id;
                end
            end
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   RunPhysics
        %   
        %   Iterative. Run one cycle of the physics engine.
        %   
        %   
        %   
        function val = RunPhysics(this,timeMilliseconds)
            %deal with inst velocity
            %next lines "moves" targets that are being carried.
        
            
            %apply friction
            decay = 0;
            [ numRobots, dimensions] = size( this.robotPos);
            for i=1:numRobots
                newPos = this.robotPos(i,:) + this.robotVelocity(i,:);
                
                carrierOther = 0;
                carrierMe = 0;
                
                if(this.groupPickup == 1 && this.robotProperties(i,1)> 0)
                    tid = this.robotProperties(i,1);
                    % assign the current robot and helper
                    if(this.targetProperties(tid,this.ID_CARRIED_BY) ==i)
                        carrierMe =this.targetProperties(tid,this.ID_CARRIED_BY) ;
                        carrierOther =this.targetProperties(tid,this.ID_CARRIED_BY_2) ;
                    else
                        carrierMe =this.targetProperties(tid,this.ID_CARRIED_BY_2) ;
                        carrierOther =this.targetProperties(tid,this.ID_CARRIED_BY) ;
                    end
                end
                
                if this.ValidPoint(newPos,this.TYPE_ROBOT,i,1,carrierOther) == 1 

                    if(this.groupPickup == 1 && this.robotProperties(i,1)> 0)
                        
                        weakPushingStrong = 0;
                        
                        if(carrierMe > 0)
                        % If you have a box, we want to know if you are weak
                        % pushing a heavy box
                            robotType = this.robotProperties(carrierMe,5);
                            boxType = this.targetProperties(tid ,3);
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
                                        this.targetPos(this.robotProperties(i,1),:) = newPos + [0.01 0.01 0];
                                        this.robotPos(i,:) = newPos;
                                    end
                                else
                                    %Move helper, if we have one
                                    this.targetPos(this.robotProperties(i,1),:) = newPos + [0.01 0.01 0];                                         
                                    this.robotPos(i,:) = newPos;
                                    this.robotPos(carrierOther,:) = newPos;
                                end
                            
                        else
                             this.robotPos(i,:) = newPos;
                        end
                    else
                        this.robotPos(i,:) = newPos;
                    end
                    
                    %If we are stuck in a wall, move off it
                %elseif (this.ValidPoint(this.robotPos(i,:),this.TYPE_ROBOT,i,0,0) == 0 )
                    %disp('getting out of here!') ;   
                %    this.robotPos(i,:) = newPos;
                end                
                this.robotVelocity(i,:) = this.robotVelocity(i,:)*decay;
            end
            
            [ numTargets, dimensions] = size( this.targetPos);
            if(this.groupPickup == 0)
                for i=1:numTargets
                    newPos = this.targetPos(i,:) + this.targetVelocity(i,:);
                    if(this.boxPickup == 1 )
                        if(this.targetProperties(i,this.ID_CARRIED_BY) ~= 0)
                            robId = this.targetProperties(i,this.ID_CARRIED_BY);
                            newPos = this.robotPos(robId,:) + [0.01 0.01 0];
                            this.targetPos(i,:) = newPos;
                        end
                        
                    end
                    
                    if(this.groupPickup == 1 )
                        %only test for collision if you are NOT being
                        %carried, otherwise it's a waste of time
                        if(this.targetProperties(i,this.ID_CARRIED_BY) == 0 ...
                                && this.targetProperties(i,this.ID_CARRIED_BY_2) == 0)
                            if this.ValidPoint(newPos,this.TYPE_TARGET,i,1,0) == 1
                                this.targetPos(i,:) = newPos;
                            end
                        end
                    else
                        if this.ValidPoint(newPos,this.TYPE_TARGET,i,1,0) == 1
                            this.targetPos(i,:) = newPos;
                        end
                        
                    end
                    this.targetVelocity(i,:) = this.targetVelocity(i,:)*decay;
                end
            end
            
            %see if a box is magically returned
            targetDistanceToGoal = bsxfun(@minus,this.targetPos,this.goalPos);
            targetDistanceToGoal = targetDistanceToGoal.^2;
            targetDistanceToGoal = sum(targetDistanceToGoal,2);
            targetDistanceToGoal = sqrt(targetDistanceToGoal);
            targetDistanceToGoalBarrier = targetDistanceToGoal - (this.targetSize + this.goalSize);
            i = 1;
            [numTargets,rows] = size(targetDistanceToGoal);
            
            %targetDistanceToGoalBarrier(2)
            while i <= numTargets
                if(targetDistanceToGoalBarrier(i) < -this.targetSize)
                    this.targetProperties(i) = 1;
                    %if the box is being carried, we drop it here.
                    if(this.boxPickup == 1 || this.groupPickup == 1)
                        this.targetProperties(i,this.ID_CARRIED_BY) = 0;
                    end    
                    if(this.groupPickup == 1)
                        this.targetProperties(i,this.ID_CARRIED_BY_2) = 0;
                    end    
                    
                end
                i = i + 1;
            end
            
            targetsReturned = sum(this.targetProperties(:,1));
            if targetsReturned == numTargets
                this.converged = this.converged +1;
                if(this.converged > 2)
                    this.converged = 2;
                end
            end
            
            val = 1;
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   GetSnapshot
        %   
        %   Get a copy of the entire world.
        %   
        %   
        %   
        function [robPos, robOrient, millis, obstaclePos,targetPos,goalPos,targetProperties,robotProperties ] ...
                = GetSnapshot(this)
            robPos = this.robotPos;
            robOrient = this.robotOrient;
            obstaclePos = this.obstaclePos;
            targetPos = this.targetPos;
            millis = this.milliseconds;
            goalPos = this.goalPos;
            targetProperties = this.targetProperties;
            robotProperties = this.robotProperties;
            
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   GetTargetState
        %   
        %   Get all the targets in a Nx6 array.
        %   
        %   
        %   
        function targetState =  GetTargetState(this)
                targetState = [this.targetPos this.targetOrient];
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   GetTargetObstacles
        %   
        %   Get all the obstacles in a Nx6 array.        
        %   
        %   
        %   
        function obstacleState =  GetObstacleState(this)
                obstacleState = [this.obstaclePos this.obstacleOrient];
        end
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   GetRandomPositions
        %   
        %   Generate random poisitions for the world objects
        %   given a set of world properties
        %   
        %   
        function randomPositions = GetRandomPositions(this,borderSize,paddingSize)
            worldWidth = this.WIDTH;
            worldHeight = this.HEIGHT;
            border = borderSize;
            padding = paddingSize;
            objectRadius = 0.5 + padding;

            slotH = floor( (worldWidth - border*2)/ (objectRadius+paddingSize));
            slotV = floor((worldHeight - border*2)/ (objectRadius+paddingSize));

            positions = zeros(slotH*slotV,2);

            x = 1;
            hor = combnk(1:slotH,1);
            hor= randperm(length(hor));
            for i=1:slotH,
                ver = combnk(1:slotV,1);
                ver= randperm(length(ver))';
                for j=1:slotV,
                    positions(x,:) =  [hor(i) ver(j)];
                    x= x+ 1;
                end
              
            end
            
            posRandom =  zeros(slotH*slotV,2);

            for z=1:3,
                order = randperm(length(1:(slotH*slotV)))';
                for i=1:length(order),
                    posRandom(i,:) = positions(order(i),:);    
                end
                positions = posRandom;
            end
            
            positions = positions.*(objectRadius+paddingSize);
            positions = bsxfun(@plus,positions,[borderSize borderSize]);
            randomPositions = positions;
        end
        
    end
    
end

