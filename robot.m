classdef robot < handle 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % 
    %   Class Name
    %   
    %   Description 
    %   
    %   
    %   
    %ROBOT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        %pos = [0 0 0];
        %orientation = [0 0 0];
        CISL = [];
        state = [];
        id = 0;
        RobotState;
        lastActionId = 0;
        
        stepSize = 0.5;
        rotationSpeed = pi/4;
        ticks = 0;
        learningFreq = 4;
        lastActionExpProfile =[];
        s_robotTeam = GenericList();

        systemType = 0;
        
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
        function SetRobotTeam(this,list)
            this.s_robotTeam  = list;
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
        function robo = GetRobotFromTeam(this,id)
            robo = this.s_robotTeam.Get(id);
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
        function this = robot(inId,configId,encCodes)
              
            this.id = inId;
            %this.CISL = cisl(this.stepSize ,this.rotationSpeed,configId);
            c = Configuration.Instance(configId);
            if( c.cisl_type == 1)
                this.systemType =1;
                'Only Q-Learning Running'
                this.CISL = QSystem(configId,inId,encCodes);
            elseif( c.cisl_type == 2)
                this.systemType =2;
                'L-AllianceRunning'
                this.CISL = QAL(configId,inId,encCodes);
            elseif( c.cisl_type == 3)
                this.systemType =3;
                'RSLA Running'
                this.CISL = QAL(configId,inId,encCodes);
            else
                this.systemType =4;
                'QAQ Running'
                this.CISL = QAQ(configId,inId,encCodes);
            end
            this.learningFreq = c.cisl_learningFrequency;
            this.lastActionExpProfile = [];
        end
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
        function val = SetWorldState(this,WorldState)
            this.RobotState = robotState(this.id,WorldState,this.CISL.configId,this.CISL,this);
            this.state = WorldState;
            %TODO - combine all object properties into a
            %single array.  Constants can describe
            %the array indexes, and can be redined at will.
            
            [robPos, robOrient, millis, obstaclePos,targetPos,goalPos,targetProperties,robotProperties ]  = this.state.GetSnapshot();
            this.stepSize = robotProperties(this.id, 4);
            this.rotationSpeed = robotProperties(this.id, 2);
            typeLabel = robotProperties(this.id,5);

            if(typeLabel == 1)
                typeLabel = 'ss-';
            elseif(typeLabel == 2)
                typeLabel = 'wf-';
            elseif(typeLabel == 3)
                typeLabel = 'ws-';
            else
                typeLabel = 'sf-';
            end
            
            this.RobotState.update();
            %this.CISL.UpdateId(this.RobotState);

            this.RobotState.SetTypeLabel(typeLabel );
            this.CISL.SetRobotProperties(this.stepSize,this.rotationSpeed  );
            this.CISL.Reset();
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
        function cisl = GetCISL(this)
            cisl = this.CISL;
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
        function worldState = GetWorldState(this)
            worldState = this.state;
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
        function robotState = GetRobotState(this)
            robotState = this.RobotState;
        end
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
        function val = Run(this)
            %Must update before acting.
            %disp(strcat(num2str(this.id),' ACTING '));
            this.RobotState.update();

            originalTaskId = this.CISL.GetTask();
            [action,actionId,experienceProfile,acquiescence]= this.CISL.Act(this.RobotState);
            afterTaskId = this.CISL.GetTask();
            
            this.lastActionExpProfile = experienceProfile;
            
            %Save, in the world, our current target ID
            this.state.UpdateRobotTarget(this.id,this.GetTargetId()); 
            this.state.SetRobotAdvisor(this.id,this.GetAdvisorId());
            
            this.lastActionId = actionId; 

            this.RobotState.saveState();
            %disp(strcat(num2str(this.id),'-Get Action-',num2str(actionId)));
            if(acquiescence > 0 )
                %disp('Dropping Task');
                %disp(strcat(num2str(this.id),' thinks we are dropping'));
                this.RobotState.MoveTarget (this.id,originalTaskId,-1);
            elseif(actionId == 0)
                %disp(strcat(num2str(this.id),'-Moving-(',num2str(actionId),',',num2str(action(1)),',',num2str(action(2)),')'));
                this.RobotState.MoveRobot (this.id,action(1),action(2));
            elseif(actionId <= 3) % a locomotion action (turning or driving)
                %disp(strcat(num2str(this.id),'-Moving-(',num2str(actionId),',',num2str(action(1)),',',num2str(action(2)),')'));
                this.RobotState.MoveRobot (this.id,action(1),action(2));
            elseif(actionId >3) %a move object action (if we can)
                %disp(strcat(num2str(this.id),'-Target Get-'));
                this.RobotState.MoveTarget (this.id,afterTaskId,action);
            end
            
            this.ticks = this.ticks + 1;
            val = actionId;
        end
        

        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
        function tid = GetTargetId(this)
            tid = this.CISL.GetTask();
        end
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Class Name
        %   
        %   Description 
        %   
        %   
        %   
        function rid = GetAdvisorId(this)
            rid = 0;
            if(this.CISL.advexc_on ==1)
                rid = this.CISL.adviceexchange.GetCurrentAdvisor();
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
        function val = Reward(this)
            experience = min(this.lastActionExpProfile);
            
            this.RobotState.update();
            
            %slow learning down when we start to know everything about a
            %certain state.... IE we are converged on a certain value

            %rate = this.learningFreq + round(50*exp(experience/100 )/(100+(exp(experience/100 ))));
            rate = this.learningFreq + round(50*exp((experience-45)/20 )/(100+(exp((experience-45)/20 ))));
            
            if(mod(this.ticks,rate) == 0)
                this.CISL.LearnFrom(this.RobotState,this.lastActionId);
            end
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
        function val = GetMemoryOccupancy(this)
            val = this.CISL.GetMemoryOccupancy();
        end
        
    end
    
end

