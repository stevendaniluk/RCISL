classdef SimulationRun < handle
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %   Class Name
    %
    %   Description
    %
    %
    %
    
    properties
        numRobots = 0;
        numTargets = 0;
        numObstacles = 0;
        sizeObstacle = 0;
        numMilliseconds = 0;
        WorldState = [];
        %some statistics variables for tracking...
        totalBoxDistance = 0;
        configurationId = 1;
        robotProperties = RobotProperties();
        %        results_Milliseconds = 0;
        %        results_TotalReward = 0;
        
        posData = [];
        targData = [];
        goalData = [];
        obsData = [];
        advisorData = [];
        
        rpropData = [];
        tpropData = [];
        
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
        function this = SimulationRun(milliSecondsIn,configId)
            this.configurationId = configId;
            
            c= Configuration.Instance(this.configurationId );
            
            this.numRobots = c.numRobots;
            this.numObstacles = c.numObstacles;
            this.sizeObstacle = 0.5;
            
            this.numTargets = c.numTargets;
            this.numMilliseconds = milliSecondsIn;
            
            
            
            
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %   Class Name
        %
        %   Description
        %
        %
        %
        function milliseconds = Run(this,robotsList,show,world,configId)
            %{
            [N,dayName] = weekday(now);
            [H] = clock;
            H = H(4);
            hostname = char( getHostName( java.net.InetAddress.getLocalHost ) )
            if((N== 2) || (N==3) || (N==4) || (N==6))
                if(H > 11 && H < 18 )
                    if(hostname(1) == 'C' || hostname(1) == 'c' )
                        'TIME TO DIE'
                        exit;
                        %if you dont exit - crash
                        gbdjkgbdskjgds
                        gdsf
                        hsrahs
                        ar
                    end
                end
            end
            %}
            
            if( show > 0)
                h1 =figure();
            end
            [this.numRobots, dimension] = size(robotsList);
            this.WorldState = world;
            this.WorldState.reset();
            WorldState = this.WorldState;
            worldWidth = WorldState.WIDTH;
            worldHeight = WorldState.HEIGHT;
            
            
            r = [];
            for i=1:this.numRobots
                robotsList(i).SetWorldState(WorldState);
                r = [r; robotsList(i)];
            end
            posData = [];
            targData = [];
            goalData = [];
            obsData = [];
            rpropData = [];
            tpropData = [];
            
            % Run
            step = 1;
            targetsOld = 0;
            %if show == 2
            %    h1 = subplot(4,1,1);
            %    h2 = subplot(4,1,2);
            %    h3 = subplot(4,1,3);
            %    h4 = subplot(4,1,4);
            %    %move down
            %    ax=get(h1,'Position'); ax(4)=ax(4)*2; ax(2)=ax(2)-ax(4)/2; set(h1,'Position',ax);adj = ax(4)/2;
            %
            %    ax=get(h2,'Position');  ax(2)=ax(2)-adj; ax(4) =ax(4)/2; set(h2,'Position',ax);adj = adj - ax(4);
            %    ax=get(h3,'Position');  ax(2)=ax(2)-adj; ax(4) =ax(4)/2; set(h3,'Position',ax);adj = adj - ax(4);
            %    ax=get(h4,'Position');  ax(2)=ax(2)-adj; ax(4) =ax(4)/2; set(h4,'Position',ax);
            %end
            
            
            while WorldState.milliseconds < this.numMilliseconds && WorldState.GetConvergence() < 2
                for i=1:this.numRobots
                    %drawnow; increasing speed by freezing all events (!)
                    r(i).Run();
                    %{
        rData = zeros(12,15,15000);
        %motivation toward task 1 & 2
        iMotivation = [1 2];
        
        %chosen task
        iTaskId =3;

        %average complete time
        iTau =[4 5];
        
        %chosen task
        iTauMin =[6 7];

        %max completeTime
        iTauMax =[8 9];
        
        %robot strength
        iStrength =10 ;
        
        %robot speed
        iSpeed =11;
                    %}
                    rp = this.robotProperties;
                    numTargets = size(WorldState.targetProperties,1);
                    motiv = zeros(numTargets,1);
                    
                    %for j=1:numTargets
                    %    motiv(j) = r(i).CISL.lalliance.s_motivation.Get([i  j]);
                    %end
                    d = zeros(3,1);
                    d(1) = sqrt(sum(r(i).RobotState.belief_distance_self.^2));
                    d(2) = sqrt(sum(r(i).RobotState.belief_distance_goal.^2));
                    d(3) = sqrt(sum(r(i).RobotState.belief_distance_task.^2));
                    
                    if(d(3) == 0)
                        d = sum(d)/2;
                    else
                        d = sum(d)/3;
                    end
                    
                    rp.Set(i,rp.iMotivation,WorldState.milliseconds+1,motiv);
                    rp.Set(i,rp.iPfDistance,WorldState.milliseconds+1,d);
                    
                    
                    %end
                    
                    WorldState.RunPhysics(step );
                    
                    %for i=1:this.numRobots
                    r(i).Reward();
                end
                
                WorldState.milliseconds = WorldState.milliseconds + step ;
                
                [pos, orient, millis,obstacles,targets,goalPos,targetProperties,robotProperties ] = WorldState.GetSnapshot();
                
                posData(:,:,WorldState.milliseconds) = pos;
                targData(:,:,WorldState.milliseconds) = targets;
                goalData(:,:,WorldState.milliseconds) = goalPos;
                obsData(:,:,WorldState.milliseconds) = obstacles;
                rpropData(:,:,WorldState.milliseconds) = robotProperties;
                tpropData(:,:,WorldState.milliseconds) = targetProperties;
                
                this.posData = posData;
                this.targData = targData;
                this.goalData = goalData;
                this.obsData = obsData;
                this.rpropData = rpropData;
                this.tpropData = tpropData;
                
                if(size(targetsOld) == size(targets))
                    targetsDistance = targets - targetsOld;
                    targetsDistance = targetsDistance.^2;
                    targetsDistance = sum(targetsDistance,2);
                    targetsDistance = sqrt(targetsDistance);
                    this.totalBoxDistance = this.totalBoxDistance + sum(targetsDistance);
                end
                
                %for next iteration
                targetsOld = targets;
                
                %Tally Reward
                %                 rwd = 0;
                %                 for i=1:this.numRobots
                %                     rwd = rwd +  robotsList(i).GetCISL().GetTotalReward();
                %                 end
                
                %                 this.results_TotalReward = rwd - rwdInital;
                
                %show graphics (if requested)
                if(show==2)
                    clf(h1);
                    cla(h1);
                    %cla(h2);
                    %set(gcf, 'currentaxes', h1);  %# for axes with handle axs on figure f
                    
                    hold on;
                    for i=1:this.numRobots
                        point= [];
                        point = [point ; pos(i,1:2)];
                        point = [point ; pos(i,1:2)];
                        point = [point ; pos(i,1:2)];
                        point = [point ; pos(i,1:2)];
                        point = [point ; pos(i,1:2)];
                        
                        ang = orient(i,3);
                        len = 0.5;
                        
                        point(1,1:2) = [point(1,1) - len*cos(ang) point(1,2) - len*sin(ang)];
                        point(2,1:2) = [point(2,1) + len*cos(ang) point(2,2) + len*sin(ang)];
                        
                        point(3,1:2) = [point(3,1) + 0.1*cos(ang)+0.1*sin(ang) ...
                            point(3,2) + 0.1*sin(ang)+0.1*cos(ang)];
                        
                        point(4,1:2) = [point(4,1) + 0.1*cos(ang)-0.1*sin(ang) ...
                            point(4,2) + 0.1*sin(ang)-0.1*cos(ang)];
                        point(5,1:2) = [point(5,1) + len*cos(ang) point(5,2) + len*sin(ang)];
                        
                        plot(point(:,1),point(:,2),'b');
                        
                        %plot(boxPoints(1,:),boxPoints(2,:),'b');
                        
                        %if robotProperties(i,5) == 2
                        %   plot(boxPoints(1,:),boxPoints(2,:)+0.05,'b');
                        %end
                        if robotProperties(i,1) ~= 0
                            X = [targets(robotProperties(i,1),1) pos(i,1)];
                            Y = [targets(robotProperties(i,1),2) pos(i,2)];
                            plot(X,Y,'r');
                        end
                        
                        axis([0 worldWidth 0 worldHeight]);
                    end
                    
                    %{
                     for i=1:this.numRobots
                       boxPoints = this.GetBox(pos(i,:),0.5);
                       plot(boxPoints(1,:),boxPoints(2,:),'b');

                       if robotProperties(i,5) == 2
                          plot(boxPoints(1,:),boxPoints(2,:)+0.05,'b');
                       end
                       if robotProperties(i,1) ~= 0
                          X = [targets(robotProperties(i,1),1) pos(i,1)];
                          Y = [targets(robotProperties(i,1),2) pos(i,2)];
                          plot(X,Y,'r');
                       end
                       
                       axis([0 worldWidth 0 worldHeight]);
                     end

                     
                    %}
                    
                    %%%% Display Robots
                    text(1,9,num2str(WorldState.milliseconds));
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
                        
                        %display a line to the current advisor (if we have
                        %one)
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
                            %{
                            point = pos(i,1:2);
                            point2 = pos(i,1:2)+ st(1:2);
                            X = [point(1) point2(1)];
                            Y = [point(2) point2(2)];
                            plot(X,Y,'b','LineWidth',1);

                            point = pos(i,1:2);
                            point2 = pos(i,1:2)+ st(3:4);
                            X = [point(1) point2(1)];
                            Y = [point(2) point2(2)];
                            plot(X,Y,'b','LineWidth',1);

                            point = pos(i,1:2);
                            point2 = pos(i,1:2) + st(5:6);
                            X = [point(1) point2(1)];
                            Y = [point(2) point2(2)];
                            plot(X,Y,'b','LineWidth',1);
                            %}
                            
                            
                        end
                        
                        
                        %particles = robotsList(i).RobotState.particleFilter.particles;
                        %sz = size(particles );
                        %for j=1:sz(1)
                        % point = particles(j,1:2);
                        %boxPoints = this.GetBox(point,0.2);
                        % plot(boxPoints(1,:),boxPoints(2,:),'r');
                        %end
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
                    
                    %set(0, 'currentfigure', h2);  %# for figures
                    % Populate sub plots
                    %{
                     for i=1:3
                         if(i == 1)
                            h = h2;
                         end
                         if(i == 2)
                            h = h3;
                         end
                         if(i == 3)
                            h = h4;
                         end
                         set(gcf, 'currentaxes', h);  %# for axes with handle axs on figure f
                         plotDat = [];
                         legend = [];
                         for robotid=1:this.numRobots
                             A = this.robotProperties.rData(robotid,this.robotProperties.iMotivation(i),1:WorldState.milliseconds);
                             A = reshape(A,max(size(A)),1);
                             plotDat = [plotDat A];
                             legendDat = [legend; strcat('rob',num2str(robotid) )];
                         end
                         %legend(legendDat');
                         plot(plotDat);
                     end
                     hold off;
                     %pause(0.001);
                     drawnow;
%                    this.ShowTable(labels,[ 1 2 3; 4 5 6]);
                    %}
                    drawnow;
                end
                
                
                
                
                
            end
            
            
            
            
            %posData
            if(show ==1)
                
                % Output Robot Tracks
                
                for i=1:this.numRobots
                    hold all
                    plot(reshape(posData(i,1,:),1,[]),reshape(posData(i,2,:),1,[]));
                    drawnow;
                    
                end
                % Output Target Tracks
                for i=1:this.numTargets
                    hold all
                    plot(reshape(targData(i,1,:),1,[]),reshape(targData(i,2,:),1,[]));
                    drawnow;
                    
                end
                
                % Output Robot Representation
                for i=1:this.numRobots
                    point = posData(i,:,this.numMilliseconds);
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
            end
            
            milliseconds = WorldState.milliseconds;
            
        end
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %   Class Name
        %
        %   Description
        %
        %
        %
        function ShowTable(this,labels,data)
            uitable('Data',data, 'ColumnName', {'A', 'B', 'C'});
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %   Class Name
        %
        %   Description
        %
        %
        %
        function boxPoints = GetBox(this,point,size)
            ang=0:0.01:2*pi;
            xp=size*cos(ang);
            yp=size*sin(ang);
            boxPoints = [point(1)+xp; point(2)+yp];
        end
    end
    
end

