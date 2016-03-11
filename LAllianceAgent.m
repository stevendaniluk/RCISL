classdef LAllianceAgent < handle
    %LALLIANCEAGENT Summary of this class goes here
    %   The agent class stores beliefs about other agent performance
    %   and decides when to take over tasks
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %QUESTIONS
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %Future commits
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %Comments
    %Comment out Id's
    
    properties
        %Each of the following 11 parameters will form an nxm matrix, and
        %will be added to the 11 page  multidimensional array data[].
        %Values are assigned to each parameter name to index data[] pages
        data = [];
        
        %Tau's: Average trial time (time robot i lets pass without
        %recieving message from teammate)
        ti = 1;
        
        %Motivation: Each robots motivation towards each task
        %[0,Theta]
        mi = 2;
        
        %Impatience Rate: Each robots impatiance towards each task
        pi = 3;
                
        %Aquiescence: Each robots acquiesence towards each task
        %Binary [0,1]
        %0=Keep, 1=Aquiesce
        ai = 4;
        
        %Psi: time currently on each task, [s11 .. sij ... s1M; ...]
        si = 5;
        
        %Delta: Maximum allowed time on each task
        di = 6;
        
        %Task Assignment: What task each robot is assigned to
        %Binary [0,1]
        %0=Not assigned, 1=Assigned
        ji = 7;

        %Task Completion, as percieved by each agent
        %Binary [0,1]
        %0=Not Completed, 1=Completed
        ui = 8;
        
        %Did we finish a task this epoch? [u11 .. uij ... u1M;...]
        fi = 9;

        %Did we finishe a task this epoch? [u11 .. uij ... u1M;...]
        vi = 10;
        
        %are we currently cooperating? A flag
        ci = 11;
        
        
        
        
        robotId = 0;    %Integer [1,n]
        n = 0;          %number of robots
        m = 0;          %number of tasks
        config = [];    %Configuration parameters
        robotCommunication = [];
        
        %ALLIANCE Parameters
        theta = 5;
        motivation_Threshold = 20;
        movingAverageKeep = 0.3;
        
        convergeAttempts = 70;
        convergeSlope = 0.15;

        confidence_Factor = 0;
        
        %tauType = 1 - Moving Average
        tauType = 1;
        
        tmax = 7000;
        tmin = 4000;
        
        %default to using only the slow impatience rate
        useFast = 0;
        
        %Do we store taus for cooperation?
        useCooperation = 0;
        useCooperationLimit = 0;
        
        
        %Do we automatically calculate taus?
        calculateTau = 0;
        tauCounter = 0;
        failureTau = 7000;
        
        updateByTaskType = 0;
        taskTypes = [];
        ticks = 0;
        freq = 0;
        
        

    end
    
    methods
        function this= LAllianceAgent(configuration,robotId)
            %Configure robot communication
            this.robotCommunication = RobotCommunication.Instance(configuration);
            
            %Set number of robots and number of tasks (1 Target=1 task)
            this.n = configuration.numRobots;
            this.m = configuration.numTargets;
            
            %Parameter values taken from Configuration Run
            this. theta = configuration.lalliance_theta ;
            this.motivation_Threshold = configuration.lalliance_motivation_Threshold ;
            this.movingAverageKeep = configuration.lalliance_movingAverageKeep ;
            this.convergeAttempts = configuration.lalliance_convergeAttempts ;
            this.convergeSlope =  configuration.lalliance_convergeSlope ;

            %tauType = 1 - Moving Average
            this.tauType = configuration.lalliance_tauType ;

            this.tmax = configuration.lalliance_tmax ;
            this.tmin = configuration.lalliance_tmin ;

            %default to using only the slow impatience rate
            this.useFast = configuration.lalliance_useFast;

            %Do we store taus for cooperation?
            this.useCooperation = configuration.lalliance_useCooperation;
            this.useCooperationLimit = configuration.lalliance_useCooperationLimit;
            
            %Do we automatically calculate taus?
            this.calculateTau = configuration.lalliance_calculateTau ;
            this.tauCounter = 0;
            this.failureTau = configuration.lalliance_failureTau ;
            this.updateByTaskType = configuration.lalliance_updateByTaskType ;
            this.freq = configuration.lalliance_motiv_freq;
            
            
            this.robotId = robotId;
            this.config = configuration;
            
            %Create empty multidimensional data array
            %Rows correspond to robots
            %Collumns correspond to tasks
            %Pages correspond to the number of ALLIANCE parameters
            this.data = zeros(this.n, this.m, 11);      
           
            
            % disp(strcat(['created robot',num2str(robotId)]));
            this.robotCommunication.SetAgent(this,robotId);
            this.SetAcquiescence(configuration.lalliance_acquiescence);
            this.confidence_Factor = configuration.lalliance_confidenceFactor;
            this.data(this.robotId,:,this.ti) = 700; %Assume you are the best!
            
       
        end
        %%
        function this= SetAcquiescence(this,acin)
            this.data(this.robotId,:,this.di) = acin;
        end
        %%
        function Broadcast(this)
            this.robotCommunication.SendMessageToAgents(this.robotId,this.data(this.robotId,:,:));
        end
        %%
        function BroadcastGeneral(this,robotRange, taskRange, flagRange,value)
            this.robotCommunication.SendGeneralMessageToAgents(robotRange,taskRange,flagRange,value);
        end
        %%
        function ImpatienceReset(this,taskRange)
            %old singular implementation;
            %robots = 1:size(this.data,1);
            %robots(this.robotId) = []; %Don't reset you own impatience
            
            robots = [];
            robotsAssigned = sum(this.data(:,taskRange,this.ji),2) <= 0;
            for i=1:size(robotsAssigned,1)
                if(robotsAssigned(i) == 1)
                    robots = [robots i];
                end
            end
            
            this.BroadcastGeneral(robots, taskRange, this.mi,0);
        end
        %%
        function AcceptPerformanceInformation(this,agentId,data)
            this.data(agentId,:,:) = data;
        end
        %%
        function  AcceptGeneralPerformanceInformation(this,robotRange,taskRange,flagRange,value)
            this.data(robotRange,taskRange,flagRange) = value;
        end
        %%
        function Reset(this)
            %We might have failed last round,
            if ( sum(this.data(this.robotId,:,this.ji),2) ~= 0)
                if(this.calculateTau ==1)
                    %disp('failed a task');
                    %[amount,index] = max(this.data(this.robotId,:,this.ji),[],2);
                    %this.UpdateTau(index(1), this.failureTau);
                    %this.data(this.robotId,index(1),this.vi) = this.data(this.robotId,index(1),this.vi) + 1;
                    
                end
            end
            
            this.tauCounter = 0;
            this.data(this.robotId,:,this.mi) = 0; % have no intrinsic motivation
            this.data(this.robotId,:,this.ji) = 0; % not assigned to any boxes
            this.data(this.robotId,:,this.ai) = 0; % not assigned to any boxes
            this.data(this.robotId,:,this.si) = 0; % not assigned to any boxes
            this.data(this.robotId,:,this.ui) = 0; % have not finished any tasks
            this.data(this.robotId,:,this.ci) = 0; % have not finished any tasks
            
            this.Broadcast();
            %this.data(this.robotId,:,this.fi) = 0; % have not finished any tasks
            
            
        end
        %%
        function CalculateImpatience(this,confidence)
            %slow impatience rate
            if(nargin < 2)
                sz = size(this.data(this.robotId,:,this.ti),2);
                confidence  = zeros(1,sz);
            end
            confidenceAdd = confidence.*this.confidence_Factor;
            
            if(this.useCooperation ~=1)
                sz = size(this.data(this.robotId,:,this.ti),2);
                tauAdd = zeros(1,sz);
            else
                assignedOther = this.data(:,:,this.ji);
                assignedOther(this.robotId,:) = 0; %forget about us.
                tauAdd = (this.data(:,:,this.ti)+100).*assignedOther; % all the taus of robots currently assigned
                assignedOther = sum(assignedOther,1);
                assignedOther = (assignedOther ==1); %we are looking at tasks with only one robot
                tauAdd = bsxfun(@times,tauAdd,assignedOther); %mask out the unassigned, and the double assigned
                tauAdd = sum(tauAdd,1); 
            end
            sr = this.theta./((this.data(this.robotId,:,this.ti) +tauAdd)+ confidenceAdd+ 1);
            if(this.useFast == 1)

                %variables needed to calc the fast rate
                tausRaw = this.data(:,:,this.ti);
                tausRaw(this.robotId,:) = tausRaw(this.robotId,:) +tauAdd + confidenceAdd; % we add to the tau of double assigned tasks
                minTau = min(min(tausRaw(:,:),[],1),[],2);
                maxTau = max(max(tausRaw(:,:),[],1),[],2);
                myTau =tausRaw(this.robotId,:); % we add to the tau of double assigned tasks
                scale = (this.tmax-this.tmin)/(maxTau-minTau );
                
                %fast superior impatience rate (used when you are the best)
                fsr = this.theta./((this.tmax - (myTau  - minTau))*scale + 1);

                %fast mediocre impatience rate
                fmr = this.theta./((this.tmin + (myTau  - minTau))*scale + 1);

                minTauRow = min(tausRaw(:,:),[],1);
                
                haveDoneTask = this.data(this.robotId,:,this.vi) > 0;
                
                amBestAtTask = (minTauRow == myTau);
                notBestAtTask = 1- amBestAtTask;
                %now we select the best value by constructing a gating
                %array:
           %     this.data(:,1,this.vi)
           %      [ fsr.*amBestAtTask.*haveDoneTask;...
           %        fmr.*notBestAtTask.*haveDoneTask;...
           %         sr.*(1-haveDoneTask)]
                slower1 = (fsr < 0);
                slower2 = (fmr < 0);
                slower3 = (fsr < 0);

                
                
                slower2 = slower2+slower3;
                if((sum(sum(slower1,1),2) > 0) || (sum(sum(slower2,1),2) > 0))
                    myTau
                    this.tmax
                    this.tmin
                    maxTau
                    minTau
                    scale
                    sr
                    fsr
                    fmr
                    error('fast rates slower than slow rates!')
                end
           
           
                this.data(this.robotId,:,this.pi)  = ...
                    fsr.*amBestAtTask.*haveDoneTask + ...
                    fmr.*notBestAtTask.*haveDoneTask + ...
                     sr.*(1-haveDoneTask);
            else
                
                this.data(this.robotId,:,this.pi)  = sr;
            end
        end
        %%
        function Update(this,delta,confidence)
            
            if(this.calculateTau == 1)
                this.tauCounter = this.tauCounter  + delta;
                %disp(strcat(num2str(this.robotId),' > updating. . . ',num2str(this.tauCounter)));
                
            end
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Acquiescence 
            % update PSI, which is a count of how long we have engaged a
            % task. 
            this.data(this.robotId,:,this.si) = (this.data(this.robotId,:,this.si) + delta).*this.data(this.robotId,:,this.ji); 
            % Update Acquiescence
            AcquiescenceAllowed = this.data(this.robotId,:,this.di) > 0;
            AcquiescenceShould = (this.data(this.robotId,:,this.si) > this.data(this.robotId,:,this.di)); 
            Acquiescence = AcquiescenceAllowed .*AcquiescenceShould .*this.data(this.robotId,:,this.ji);
            this.data(this.robotId,:,this.ai) = Acquiescence ;
            
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Impatience And Motivation 
            this.CalculateImpatience(confidence);

            % So far, gating is simply knowing if another robot is assigned
            % to a task
            
            % Taus grow at different rates, cooperation tau is double
            % effort
            % taus while not gripped are double as well
            
            
            %Create gating factor for motivation update.
            %Checks that task j is still incomplete, no other task j is
            %assigned to the agent, no more than two agents are assigned to
            %task j, and there are not better agents available.
            gating = sum(this.data(:,:,this.ji),1); % make a row array of flags, denoting if tasks are assigned
            gating = gating.*0; %We are allowed motivation toward our tasks even if they are assigned to another
            gating = (gating == 0); % Make them boolean (1 means it is avaliable)
            gating = gating + this.data(this.robotId,:,this.ji); % add in our own assignment status, 1 means we are allowed to be motivated toward our own task
            gating = gating > 0; %Make it boolean again
            gating = gating.*(1-this.data(this.robotId,:,this.ai)); % dont be motivated toward tasks that we should acquiesce
            gating = gating.*(1-this.data(this.robotId,:,this.ui)); % dont be motivated toward tasks that are finished!
            
            % Should end up with following gating array:
            % [1 0 0 0 1 0 1] Which means that item j=1 is permittied to
            % get motivated toward, whereas j=2 is not permitted to get
            % motivated toward.
            
            % update motivation
            motiv_past = this.data(this.robotId,:,this.mi);
            impatience = this.data(this.robotId,:,this.pi);
            motiv = (motiv_past + impatience.*delta).*gating;
            %save motivation
            this.data(this.robotId,:,this.mi) = motiv;
            
            
        end
        %%
        function ChooseTask(this)
            
            %preDat is for debugging task assignment at the end of the
            %function
            preDat = this.data(this.robotId,:,this.ji);
            
            
            if(this.useCooperation==1 && this.useCooperationLimit == 1)
                twoOnTasks = sum(this.data(:,:,this.ji),1);
                twoOnTasks = twoOnTasks > 1;
                coopingOnTasks = twoOnTasks .*this.data(this.robotId,:,this.ji);

                if(sum(coopingOnTasks ) > 0)
                    [amount,index] = max(coopingOnTasks,[],2);
                    this.data(this.robotId,index(1),this.ci) = 1;
                    %disp('am cooperating');
                end
            end
            if(sum( this.data(this.robotId,:,this.ji),1) == 0)
                %disp('choosing')
                
                if(this.calculateTau == 1)
                    this.tauCounter = 0;
                end
                %get motivation toward the task
                motiv = this.data(:,:,this.mi);
                % actual motivation - consider who is already working on a
                % task. If an agent is working toward a task, we do not
                % consider it motivated to it. (L1 % L2)
                robotFree= sum(this.data(:,:,this.ji),2) == 0; %(L1)
                
                actual_motiv = bsxfun(@times,motiv,robotFree); %(L2)
                % next, for actual motivation, we remove consideration toward 
                % 'taken' tasks (M1 % M2)
                if(this.useCooperation == 1)
                    taskFree= sum(this.data(:,:,this.ji),1) <= 1; %(M1)
                else
                    taskFree= sum(this.data(:,:,this.ji),1) == 0; %(M1)
                end
                
                if(this.useCooperation==1 && this.useCooperationLimit == 1)
                    %Here we prevent assignment to a task unless it looks like
                    %a robot will likely fail.

                    %quantify how much better each agent is than the tau
                    skillMatrix = this.data(:,:,this.di)- this.data(:,:,this.ti);

                    %agents in negative time are expected to fail
                    expectToFail = skillMatrix <0;

                    % agents that need help, are ones we expect to fail that
                    % have a task
                    needHelp = expectToFail.*this.data(:,:,this.ji);
                    needHelp = sum(needHelp ,1);
                    %the key line:
                    taskFree = needHelp.*taskFree + (sum(this.data(:,:,this.ji),1)==0); 
                     
                end                
                
                %A filter - we only assign ourselves to tasks that are not
                %finished. Obviously.
                taskFree = taskFree.*(1- this.data(this.robotId,:,this.ui));
                
                actual_motiv = bsxfun(@times,actual_motiv,taskFree); %(M2)
                actual_motiv  = actual_motiv  - this.motivation_Threshold;

                [amount,index] = max(actual_motiv,[],1);
                [amount2,index2] = max(amount,[],2);
                % take the task if you are the most motivated, and have
                % reached the threshold. Otherwise, the next agent will
                % likely take it when it chooses tasks.

                bestTask = index2(1);
                
                if((index(bestTask ) == this.robotId) && (amount(bestTask) > 0))
            %    amount
            %    index
            %    amount2    
            %    index2
                    %disp('task taken!')
                    
                    %assign a task
                    this.data(this.robotId,bestTask,this.ji) = 1;
                    
                    %Reset all other motivation toward our task
                    this.ImpatienceReset(bestTask);
                    %disp(strcat(num2str(this.robotId),' took a task!'));
                    %index(bestTask )
                end
                
                
            else
                %So we have a task, but should we still work toward it?
                if(sum(this.data(this.robotId,:,this.ji),2) > 1)
                    % if we have more than one task, error!
                    error('more than one task assigned!');
                end
                taskAssignment = this.data(this.robotId,:,this.ji);
                finishedTasks = this.data(this.robotId,:,this.ui);
                acquiescnece =  this.data(this.robotId,:,this.ai);
                assignedToFinishedTask = taskAssignment.*finishedTasks;

                if(sum(assignedToFinishedTask,2) > 0)
                    %disp('ass2fin2');
                    this.FinishTask();
                end
                
                if(sum(acquiescnece,2) > 0)
                    this.GiveUpTask();
                    
                end
                
            end
            
            %postDat = preDat - this.data(this.robotId,:,this.ji);
            
            %if(abs(sum(postDat,2)) > 0)
                %disp(strcat(num2str(this.robotId),' > chose a Task'))
                %preDat
                %this.data(this.robotId,:,this.ji)
            %end
        end
        %%
        function SetTaskFinished(this,taskId)
            %Set the task as finished, over all agents
            this.BroadcastGeneral(1:size(this.data,1), taskId, this.ui,1);
            
            %Then do some cleanup
            %disp('ass2fin3');
            this.FinishTask();
        end
        %%
        function FinishTask(this)
                %disp('assigned to a finished task! Im done!');
                % just disengage from all tasks
                    %disp('assigned to a finished task! Im done!');
                [amount,index] = max(this.data(this.robotId,:,this.ji),[],2);
                if(amount(1) > 0)
                    if(this.calculateTau == 1)
                        %numPre = this.data(this.robotId,index(1),this.ti);
                        this.UpdateTau(index(1),this.tauCounter);
                        %disp(strcat(['(',num2str(this.robotId),num2str(index(1)),')>',...
                        %     ' updating tau, because I finished ',num2str(numPre),' fast as',num2str(this.tauCounter), ...
                        %    ' with myTau: ',num2str(this.data(this.robotId,index(1),this.ti))]));

                        this.tauCounter = 0;
                    end

                    assignedTasksFinishedTasks = this.data(this.robotId,:,this.ui).*this.data(this.robotId,:,this.ji);
                    this.data(this.robotId,:,this.vi) = this.data(this.robotId,:,this.vi) + assignedTasksFinishedTasks;
                    %this.data(this.robotId,:,this.fi) = this.data(this.robotId,:,this.fi) + assignedTasksFinishedTasks;
                    this.data(this.robotId,:,this.ji) = this.data(this.robotId,:,this.ji) .*0;     

                    this.Broadcast();
                end
        end
        %%
        function taskId = GetCurrentTask(this)
            taskId = 0;
            taskAssignment = this.data(this.robotId,:,this.ji);
            finishedTasks = this.data(this.robotId,:,this.ui);
            acquiescnece =  this.data(this.robotId,:,this.ai);
            assignedToFinishedTask = taskAssignment.*finishedTasks;

            if(sum(assignedToFinishedTask,2) > 0)
                %disp('ass2fin');
                this.FinishTask();
            end

            if(sum(acquiescnece,2) > 0)
                this.GiveUpTask();
            end

            
            [number,index] = max(this.data(this.robotId,:,this.ji));
            if(number > 0)
                taskId = index(1);
            end
         
        end
        %%
        function SetTau(this,taskId,number)
            this.data(this.robotId,taskId,this.ti) = number;
        end
        %%
        function UpdateTau(this,taskId,number)
            
            %how many times we have worked with a task, and tracked it's
            %tau
            if(this.useCooperation==1 && this.useCooperationLimit == 1)
                %in here we wont save taus if we are cooperating.
                if( this.data(this.robotId,taskId,this.ci) == 1)
                    this.data(this.robotId,taskId,this.ci) = 0;
                    return;
                end
            end
            
            if(this.updateByTaskType == 1)
                % if we are updating by task type (and we should) we change
                % all taus of this type at once
                taskCat = mod(taskId,2);
                taskId = [];
                for i=1:size(this.data,2)
                    if(mod(i,2) == taskCat )
                        taskId = [taskId ;i];
                    end
                end
                %disp('updating taus');
                %taskId 
            end
            
            if(this.tauType == 1)
                oldNumber = this.data(this.robotId,taskId,this.ti);
                this.data(this.robotId,taskId,this.ti) = this.movingAverageKeep*oldNumber + (1-this.movingAverageKeep).*number;
                
                
            elseif(this.tauType == 2)
                    v = this.data(this.robotId,taskId,this.vi);
                    tau = this.data(this.robotId,taskId,this.ti); 
                    %use a decay rate, to help ignore terrible performance

                    pos = this.convergeAttempts/2;
                    beta = (exp(this.convergeSlope*(v-pos))...
                        ./(1+exp(this.convergeSlope*(v-pos))));
                    %update out task times, and our averages
                    learnRate = 1./(v./5+1);
                    tau = beta.*(tau + learnRate.*(number - tau) + 0) ;
                    %[this.data(this.robotId,taskId,this.ti) beta tau v]
                    this.data(this.robotId,taskId,this.ti) = tau;
            end
        end
        %%
        function UpdateTaskProperties(this,rstate)
            taskId = 0;
            [number,index] = max(this.data(this.robotId,:,this.ji));
            if(number > 0)
                taskId = index(1);
            end            
            %figure out if our task is finished from the state
            if(taskId ~= 0)
                [relativeTargetPos,relativeObjectPos,goalPos,borderWithWorld,robot,targetProperties] = rstate.GetCurrentState();
                if targetProperties(taskId ,1) == 1 %if it's not finished!
                    this.SetTaskFinished(taskId);
                end            
            end
        end
        
        %INTERFACE METHODS
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   GetTeamLearningData
        %   
        %   Return the maximum and minimum taus.
        %   This is meerely longest and shortest task
        %   completion time
        %   [task1_min task1_max   task2_min task2_max]
        
        %%       
        function dataReturn = GetLearningData(this)
            val1 = this.data(this.robotId,1,this.ti);
            val2 = this.data(this.robotId,2,this.ti);
            dataReturn = [val1 val1 val2 val2];
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   StartEpochChooseTask
        %   
        %   Choose a task :)
        
        %%           
        function StartEpochChooseTask(this, rstate)
            %Update our task properties
            this.UpdateTaskProperties(rstate);
            this.ChooseTask();
            this.Broadcast();
        end
  
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   GetCurrentTask
        %   
        %   Choose a task :)
        %           
        function taskId = GetTask(this,rstate)
            %Update our task properties
            this.UpdateTaskProperties(rstate);
            taskId = this.GetCurrentTask();
        end
        
        function UpdateMotivation(this,rewardIndividual,state,confidence)
            this.ticks = this.ticks + 1;
            
            if(mod(this.ticks, this.freq) == 0)
                this.ticks = 0;
                this.Update(this.config.lalliance_motiv_freq,confidence);
                this.Broadcast();
            end
        end
        
        
    end
    
end

