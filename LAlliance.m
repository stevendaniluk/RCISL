classdef LAlliance < handle
    % LALLIANCEAGENT Summary of this class goes here
    %   The agent class stores beliefs about other agent performance
    %   and decides when to take over tasks
    
    properties
        %Each of the following 11 parameters will form an nxm matrix, and
        %will be added to the 11 page  multidimensional array data[].
        %Values are assigned to each parameter name to index data[] pages
        data = [];
        
        ti = 1;     % Tau's: Average trial time (time robot i lets pass without
                    % recieving message from teammate)
                    
        mi = 2;     % Motivation: Each robots motivation towards each task
                    % [0,Theta]
                    
        pi = 3;     % Impatience Rate: Each robots impatiance towards each task
        
        ai = 4;     % Aquiescence: Each robots acquiesence towards each task
                    % Binary [0,1] 0=Keep, 1=Aquiesce
                    
        si = 5;     % Psi: time currently on each task, [s11 .. sij ... s1M; ...]
        
        di = 6;     % Delta: Maximum allowed time on each task
        
        ji = 7;     % Task Assignment: What task each robot is assigned to
                    % Binary [0,1] 0=Not assigned, 1=Assigned
        ui = 8;     % Task Completion, as percieved by each agent
                    % Binary [0,1] 0=Not Completed, 1=Completed
        
        fi = 9;     % Did we finish a task this epoch? [u11 .. uij ... u1M;...]

        vi = 10;    % Did we finishe a task this epoch? [u11 .. uij ... u1M;...]
        
        ci = 11;    % Are we currently cooperating? A flag
        
        n = [];          %number of robots
        m = [];          %number of tasks
        
        %ALLIANCE Parameters
        theta = [];
        motivation_Threshold = [];
        movingAverageKeep = [];
        
        convergeAttempts = [];
        convergeSlope = [];

        confidence_Factor = [];
        
        %tauType = 1 - Moving Average
        tauType = [];
        
        tmax = [];
        tmin = [];
        
        %default to using only the slow impatience rate
        useFast = [];
        
        %Do we store taus for cooperation?
        useCooperation = [];
        useCooperationLimit = [];
        
        %Do we automatically calculate taus?
        calculateTau = [];
        tauCounter = 0;
        failureTau = [];
        
        updateByTaskType = [];
        ticks = 0;
        motiv_freq = [];
    end
    
    methods
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %   Constructor
        
        function this= LAlliance(config)            
            %Set number of robots and number of tasks (1 Target=1 task)
            this.n = config.numRobots;
            this.m = config.numTargets;
            
            %Parameter values taken from Configuration Run
            this. theta = config.lalliance_theta ;
            this.motivation_Threshold = config.lalliance_motivation_Threshold ;
            this.movingAverageKeep = config.lalliance_movingAverageKeep ;
            this.convergeAttempts = config.lalliance_convergeAttempts ;
            this.convergeSlope =  config.lalliance_convergeSlope ;

            this.tauType = config.lalliance_tauType ;

            this.tmax = config.lalliance_tmax ;
            this.tmin = config.lalliance_tmin ;

            %default to using only the slow impatience rate
            this.useFast = config.lalliance_useFast;

            %Do we store taus for cooperation?
            this.useCooperation = config.lalliance_useCooperation;
            this.useCooperationLimit = config.lalliance_useCooperationLimit;
            
            %Do we automatically calculate taus?
            this.calculateTau = config.lalliance_calculateTau ;
            this.failureTau = config.lalliance_failureTau ;
            this.updateByTaskType = config.lalliance_updateByTaskType ;
            this.motiv_freq = config.lalliance_motiv_freq;
            
            %Create empty multidimensional data array
            %Rows correspond to robots
            %Collumns correspond to tasks
            %Pages correspond to the number of ALLIANCE parameters
            this.data = zeros(this.n, this.m, 11);      
           
            this.data(:, :, this.di) = config.lalliance_acquiescence;
            this.confidence_Factor = config.lalliance_confidenceFactor;
            this.data(:,:,this.ti) = 700; %Assume you are the best!
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %   UpdateTaskProperties
        %
        %   Checks which task is currently assigned (if any), and calls the
        %   SetTaskFinished method to unassign the task if it is marked as 
        %   completed in the RobotState
        
        function UpdateTaskProperties(this, robot_state)
            % Get which task is currently assigned
            task_id = find(this.data(robot_state.id_, :, this.ji), 1);
            
            % If a task is assigned, and if it is completed, finish it
            if(~isempty(task_id))
                target_state = robot_state.target_properties_(task_id, 1);
                if target_state == 1 %if it's finished!
                    this.FinishTask(robot_state.id_, task_id);
                end 
            end
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %   ChooseTask
        %
        %   When a robot is free it will evaluate the motivation to assign
        %   a task. When a robot is currently assigned a task, it will
        %   evaluate the acquiescence to see if it should be given up.
        
        function ChooseTask(this, robot_id)

            if(this.useCooperation==1 && this.useCooperationLimit == 1)
                twoOnTasks = sum(this.data(:,:,this.ji),1);
                twoOnTasks = twoOnTasks > 1;
                coopingOnTasks = twoOnTasks .*this.data(robot_id, :, this.ji);

                if(sum(coopingOnTasks ) > 0)
                    [~,index] = max(coopingOnTasks,[],2);
                    this.data(robot_id, index(1), this.ci) = 1;
                end
            end
            
            % If a task is not assigned, one needs to be. If a task is
            % assigned, it needs to be determined if it should still be
            % pursued.
            if(sum(this.data(robot_id, :, this.ji), 1) == 0)                
                if(this.calculateTau == 1)
                    this.tauCounter = 0;
                end
                
                % Find which tasks are free
                if(this.useCooperation == 1)
                    taskFree= sum(this.data(:,:,this.ji),1) <= 1;
                    
                    if (this.useCooperationLimit == 1)
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
                else
                    taskFree= sum(this.data(:,:,this.ji),1) == 0;
                end               
                
                % Filter out tasks that are finished
                taskFree = taskFree.*(1- this.data(robot_id, :, this.ui));
                
                % Find which robots are not assigned tasks
                robotFree= sum(this.data(:,:,this.ji),2) == 0;
                
                % Get motivation toward the task
                motiv = this.data(:,:,this.mi);
                % actual motivation - consider who is already working on a
                % task. If an agent is working toward a task, we do not
                % consider it motivated to it.
                actual_motiv = bsxfun(@times,motiv,robotFree);
                % next, for actual motivation, we remove consideration toward 
                % 'taken' tasks
                actual_motiv = bsxfun(@times,actual_motiv,taskFree);
                actual_motiv  = actual_motiv  - this.motivation_Threshold;
                
                
                % Find the highest motivations for each task, and which
                % robot that motivation corresponds to
                [motiv_values, best_robots] = max(actual_motiv);
                [~, best_task] = max(motiv_values);
                % take the task if you are the most motivated, and have
                % reached the threshold. Otherwise, the next agent will
                % likely take it when it chooses tasks.
                
                % Assign the best task if thi robot is the most motivated 
                % towards it, and the motivation is above the threshold
                if((best_robots(best_task) == robot_id) && (motiv_values(best_task) > 0))
                    % Assign the task
                    this.data(robot_id, best_task, this.ji) = 1;
                    
                    %Reset all other motivation toward this task
                    robots_not_on_task = sum(this.data(:, best_task, this.ji), 2) == 0;
                    this.data(robots_not_on_task, best_task, this.mi) = 0;
                end
            else                
                % Make sure there is not more than one task assigned
                if(sum(this.data(robot_id, :, this.ji), 2) > 1)
                    % if we have more than one task, error!
                    error('more than one task assigned!');
                end
                                
                % Check acquiescence if the task should be given up
                acquiscence =  this.data(robot_id, :, this.ai);
                if(sum(acquiscence,2) > 0)
                    this.GiveUpTask(robot_id);
                end
            end
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %   UpdateMotivation
        
        function UpdateMotivation(this, robot_id, confidence)
            this.Update(robot_id, this.motiv_freq, confidence);
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %   Update
        %
        %   Determines the acquiescence towards each task by finding for
        %   which tasks has the robot been enagaged longer than the max
        %   time allowed. This is then saved to the acquiescence property.
        
        function Update(this, robot_id, delta, confidence)
            
            if(this.calculateTau == 1)
                this.tauCounter = this.tauCounter  + delta;                
            end
            
            % Acquiescence: update PSI, which is a count of how long we 
            % have engaged a task 
            this.data(robot_id, :, this.si) = (this.data(robot_id, :, this.si) + delta).*this.data(robot_id, :, this.ji); 
            % Update Acquiescence
            AcquiescenceAllowed = this.data(robot_id, :, this.di) > 0;
            AcquiescenceShould = (this.data(robot_id, :, this.si) > this.data(robot_id, :, this.di)); 
            Acquiescence = AcquiescenceAllowed .*AcquiescenceShould .*this.data(robot_id, :, this.ji);
            this.data(robot_id, :, this.ai) = Acquiescence ;
            
            % Impatience And Motivation 
            this.CalculateImpatience(robot_id, confidence);

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
            gating = gating + this.data(robot_id, :, this.ji); % add in our own assignment status, 1 means we are allowed to be motivated toward our own task
            gating = gating > 0; %Make it boolean again
            gating = gating.*(1-this.data(robot_id, :, this.ai)); % dont be motivated toward tasks that we should acquiesce
            gating = gating.*(1-this.data(robot_id, :, this.ui)); % dont be motivated toward tasks that are finished!
            
            % Should end up with following gating array:
            % [1 0 0 0 1 0 1] Which means that item j=1 is permittied to
            % get motivated toward, whereas j=2 is not permitted to get
            % motivated toward.
            
            % update motivation
            motiv_past = this.data(robot_id, :, this.mi);
            impatience = this.data(robot_id, :, this.pi);
            motiv = (motiv_past + impatience.*delta).*gating;
            %save motivation
            this.data(robot_id, :, this.mi) = motiv;
        end
                
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %   CalculateImpatience
        %
        %   Evaluates tau values for each task and determines the
        %   impatiance towards each task
        
        function CalculateImpatience(this, robot_id, confidence)
           
            if(this.useCooperation ~=1)
                num_tasks = size(this.data(robot_id, :, this.ti), 2);
                tauAdd = zeros(1, num_tasks);
            else
                assignedOther = this.data(:,:,this.ji);
                assignedOther(robot_id, :) = 0; %forget about us.
                tauAdd = (this.data(:,:,this.ti)+100).*assignedOther; % all the taus of robots currently assigned
                assignedOther = sum(assignedOther,1);
                assignedOther = (assignedOther ==1); %we are looking at tasks with only one robot
                tauAdd = bsxfun(@times,tauAdd,assignedOther); %mask out the unassigned, and the double assigned
                tauAdd = sum(tauAdd,1); 
            end
            
            confidenceAdd = confidence.*this.confidence_Factor;
            
            slow_rate = this.theta./((this.data(robot_id, :, this.ti) +tauAdd)+ confidenceAdd+ 1);
            
            if(this.useFast == 1)
                %variables needed to calc the fast rate
                tau_vals = this.data(:,:,this.ti);
                tau_vals(robot_id, :) = tau_vals(robot_id, :) + tauAdd + confidenceAdd; % we add to the tau of double assigned tasks
                min_tau = min(min(tau_vals(:,:)));
                max_tau = max(max(tau_vals(:,:)));
                my_tau = tau_vals(robot_id, :); % we add to the tau of double assigned tasks
                scale = (this.tmax - this.tmin)/(max_tau - min_tau);
                
                %fast superior impatience rate (used when you are the best)
                fast_superior_rate = this.theta./((this.tmax - (my_tau  - min_tau))*scale + 1);

                %fast mediocre impatience rate
                fast_mediocre_rate = this.theta./((this.tmin + (my_tau  - min_tau))*scale + 1);

                minTauRow = min(tau_vals(:,:));
                
                have_done_task = this.data(robot_id, :, this.vi) > 0;
                
                am_best_at_task = (minTauRow == my_tau);
                not_best_at_task = 1- am_best_at_task;
           
                this.data(robot_id, :, this.pi)  = ...
                    fast_superior_rate.*am_best_at_task.*have_done_task + ...
                    fast_mediocre_rate.*not_best_at_task.*have_done_task + ...
                    slow_rate.*(1 - have_done_task);
            else
                this.data(robot_id, :, this.pi)  = slow_rate;
            end
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %   UpdateTau
        
        function UpdateTau(this, robot_id, task_id, number)
            %how many times we have worked with a task, and tracked it's
            %tau
            if(this.useCooperation==1 && this.useCooperationLimit == 1)
                %in here we wont save taus if we are cooperating.
                if( this.data(robot_id, task_id, this.ci) == 1)
                    this.data(robot_id, task_id, this.ci) = 0;
                    return;
                end
            end
            
            if(this.updateByTaskType == 1)
                % if we are updating by task type (and we should) we change
                % all taus of this type at once
                taskCat = mod(task_id, 2);
                task_id = [];
                for i=1:size(this.data,2)
                    if(mod(i,2) == taskCat )
                        task_id = [task_id ;i];
                    end
                end
            end
            
            if(this.tauType == 1)
                oldNumber = this.data(robot_id, task_id, this.ti);
                this.data(robot_id, task_id, this.ti) = this.movingAverageKeep*oldNumber + (1-this.movingAverageKeep).*number;
                
            elseif(this.tauType == 2)
                v = this.data(robot_id, task_id, this.vi);
                tau = this.data(robot_id, task_id, this.ti);
                %use a decay rate, to help ignore terrible performance
                
                pos = this.convergeAttempts/2;
                beta = (exp(this.convergeSlope*(v-pos))...
                    ./(1+exp(this.convergeSlope*(v-pos))));
                %update out task times, and our averages
                learnRate = 1./(v./5+1);
                tau = beta.*(tau + learnRate.*(number - tau) + 0) ;
                this.data(robot_id, task_id, this.ti) = tau;
            end
        end
                                                                
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %   FinishTask
        %
        %   For when a task is completed (as reported by the RobotState),
        %   its completion will be set for all agents, the task
        %   completion counter will be increased, and the assigned task
        %   will be reset.
        
        function FinishTask(this, robot_id, task_id)
            % Set task as finished for all robots
            this.data(:, task_id, this.ui) = 1;
                        
            if(this.calculateTau == 1)
                this.UpdateTau(robot_id, task_id, this.tauCounter);
                this.tauCounter = 0;
            end
            
            assignedTasksFinishedTasks = this.data(robot_id, :, this.ui).*this.data(robot_id, :, this.ji);
            this.data(robot_id, :, this.vi) = this.data(robot_id, :, this.vi) + assignedTasksFinishedTasks;
            this.data(robot_id, :, this.ji) = this.data(robot_id, :, this.ji) .*0;
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %   GiveUpTask
        %
        %   Unassign the task from this robot, zero the motivation of this
        %   robot towards this task, zero the acquiescence of this robot
        %   towards all tasks, and zero the cooperation of this robot
        %   towards all tasks
        
        function GiveUpTask(this, robot_id)
            % Find the assigned task id
            [~, task_id] = find(this.data(robot_id, :, this.ji));
            if(this.calculateTau ==1)
                this.UpdateTau(robot_id, task_id, this.failureTau);
            end
            
            % Increment the vi counter
            this.data(robot_id, task_id, this.vi) = this.data(robot_id, task_id, this.vi) + 1;
            
            % Unassign the task, zero the motivation, zero the acquiesence
            % and zero the cooperation
            this.data(robot_id, :, this.ji) = this.data(robot_id, :, this.ji) .*0;
            this.data(robot_id, task_id, this.mi) = 0;
            this.data(robot_id,:,this.ai) = 0;
            this.data(robot_id,:,this.ci) = 0;
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %   GetCurrentTask
        %
        %   Returns the currently assigned task id. If no task is assigned
        %   it returns zero.
        
        function task_id = GetCurrentTask(this, robot_id)
            % Get which task is currently assigned
            task_id = find(this.data(robot_id, :, this.ji), 1);
            
            % Should return zero if no task is assigned
            if(isempty(task_id))
               task_id = 0; 
            end
        end
                        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %   Reset
        
        function Reset(this)
            this.tauCounter = 0;
            this.data(:, :, this.mi) = 0; % have no intrinsic motivation
            this.data(:, :, this.ji) = 0; % not assigned to any boxes
            this.data(:, :, this.ai) = 0; % not assigned to any boxes
            this.data(:, :, this.si) = 0; % not assigned to any boxes
            this.data(:, :, this.ui) = 0; % have not finished any tasks
            this.data(:, :, this.ci) = 0; % have not finished any tasks
        end
                
    end
    
end
