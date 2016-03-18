classdef SimulationRun < handle
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %   SimulationRun
    %
    %   Responsible for running the simulation given robots, a world, and
    %   a configuration. Will advance through each time step, updating 
    %   robot states, running the world physics, and updating the learning.
    
    properties
        % World parameters
        configurationId = 1;
        numRobots = 0;
        numTargets = 0;
        numObstacles = 0;
        numMilliseconds = 0;
        WorldState = [];
        
        % World data
        posData = [];
        targData = [];
        goalData = [];
        obsData = [];
        advisorData = [];
        
        % Robot and target properties
        robotProperties = [];
        tpropData = [];
        orient = [];
        
        % Time step for simulation
        step = 1;

    end
    
    methods
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %   Constructor
        %
        %   configId: The 8 digit configuration ID
        %   milliSecondsIn: Maximum number of iterations (seconds) for sim
        %
        function this = SimulationRun(milliSecondsIn,configId)
            this.configurationId = configId;
            c= Configuration.Instance(this.configurationId );
            
            this.numRobots = c.numRobots;
            this.numObstacles = c.numObstacles;
            this.numTargets = c.numTargets;
            this.numMilliseconds = milliSecondsIn; 
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %   Run
        %
        %   Steps through the simulation for the given world and robots.
        %   Main loop consists of calling the Run and Reward methods of the
        %   robot class, as well as the RunPhysics method for the wordState
        %   class at each iteration, until the world converges or the max
        %   time is reached.
        %
        %   Graphics can be set to be displayed live, only show the path
        %   afterwards, or not show at all.

        function milliseconds = Run(this,robotsList,show,world)
             
            % Set world properties
            this.WorldState = world;
            this.numRobots = size(robotsList,1);
            worldWidth = this.WorldState.WIDTH;
            worldHeight = this.WorldState.HEIGHT;
            
            % Set state for each robot
            for i=1:this.numRobots
                robotsList(i).SetWorldState(this.WorldState);
            end
            
            % If we need a figure, open it
            if( show > 0)
                h1 =figure();
            end
            
            while this.WorldState.milliseconds < this.numMilliseconds && this.WorldState.GetConvergence() < 2
                for i=1:this.numRobots
                    % Get action, act, and update state
                    robotsList(i).Run();
                    % Run one step of world physics
                    this.WorldState.RunPhysics(this.step );
                    % Update learning rate and learn
                    robotsList(i).Reward();
                end
                
                this.WorldState.milliseconds = this.WorldState.milliseconds + this.step ;
                
                % Load worldstate and record data 
                % (saved in new variables to be used later)
                [pos, this.orient, ~,obstacles,targets,goalPos,targetProperties,this.robotProperties ] = this.WorldState.GetSnapshot();
                this.posData(:,:,this.WorldState.milliseconds) = pos;
                this.targData(:,:,this.WorldState.milliseconds) = targets;
                this.goalData(:,:,this.WorldState.milliseconds) = goalPos;
                this.obsData(:,:,this.WorldState.milliseconds) = obstacles;
                this.tpropData(:,:,this.WorldState.milliseconds) = targetProperties;
                
                % If requested, display the live graphics during the run
                if(show==2)
                    clf(h1);
                    cla(h1);
                    hold on;
                    
                    for i=1:this.numRobots

                        point=zeros(5,2);
                        point(:,1)=pos(i,1);
                        point(:,2)=pos(i,2);
                        
                        ang = this.orient(i,3);
                        len = 0.5;
                        
                        point(1,1:2) = [point(1,1) - len*cos(ang) point(1,2) - len*sin(ang)];
                        point(2,1:2) = [point(2,1) + len*cos(ang) point(2,2) + len*sin(ang)];
                        
                        point(3,1:2) = [point(3,1) + 0.1*cos(ang)+0.1*sin(ang) ...
                            point(3,2) + 0.1*sin(ang)+0.1*cos(ang)];
                        
                        point(4,1:2) = [point(4,1) + 0.1*cos(ang)-0.1*sin(ang) ...
                            point(4,2) + 0.1*sin(ang)-0.1*cos(ang)];
                        point(5,1:2) = [point(5,1) + len*cos(ang) point(5,2) + len*sin(ang)];
                        
                        plot(point(:,1),point(:,2),'b');
                        
                        if this.robotProperties(i,1) ~= 0
                            X = [targets(this.robotProperties(i,1),1) pos(i,1)];
                            Y = [targets(this.robotProperties(i,1),2) pos(i,2)];
                            plot(X,Y,'r');
                        end
                        
                        axis([0 worldWidth 0 worldHeight]);
                    end
                    
                    % Display Robots
                    text(1,9,num2str(this.WorldState.milliseconds));
                    for i=1:this.numRobots
                        point = robotsList(i).RobotState.belief_self(1:2);
                        
                        boxPoints = this.GetBox(point,0.25/2);
                        plot(boxPoints(1,:),boxPoints(2,:),'g');
                        lbl = strcat(num2str(i),' ',robotsList(i).RobotState.lastActionLabel);
                        text(point(1)+0.2,point(2)+0.2,lbl);
                        
                        point = robotsList(i).RobotState.belief_task(1:2);
                        boxPoints = this.GetBox(point,0.1);
                        plot(boxPoints(1,:),boxPoints(2,:),'b');
                        
                        point = robotsList(i).RobotState.belief_goal(1:2);
                        boxPoints = this.GetBox(point,0.1);
                        plot(boxPoints(1,:),boxPoints(2,:),'b');
                        
                        %display a line to current advisor (if we have one)
                        if(robotsList(i).RobotState.cisl.advexc_on == 1)
                            advisorId = robotsList(i).RobotState.cisl.adviceexchange.GetCurrentAdvisor();
                        else
                            advisorId = i;
                        end
                        
                        if(advisorId ~= i)
                            point = pos(i,1:2);
                            point2 = pos(advisorId,1:2);
                            boxPoints = this.GetBox(point,0.3);
                            plot(boxPoints(1,:),boxPoints(2,:),'y');
                            X = [point(1) point2(1)];
                            Y = [point(2) point2(2)];
                            plot(X,Y,'y');
                        end
                        
                        if(robotsList(i).RobotState.cisl.useHal == 1)
                            vecAdv = [0 0];
                            dist = [];
                            st = [];
                            [vecAdv,st] = robotsList(i).RobotState.cisl.hal.GetLastAdvisedVector();
                        else
                            vecAdv = [0 0];
                            dist = [];
                            st = [];
                        end
                        
                        if(sum(vecAdv ,2) ~= 0)
                            point = pos(i,1:2);
                            point2 = pos(i,1:2) + vecAdv;
                            X = [point(1) point2(1)];
                            Y = [point(2) point2(2)];
                            plot(X,Y,'b','LineWidth',4);
                        end
                        
                        axis([0 worldWidth 0 worldHeight]);
                    end
                    
                    % Output Obstacle Locations
                    for i=1:this.numObstacles
                        boxPoints = this.GetBox(obstacles(i,:),0.5);
                        plot(boxPoints(1,:),boxPoints(2,:),'r');
                        
                        axis([0 worldWidth 0 worldHeight]); 
                    end
                    
                    % Output Target Locations
                    for i=1:this.numTargets
                        point = targets(i,:);
                        boxPoints = this.GetBox(point,0.25);
                        if targetProperties(i,1) == 0
                            plot(boxPoints(1,:),boxPoints(2,:),'g');
                            if targetProperties(i,3) == 2
                                plot(boxPoints(1,:),boxPoints(2,:)+0.05,'g');
                            end
                        else
                            plot(boxPoints(1,:),boxPoints(2,:),'r');
                        end
                        axis([0 worldWidth 0 worldHeight]);
                    end
                    
                    % Output Goal Location
                    point = goalPos;
                    boxPoints = this.GetBox(point,1);
                    plot(boxPoints(1,:),boxPoints(2,:),'k');
                    
                    drawnow limitrate;
                end % end if(show==2)
   
            end % end while
     
            % If requested, plot the final robot and traget tracks after
            % the run has finished
            if(show ==1)
                
                % Output Robot Tracks
                for i=1:this.numRobots
                    hold all
                    plot(reshape(this.posData(i,1,:),1,[]),reshape(this.posData(i,2,:),1,[]));
                    drawnow;
                end
                
                % Output Target Tracks
                for i=1:this.numTargets
                    hold all
                    plot(reshape(this.targData(i,1,:),1,[]),reshape(this.targData(i,2,:),1,[]));
                    drawnow;
                end
                
                % Output Robot Representation
                for i=1:this.numRobots
                    point = this.posData(i,:,this.numMilliseconds);
                    boxPoints = this.GetBox(point,0.5);
                    hold all
                    plot(boxPoints(1,:),boxPoints(2,:),'b');
                end
                
                % Output Obstacle Locations
                for i=1:this.numObstacles
                    point = obstacles(i,:);
                    boxPoints = this.GetBox(point,0.5);
                    hold all
                    plot(boxPoints(1,:),boxPoints(2,:),'r');
                end
                
                % Output Target Locations
                for i=1:this.numTargets
                    point = targets(i,:);
                    boxPoints = this.GetBox(point,0.5);
                    hold all
                    plot(boxPoints(1,:),boxPoints(2,:),'g');
                end
                
                % Output Goal Location
                point = goalPos;
                boxPoints = this.GetBox(point,1);
                hold all
                plot(boxPoints(1,:),boxPoints(2,:),'k');
            end % end if(show==2)
            
            % Set task completion time to return
            milliseconds = this.WorldState.milliseconds;
            
        end % end Run

        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %   GetBox
        %
        %   For plotting purposes, returns an array of data 
        %   points centred at 'point', and with radius or 'size'

        function boxPoints = GetBox(~,point,size)
            ang=0:0.01:2*pi;
            xp=size*cos(ang);
            yp=size*sin(ang);
            boxPoints = [point(1)+xp; point(2)+yp];
        end % end Getbox
        
    end % end methods
    
end % end classdef

