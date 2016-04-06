classdef AdviceExchange < handle
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Advice Exchange
        %   
        %   This module allows collaborative behaviour
        %   between agents
        %   
        %   
    %ADVICEEXHANGE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        rewardSum = 0;
        learnsSum = 0;
        eta = 0.7; % [0, 1 [
        delta = 0.3; %  [0,1]
        row = 1;% [0.9, 1 [

        robotId = 0;
        numRobots = 0;
        advisorId = 0;
        robot_strengthTypes = [];
    end
        
    properties (Constant)
        %[motivation is stored as [metric Type robotId ]
        s_qualityMetrics = SparseHashtable(10);
        
        %quality is the 'avergae quality' over an epoch
        c_avgQual = 1;
        c_currentQual = 2;
        c_bestQual = 3;
    end
    
    methods

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   AdviceExchange(robotId,numRobots)
        %   robotId - the robot whos advice will be tracked.
        %   
        %   numRobots - how many teammates will we look at?
        %   
        %   
        %
        function this = AdviceExchange(robotId,numRobots,robStrTypes,configId)
            this.robotId =robotId;
            this.numRobots = numRobots;
            this.s_qualityMetrics.Put([this.c_avgQual robotId],0);
            this.s_qualityMetrics.Put([this.c_currentQual robotId],0);
            this.s_qualityMetrics.Put([this.c_bestQual robotId],0);
            config = Configuration.Instance(configId);
            this.eta = config.advice_eta;
            this.delta = config.advice_delta;
            this.row = config.advice_row;
            
            % Monday 3 row = 1
            % row = 1
            % eta = 0.1
            % decay = 0; 
            % Save Advice Exchange data in new datafile

            this.advisorId  = this.robotId;
            this.robot_strengthTypes = robStrTypes;
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   AddReward(this,reward)
        %  
        %   During an epoch, reward can be added when it is obtained.
        %   
        %
        function AddReward(this,reward)
            this.rewardSum = this.rewardSum  + reward;
            this.learnsSum = this.learnsSum +1;
            %keep our 'current' reward updated
            this.s_qualityMetrics.Put([this.c_currentQual this.robotId],this.rewardSum / this.learnsSum );
            
            
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   EpochEnd(this)
        %  
        %   End an epoch. At this moment, all the quality metrics are
        %   updated. 
        %   
        %
        function EpochEnd(this,rstate)
            
            bestQual = this.s_qualityMetrics.Get([this.c_bestQual this.robotId]);
            averageQual = this.s_qualityMetrics.Get([this.c_avgQual this.robotId]);           
            currentQual = this.s_qualityMetrics.Get([this.c_currentQual this.robotId]);
            
            %save the current quality if we should be doing that.
            bestQual = bestQual*this.row;
            if(currentQual > bestQual)
                this.s_qualityMetrics.Put([this.c_bestQual this.robotId],currentQual);
            else
                this.s_qualityMetrics.Put([this.c_bestQual this.robotId],bestQual);
            end
            
            %update the average quality (over many epochs)
            averageQual = (1-this.eta)*currentQual + this.eta*averageQual;
            this.s_qualityMetrics.Put([this.c_avgQual this.robotId],averageQual);
            
            %finally reset our counters and start over
            
            this.rewardSum = 0;
            this.learnsSum = 0;
            this.advisorId  = this.ChooseAdvisor(rstate);
            
        end

        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   GetCurrentAdvisor(this)
        %  
        %   Get our current advisor
        %   
        %   
        %           
        function robId = GetCurrentAdvisor(this)
            robId =  this.advisorId;
            return;
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   ChooseAdvisor(this)
        %  
        %   given our set of robots, choose a robot to take advice from.
        %   
        %   
        %        
        function robotIdChosen = ChooseAdvisor(this,rstste)
            myBestQual = this.s_qualityMetrics.Get([this.c_bestQual this.robotId]);
            myAverageQual = this.s_qualityMetrics.Get([this.c_avgQual this.robotId]);           
            myCurrentQual = this.s_qualityMetrics.Get([this.c_currentQual this.robotId]);
            bestTeamAvgQual = 0;
            bestId = 0;
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %
            % step 1, put together a set of robots that *can* advise us
            %
            % These robots are the same type, and doing the same task as
            % us:
            % robotProperties =[     currentTarget       rotationStep          
            % mass              speedStep         typeId] 
            %
            % targetProperties =      [isReturned          weight                 
            % type(1/2)          carriedBy           
            % size                   lastRobotToCarry]
            
            [robPos, robOrient, millis, ...
                obstaclePos,targetPos,goalPos,...
                targetProperties,robotProperties ] ...
            = rstste.GetSnapshot();
            types = [0; targetProperties(:,3)];
            
            rSameRobotStrength = (this.robot_strengthTypes(robotProperties(:,5)) == this.robot_strengthTypes(robotProperties(this.robotId,5)));
            rSameTargetTypes = (types(robotProperties(:,1)+1) == types(robotProperties(this.robotId,1)+1));
            rPossibleAdvisorIndices = floor((rSameRobotStrength + rSameTargetTypes )/2);
            profile = [rSameRobotStrength rSameTargetTypes rPossibleAdvisorIndices];
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %
            % step 2 - find the best robot (that we can take advice from)
            %
            %
            %debugProf= [rSameRobotStrength rSameTargetTypes rPossibleAdvisorIndices]
            bestId = this.robotId;
            for i=1:size(rPossibleAdvisorIndices,1)
                possible = rPossibleAdvisorIndices(i);
                if i ~= this.robotId && possible~= 0
                    averageQual = this.s_qualityMetrics.Get([this.c_avgQual i]);           
                    if(averageQual > bestTeamAvgQual )
                        bestTeamAvgQual = averageQual;
                        bestId = i;
                    end
                    
                end
            end
            
            %if nobody is the best, OR I'm the best, select myself.
            if(bestId == this.robotId)
                robotIdChosen = this.robotId;
                return;
            end

            %if someone else seems better - take their advice....if...
            bestQual = this.s_qualityMetrics.Get([this.c_bestQual bestId]);
            %they are better than I'm doing (on average)
            if(myCurrentQual < averageQual - this.delta*averageQual)
                %and their best is better than my best
                if(myBestQual < bestQual)
                    %disp('taking advice foos');
                    robotIdChosen = bestId;
                    %[this.robotId bestId]
                    %profile 
                    return;
                end
            end
            robotIdChosen = this.robotId;
            
        end
        
    end
end

