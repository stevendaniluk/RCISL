classdef robotState < handle
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % 
    %   Class Name
    %   
    %   Description 
    %   
    %   
    %   
    %ROBOTSTATE
    % a robot state is all the information a robot has about:
    % - It's environment
    % - its learning (parametric variables)
    
    properties
        %positions and orientations and types of all members relative to me
        %robots = [];
        
        %boundry walls relative to me
        %my position and orientation
        %target positions and orientations
        %robot = [];
        %targets = [];
        %obstacles = [];
        %goal = [];

        id = 0;
        WorldState = [];
        
        %targets_saved = [];
        %robot_saved = [];
        %obstacles_saved = [];
        %goal_saved = [];
        %borderOfWorld_saved = [];
        
        noiseLevel = 0;
        
        sensor_robPos = []; 
        sensor_robOrient = [];
        sensor_obstaclePos = [];
        sensor_targetPos = [];
        sensor_goalPos = [];

        sensor_millis = [];
        sensor_targetProperties = [];
        sensor_robotProperties = [];
        
        saved_sensor_robPos = []; 
        saved_sensor_robOrient = [];
        saved_sensor_obstaclePos = [];
        saved_sensor_targetPos = [];
        saved_sensor_goalPos = [];

        saved_sensor_millis = [];
        saved_sensor_targetProperties = [];
        saved_sensor_robotProperties = [];

        
        %'CURRENT' sensor values
        saved_sensor_current_targets = []; 
        saved_sensor_current_obstacles = []; 
        saved_sensor_current_goal = []; 
        saved_sensor_current_borderOfWorld = [];  
        saved_sensor_current_robot = []; 
        saved_sensor_current_targetProperties = [];
        saved_sensor_current_robotProperties = [];

        sensor_current_targets = [];
        sensor_current_obstacles= [];
        sensor_current_goal= [];
        sensor_current_borderOfWorld = [];
        sensor_current_robot= [];
        sensor_current_targetProperties= [];
        sensor_current_robotProperties= [];
        
        
        true_robPos = [];
        true_robOrient= [];
        true_millis = [];
        true_obstaclePos = [];
        true_targetPos = [];
        true_goalPos = [];
        true_targetProperties = [];
        true_robotProperties = [];        

        true_targets = [];
        true_obstacles = [];
        true_goal = [];
        true_borderOfWorld = [];
        true_robot = [];

        saved_true_robPos = [];
        saved_true_robOrient= [];
        saved_true_millis = [];
        saved_true_obstaclePos = [];
        saved_true_targetPos = [];
        saved_true_goalPos = [];
        saved_true_targetProperties = [];
        saved_true_robotProperties = [];        

        saved_true_targets = [];
        saved_true_obstacles = [];
        saved_true_goal = [];
        saved_true_borderOfWorld = [];
        saved_true_robot = [];
        
        
        
        % Rows: robot id, Cols: task Choice
        %belief_taskChoices = [];
        useParticleFilter = 0;
        particleFilter;
        
        configId = 0;
        targetOld = -1;
        %borderOfWorld = [left down right up];
        %borderOfWorld = [0 0 0 0];
        belief_task = [0 0];
        belief_self = [0 0 0];
        belief_goal = [0 0];

        
        belief_distance_task = [];
        belief_distance_self = [];
        belief_distance_goal = [];
        
        
        typeLabel = 'xx';
        
        newOrient = 0;
        newVelocity = 0;
        targetAdj = 0;
        
        cisl = 0;
        lastActionLabel = '';
        i_robot;
    end
    
    methods
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
        function this = robotState(id,WorldStateIn,configId, CISL,inst_robot)
           %ptr = libpointer('robotState',this);
           this.i_robot = inst_robot;
           this.particleFilter = [ParticleFilter();ParticleFilter();ParticleFilter()];

           this.configId = configId;
           this.cisl = CISL;
           this.WorldState=WorldStateIn;
           this.id = id;
           
           c = Configuration.Instance(configId);
           this.useParticleFilter = c.particle_Used;
           this.noiseLevel = c.robot_NoiseLevel;
           this.noiseLevel 
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
        function robState = GetTeamRobot(this,advisorId)
            %rPtr = this.s_robotTeam.Get([advisorId]);
            rob = this.i_robot.GetRobotFromTeam(advisorId);
            robState = rob.RobotState;
        end
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
        function  saveState(this)

            this.saved_sensor_robPos = this.sensor_robPos; 
            this.saved_sensor_robOrient = this.sensor_robOrient;
            this.saved_sensor_obstaclePos = this.sensor_obstaclePos;
            this.saved_sensor_targetPos = this.sensor_targetPos;
            this.saved_sensor_goalPos = this.sensor_goalPos;

            this.saved_sensor_millis = this.sensor_millis;
            this.saved_sensor_targetProperties = this.sensor_targetProperties;
            this.saved_sensor_robotProperties = this.sensor_robotProperties;
        
            %update our 'current' info
            this.saved_sensor_current_targets = this.sensor_current_targets ;
            this.saved_sensor_current_obstacles = this.sensor_current_obstacles;
            this.saved_sensor_current_goal = this.sensor_current_goal;
            this.saved_sensor_current_borderOfWorld =  this.sensor_current_borderOfWorld ;
            this.saved_sensor_current_robot = this.sensor_current_robot;
            this.saved_sensor_current_targetProperties = this.sensor_current_targetProperties;
            this.saved_sensor_current_robotProperties = this.sensor_current_robotProperties;
            
            %--------------------------------------------
            this.saved_true_robPos = this.true_robPos; 
            this.saved_true_robOrient = this.true_robOrient;
            this.saved_true_obstaclePos = this.true_obstaclePos;
            this.saved_true_targetPos = this.true_targetPos;
            this.saved_true_goalPos = this.true_goalPos;

            this.saved_true_millis = this.true_millis;
            this.saved_true_targetProperties = this.true_targetProperties;
            this.saved_true_robotProperties = this.true_robotProperties;
        
            %update our 'current' info
            this.saved_true_targets = this.true_targets ;
            this.saved_true_obstacles = this.true_obstacles;
            this.saved_true_goal = this.true_goal;
            this.saved_true_borderOfWorld =  this.true_borderOfWorld ;
            this.saved_true_robot = this.true_robot;
            this.saved_true_targetProperties = this.true_targetProperties;
            this.saved_true_robotProperties = this.true_robotProperties;
            
            
            
            
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
        function [targets,obstacles,goal,borderOfWorld,robot,targetProperties,robotProperties] = GetCurrentState(this)
            targets = this.sensor_current_targets;
            obstacles= this.sensor_current_obstacles;
            goal = this.sensor_current_goal;
            borderOfWorld = this.sensor_current_borderOfWorld;
            robot = this.sensor_current_robot;
            targetProperties= this.sensor_current_targetProperties;
            robotProperties= this.sensor_current_robotProperties;
            
        end
        
        function [targets,obstacles,goal,borderOfWorld,robot,targetProperties,robotProperties] = GetTrueCurrentState(this)
            targets = this.true_targets;
            obstacles= this.true_obstacles;
            goal = this.true_goal;
            borderOfWorld = this.true_borderOfWorld;
            robot = this.true_robot;
            targetProperties= this.true_targetProperties;
            robotProperties= this.true_robotProperties;
            
            
        end
                
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
        function [targets,obstacles,goal,borderOfWorld,robot,targetProperties,robotProperties] = GetSavedState(this)
            targets = this.saved_sensor_current_targets;
            obstacles= this.saved_sensor_current_obstacles;
            goal = this.saved_sensor_current_goal;
            borderOfWorld = this.saved_sensor_current_borderOfWorld;
            robot = this.saved_sensor_current_robot;
            targetProperties= this.saved_sensor_current_targetProperties;
            robotProperties= this.saved_sensor_current_robotProperties;
            
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
        function [targets,obstacles,goal,borderOfWorld,robot,targetProperties,robotProperties] = GetTrueSavedState(this)
            targets = this.saved_true_targets;
            obstacles= this.saved_true_obstacles;
            goal = this.saved_true_goal;
            borderOfWorld = this.saved_true_borderOfWorld;
            robot = this.saved_true_robot;
            targetProperties= this.saved_true_targetProperties;
            robotProperties= this.saved_true_robotProperties;
            
        end
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
        function [targets,obstacles,goal,borderOfWorld,robot,targetProperties] = ...
                CalculateCurrentState(this)
                        targetProperties = this.sensor_targetProperties;
            ws = this.WorldState;
            
            obsPosRaw = this.sensor_obstaclePos;
            sz = size(obsPosRaw );
            obsOrientRaw = zeros(sz(1),3);

            targetPosRaw = this.sensor_targetPos;
            sz = size(targetPosRaw );
            targetOrientRaw = zeros(sz(1),3);

            goalPosRaw = this.sensor_goalPos;
            
            robotPosRaw = this.sensor_robPos(this.id,:);
            robotOrientRaw= this.sensor_robOrient(this.id,:) ;
            
            robot = [robotPosRaw robotOrientRaw];
            borderOfWorld = [robot(1) robot(2) ws.WIDTH-robot(1) ws.HEIGHT-robot(2)];
           
            targets = [targetPosRaw targetOrientRaw];
            targets = bsxfun(@minus, targets,robot);
            distance =  targets(:,1:3);
            distance = distance.^2;
            targets = [ sum(distance,2) targets];

            %obstacles include robots
            otherRobotsPos = this.sensor_robPos;
            otherRobotsOrient = this.sensor_robOrient;
            
            %obstacles include 'other' targets
            taskId = this.cisl.GetTask();
            otherTargetsPos = targetPosRaw;
            otherTargetsOrient = targetOrientRaw;
            
            %remove objects we should not worry about as obstacles. This
            %includes the current robot and any obstacles
            if(taskId > 0)
                ID_CARRIED_BY = 4;
                ID_CARRIED_BY_2 = 7;
                assistRobots = targetProperties(taskId, [ID_CARRIED_BY ID_CARRIED_BY_2] );

                if(sum(assistRobots  > 0,2) > 1)
                    otherRobotsPos(assistRobots ,:) = [];
                    otherRobotsOrient(assistRobots ,:) = [];
                else
                    otherRobotsPos(this.id,:) = [];
                    otherRobotsOrient(this.id,:) = [];
                end
                
                otherTargetsPos (taskId,:) = [];
                otherTargetsOrient (taskId,:) = [];
            else
                otherRobotsPos(this.id,:) = [];
                otherRobotsOrient(this.id,:) = [];
                
            end
            
            obstacles = [obsPosRaw obsOrientRaw; otherRobotsPos otherRobotsOrient; otherTargetsPos otherTargetsOrient];
            %obstacles = [obsPosRaw obsOrientRaw];
            obstacles = bsxfun(@minus, obstacles,robot);
            
            
            distance =  obstacles(:,1:3);
            distance = distance.^2;
            obstacles = [ sqrt(sum(distance,2)) obstacles];
           
            %this.goal = ws.GetGoalPos();
            goal = goalPosRaw;
            goal = goal - robot(1:3);
            distance =  goal(1:3);
            distance = distance.^2;
            goal = [ sqrt(sum(distance,2)) goal];            


        end
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   NOTE: in position arrays, the first field is NOT the distance
        function [robPos, robOrient, millis, obstaclePos,targetPos,goalPos,targetProperties,robotProperties ] ...
                = GetSnapshot(this)

                sz = size(this.sensor_robPos);
                %if this is our first sensor reading, update our sensors
                % by 'reading' values from the world
                if(sz(1) == 0)
                    this.update();
                end
            
                %return our belief of the world
                robPos = this.sensor_robPos;
                robOrient= this.sensor_robOrient;
                millis = this.sensor_millis;
                obstaclePos = this.sensor_obstaclePos;
                targetPos = this.sensor_targetPos;
                goalPos = this.sensor_goalPos;
                targetProperties = this.sensor_targetProperties;
                robotProperties = this.sensor_robotProperties;
        end
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
        function [robPos, robOrient, millis, obstaclePos,targetPos,goalPos,targetProperties,robotProperties ] ...
                = GetTrueSnapshot(this)

                sz = size(this.sensor_robPos);
                %if this is our first sensor reading, update our sensors
                % by 'reading' values from the world
                if(sz(1) == 0)
                    this.update();
                end
            
                %return our belief of the world
                robPos = this.true_robPos;
                robOrient= this.true_robOrient;
                millis = this.true_millis;
                obstaclePos = this.true_obstaclePos;
                targetPos = this.true_targetPos;
                goalPos = this.true_goalPos;
                targetProperties = this.true_targetProperties;
                robotProperties = this.true_robotProperties;
        end        
        
        
        function result = EvaluateConstraints(this,targetProperties,robotProperties)
            result = 0;

            %check after each iteration for this constraint
            carriedBy = abs(targetProperties(:,4));
            amountCarried = carriedBy - this.id;
            amountCarried = (amountCarried == 0);
            amountCarried = sum(amountCarried,1);
           
            if(amountCarried > 1)
                disp('robotState error');
                result=1;
                robotProperties
                targetProperties
                this.id
                error('!A robot has picked up two boxes');
                return;
            end
            
            
            if(amountCarried ==1)
   
                %check after each iteration for this constraint
                carriedByMe = carriedBy - this.id;
                carriedByMe = (carriedByMe == 0);

                 
                [carriedIndex,ones]=find(carriedByMe,1);
                targetId = robotProperties(this.id,1);
                if(targetId  ~= carriedIndex)
                    result=1;
                    robotProperties
                    targetProperties
                    this.id
                    
                    error('!Robot Targeting a new box, but it already has one');
                end

            end

        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
        function val = update(this)
            
           
            [robPos, robOrient, millis, obstaclePos,targetPos,goalPos,targetProperties,robotProperties ] = ...
            this.WorldState.GetSnapshot();


            this.sensor_robPos = robPos;
            this.sensor_robOrient= robOrient;
            this.sensor_millis = millis;
            this.sensor_obstaclePos = obstaclePos;
            this.sensor_targetPos = targetPos;
            this.sensor_goalPos = goalPos;
            this.sensor_targetProperties = targetProperties;
            this.sensor_robotProperties = robotProperties;
         
            
            result = this.EvaluateConstraints(targetProperties,robotProperties);
            if( result == 1)
                error('Terminating');
            
            end
            
            %Now we update our 'truth' states
            [targets,obstacles,goal,borderOfWorld,robot,targetProperties] = this.CalculateCurrentState();
            
            
            this.true_robPos = robPos;
            this.true_robOrient= robOrient;
            this.true_millis = millis;
            this.true_obstaclePos = obstaclePos;
            this.true_targetPos = targetPos;
            this.true_goalPos = goalPos;
            this.true_targetProperties = targetProperties;
            this.true_robotProperties = robotProperties;
            
            this.true_targets = targets;
            this.true_obstacles = obstacles;
            this.true_goal = goal;
            this.true_borderOfWorld = borderOfWorld;
            this.true_robot = robot;
            this.true_targetProperties = targetProperties;
                        
            
           
           %Apply Noise to all the sensor values
            if(this.noiseLevel > 0)
                this.ApplyNoise();
            end
            
            if(this.useParticleFilter >0)
                this.ApplyParticleFilter();
            end
            
            
            taskId = this.cisl.GetTask();
            this.belief_self = [this.sensor_robPos(this.id,1:2) this.sensor_robOrient(this.id,3)];
            if(taskId > 0)
                this.belief_task = this.sensor_targetPos(taskId,1:2) ;
            end
            this.belief_goal = this.sensor_goalPos(1:2);
           
            
            % track some metrics related to particle filter performance
            this.belief_distance_self = robPos(this.id,1:2) - this.sensor_robPos(this.id,1:2);
            this.belief_distance_goal = goalPos(1:2) - this.sensor_goalPos(1:2);
            if(taskId > 0)
                this.belief_distance_task = targetPos(taskId,1:2) - this.belief_task (1:2);
            else
                this.belief_distance_task = [0 0];
            end
            
            
            %Now we update our 'CURRENT' state information
            [targets,obstacles,goal,borderOfWorld,robot,targetProperties] = this.CalculateCurrentState();

            this.sensor_current_targets = targets;
            this.sensor_current_obstacles = obstacles;
            this.sensor_current_goal = goal;
            this.sensor_current_borderOfWorld = borderOfWorld;
            this.sensor_current_robot = robot;
            this.sensor_current_targetProperties = targetProperties;
            this.sensor_current_robotProperties = robotProperties;
            
            
    
            
            val = 1;
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
        function ApplyParticleFilter(this)
            taskId = this.cisl.GetTask();
            
            %if we have no task, we don't update the filter.
            %This function adjusts our sensor values for certain objects (but
            %not all!)
            %Currently this is
            %   - Position of the closest target
            %   - Orientation of ourself
            %   - the robots position
            %   - the goal position
            %   - the xy position
           
            rPos = this.sensor_robPos(this.id,1:2);
            rOrient = this.sensor_robOrient(this.id,3);
            
            %rObstacle = this.sensor_obstaclePos(1:2);
            tCarriedByMe  =0;
            validMove = 1;
            
            if taskId > 0
                tPos = this.sensor_targetPos(taskId,1:2) ;
                tCarriedBy = this.sensor_targetProperties(taskId,4);
                tCarriedBy2 = this.sensor_targetProperties(taskId,7);
                rType = this.sensor_robotProperties(this.id,5);
                tType = this.sensor_targetProperties(taskId,3);
                rHasTeammate = this.sensor_targetProperties(taskId,4) > 0 ...
                    && this.sensor_targetProperties(taskId,7) > 0;
                validMove = 1;
                if(tType == 2) 
                    %if the box is heavy
                    if(rType == 2 || rType == 3) 
                        if(rHasTeammate == 0)
                        %And you are weak, and can't budge it, because you
                        %are alone . . .
                            validMove = 0;
                        end
                    end
                end
                if(tCarriedBy  == this.id || tCarriedBy2  == this.id )
                    tCarriedByMe = 1;
                else
                    tCarriedByMe = 0;
                end
            else
                
                tPos = [0 0];
            end
            tGoal = this.sensor_goalPos(1:2);
            
            %rPos = [1 1];
            %tPos = [1 1];
            %tGoal = [1 1];
            
            
            pfVec = [rPos rOrient; tPos 0; tGoal 0];
            %pfBorder = [10 10 4*pi 10 10 10 10; 0 0 0 0 0 0 0];
            pfBorderTop = [20 20 4*pi; 20 20 0; 20 20 0];
            pfBorderBottom = [0 0 0; 0 0 0; 0 0 0];
            
            targMove = [0 0];
            selfMove = [0 0 0];
            goalMove = [0 0];

            if(sum(this.targetAdj) ~= 0)
                targMove = targMove + this.targetAdj(1:2);
                this.targetAdj =0;
            end
            
            if(sum(this.newOrient) ~= 0)
                selfMove(3) = selfMove(3) + this.newOrient(3);
                if(selfMove(3) > 2*pi)
                    selfMove(3) = selfMove(3) - 2*pi;
                end
                this.newOrient = 0;
            end

            if(sum(this.newVelocity) ~= 0 && validMove == 1)
                %targMove = targMove - this.newVelocity(1:2);
                %goalMove = goalMove - this.newVelocity(1:2);
                selfMove(1:2) = this.newVelocity(1:2);
                if(tCarriedByMe == 1)
                    targMove = selfMove(1:2);
                end
                this.newVelocity = 0;
            end
            pfAction = [selfMove; targMove 0; goalMove 0];

            
            %pfAction = 0;
            pfSample = this.GetFilteredValues(pfVec,pfAction,pfBorderTop,pfBorderBottom,taskId);

            this.sensor_robPos(this.id,1:2) = pfSample(1,1:2);
            this.sensor_robOrient(this.id,3) = pfVec(1,3);
            
            %rObstacle = this.sensor_obstaclePos(1:2);
            if taskId > 0
                this.sensor_targetPos(taskId,1:2) =  pfSample(2,1:2);
            end
            
            this.sensor_goalPos(1:2) = pfSample(3,1:2);
            
        
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
        function values = GetFilteredValues(this,reading,action,boundsTop,boundsBottom,taskId)
            sz = size(reading);
            values = [];
            c = Configuration.Instance(this.configId);
            
            numParticles = c.particle_Number;
            pruneThreshold = c.particle_PruneNumber;
            resampleStd = c.particle_ResampleNoiseSTD;
            controlStd =  c.particle_ControlStd;
            sensorStd  = c.particle_SensorStd;
            
            for i=1:sz(1)
                % initalize if new
                if(this.particleFilter(i).uninitalized == 1)
                    this.particleFilter(i).Initalize(reading(i,1:2),numParticles,pruneThreshold,resampleStd,controlStd,sensorStd  );  
                % initalize if target changes
                elseif(this.targetOld ~= taskId && i ==2)
                    this.particleFilter(i).Initalize(reading(i,1:2),numParticles,pruneThreshold,resampleStd,controlStd,sensorStd  );  
                end
                %update beliefs
                this.particleFilter(i).UpdateBeliefs(reading(i,1:2),action(i,1:2));
                %resample
                this.particleFilter(i).Resample();
                values = [values ; this.particleFilter(i).Sample()];
            end
            
            this.targetOld = taskId;

        end
        
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
        function ApplyNoise(this)
            
            mu = 0;
            sigma = this.noiseLevel;
            
            sz = size(this.sensor_robPos) ;
            this.sensor_robPos = this.sensor_robPos + normrnd(mu,sigma,sz(1),sz(2));

            sz = size(this.sensor_robOrient(:,1:2)) ;
            this.sensor_robOrient(:,1:2) = this.sensor_robOrient(:,1:2) + normrnd(mu,sigma,sz(1),sz(2));
            
            if(this.sensor_robOrient(3) < 0)
                this.sensor_robOrient(3) = this.sensor_robOrient(3) + 2*pi;
            end
            
            sz = size(this.sensor_obstaclePos) ;
            this.sensor_obstaclePos = this.sensor_obstaclePos + normrnd(mu,sigma,sz(1),sz(2));

            sz = size(this.sensor_targetPos) ;
            this.sensor_targetPos = this.sensor_targetPos + normrnd(mu,sigma,sz(1),sz(2));

            sz = size(this.sensor_goalPos) ;
            this.sensor_goalPos = this.sensor_goalPos + normrnd(mu,sigma,sz(1),sz(2));    
            
        
        
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
        function SetTypeLabel(this,label)
            this.typeLabel = label;
            
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
        function val = MoveTarget(this,robotId,targetId,powerAngle)
            %make sure distance is close enough
            if(targetId == 0)
                val = 1;
                return;
            end
            
            %this.lastActionLabel  = strcat(this.typeLabel ,' mv t');
            this.targetAdj = this.WorldState.MoveTarget(robotId,targetId,powerAngle);
            this.targetAdj = this.targetAdj *0; %Since boxes are only ever picked up now, ane never pushed, we hack this value.
            %If box PUSHING is added back in, the particle filter will have
            %to be updated to account for box movement.
            %this.lastActionLabel  = strcat(this.typeLabel ,' mv t (',num2Str(this.targetAdj(1)),',',num2Str(this.targetAdj(1)),')');
            this.lastActionLabel  = strcat(this.typeLabel ,' mv t');
           
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
        %called when we would like to move an object
        function val = MoveRobot(this,id,amount,rotation)
            [this.newOrient this.newVelocity] = this.WorldState.MoveRobot(id,amount,rotation);
            if(rotation ~= 0)
                this.lastActionLabel = strcat(num2str(this.typeLabel ),' rot ');
            else
                
                this.lastActionLabel = strcat(num2str(this.typeLabel ),' mv s');
            end
            
            %b = this.belief_self
            %v = this.newVelocity
            
            newPoint = [this.belief_self(1:2) 0] + this.newVelocity;
            val = this.WorldState.ValidPoint(newPoint,this.WorldState.TYPE_ROBOT,id,0,0); 
            
            if(val ==0)
                 this.lastActionLabel =  strcat(num2str(this.typeLabel ),'XXX mv');
                 this.newVelocity = [0 0 0];
            end
            
            val = 1;
        end    
        
        
        function GetHelper (this,taskId)
            this.WorldState.AssignFreeRobot(taskId);
        end
    end
    
end

