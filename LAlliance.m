classdef LAlliance < handle
    % LAlliance - L-Alliance algorithm for task allocation
    %
    % Based off the algorithm presented in [Lynne Parker, 1998], with
    % additional modoifications described in [Girard, 2015].
    %
    % Monitors the performance of all agents towards each tasks, then uses
    % those beliefs to assign new tasks to agents, and determine when to
    % give up on a task.
    
    properties (Access = private)
        % data is a multidimensional matrix, with one row for each robot,
        % one column for each task, and one page for each of the following
        % eleven parameters.        
        data_ = [];
        
        tau_i_ = 1;     % Average trial time
        mi_ = 2;        % Motivation
        pi_ = 3;        % Impatience Rate
        ai_ = 4;        % Aquiescence (Binary: 0=Keep, 1=Aquiesce)
        psi_i_ = 5;     % Psi: time currently on each task, [s11 .. sij ... s1M; ...]
        di_ = 6;        % Delta: Maximum allowed time on each task
        ji_ = 7;        % Task assignment (Binary: 0=Not assigned, 1=Assigned)
        ui_ = 8;        % Task Completion (Binary: 0=Not Completed, 1=Completed)
        fi_ = 9;        % Did we finish a task this epoch?
        vi_ = 10;       % Number of attempts at a task
        ci_ = 11;       % Are we currently cooperating? A flag
        
        num_robots_ = [];          % Number of robots
        num_tasks_ = [];           % Number of tasks
        
        % Algorithm parameters
        motiv_freq_ = [];               % Frequency at which motivation updates
        theta_ = [];                    % Motivation threshold
        min_delay_ = [];                % Minimum idle time
        max_delay_ = [];                % Maximum idle time
        trial_time_update_ = [];        % Method for updating trial times
        stochastic_update_theta2_ = []; % Coefficient for stochastic update
        stochastic_update_theta3_ = []; % Coefficient for stochastic update
        stochastic_update_theta4_ = []; % Coefficient for stochastic update
    end
    
    methods (Access = public)
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %   Constructor
        
        function this= LAlliance(config)            
            % Set number of robots and number of tasks
            this.num_robots_ = config.numRobots;
            this.num_tasks_ = config.numTargets;
            
            % Load L-Alliance parameters from configuration
            this.motiv_freq_ = config.motiv_freq;
            this.theta_ = config.theta;
            this.min_delay_ = config.min_delay;
            this.max_delay_ = config.max_delay;
            this.trial_time_update_ = config.trial_time_update;
            this.stochastic_update_theta2_ = config.stochastic_update_theta2;
            this.stochastic_update_theta3_ = config.stochastic_update_theta3;
            this.stochastic_update_theta4_ = config.stochastic_update_theta4;
            
            %Create empty multidimensional data array
            this.data_ = zeros(this.num_robots_, this.num_tasks_, 11);      
            this.data_(:, :, this.di_) = config.max_task_time;
            % Set initial average trial time to half of max allowed time
            % with some noise, so not all robots are equal
            this.data_(:,:,this.tau_i_) = normrnd(0.5*config.max_task_time, 5, [this.num_robots_, this.num_tasks_]);
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %   updatetaskProperties
        %
        %   Checks which task is currently assigned (if any), and calls the
        %   SetTaskFinished method to unassign the task if it is marked as 
        %   completed in the RobotState
        %
        %   INPUTS:
        %   robot_state = RobotState object for this robot
        
        function updatetaskProperties(this, robot_state)
            
            % Get which task is currently assigned
            task_id = find(this.data_(robot_state.id_, :, this.ji_), 1);
            
            % If a task is assigned, and if it is completed, finish it
            if(~isempty(task_id))
                % Increment psi (count of time on task)
                this.data_(robot_state.id_, task_id, this.psi_i_) = this.data_(robot_state.id_, task_id, this.psi_i_) + 1;
                
                target_state = robot_state.target_properties_(task_id, 1);
                if target_state == 1
                    this.finishTask(robot_state.id_, task_id);
                end 
            end

            % Make sure there is not more than one task assigned
            if(sum(this.data_(robot_state.id_, :, this.ji_), 2) > 1)
                error('More than one task assigned to robot %d', robot_state.id_); 
            end
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %   chooseTask
        %
        %   When a robot is free it will evaluate the motivation to assign
        %   a task. When a robot is currently assigned a task, it will
        %   evaluate the acquiescence to see if it should be given up.
        %
        %   A task is only assigned when a robot has the highest motivation
        %   towards that task.
        %
        %   INPUTS:
        %   robot_id = ID number of robot
        
        function chooseTask(this, robot_id)
            
            % COOPERATION NOT IMPLEMENTED YET
%             if(this.use_cooperation_==1 && this.use_cooperation_limit_ == 1)
%                 twoOnTasks = sum(this.data_(:,:,this.ji_),1);
%                 twoOnTasks = twoOnTasks > 1;
%                 coopingOnTasks = twoOnTasks .*this.data_(robot_id, :, this.ji_);
% 
%                 if(sum(coopingOnTasks ) > 0)
%                     [~,index] = max(coopingOnTasks,[],2);
%                     this.data_(robot_id, index(1), this.ci_) = 1;
%                 end
%             end
            
            % If a task is not assigned, one needs to be. If a task is
            % assigned, need to determine if it should still be pursued.
            if(sum(this.data_(robot_id, :, this.ji_), 1) == 0)                
                
                % COOPERATION NOT IMPLEMENTED YET
%                 % Find which tasks are free
%                 if(this.use_cooperation_ == 1)
%                     free_tasks= sum(this.data_(:,:,this.ji_),1) <= 1;
%                     
%                     if (this.use_cooperation_limit_ == 1)
%                         % Here we prevent assignment to a task unless it looks like
%                         % a robot will likely fail.
%                         
%                         % Quantify how much better each agent is than the tau
%                         skillMatrix = this.data_(:,:,this.di_)- this.data_(:,:,this.tau_i_);
%                         
%                         % Agents in negative time are expected to fail
%                         expectToFail = skillMatrix <0;
%                         
%                         % Agents that need help are ones we expect to fail that
%                         % have a task
%                         needHelp = expectToFail.*this.data_(:,:,this.ji_);
%                         needHelp = sum(needHelp ,1);
%                         % the key line:
%                         free_tasks = needHelp.*free_tasks + (sum(this.data_(:,:,this.ji_),1)==0);
%                     end
%                 else
%                     free_tasks = sum(this.data_(:,:,this.ji_),1) == 0;
%                 end               
                
                free_tasks = (sum(this.data_(:,:,this.ji_),1) == 0);
                
                % Find which tasks are not assigned
                free_tasks = free_tasks.*(1- this.data_(robot_id, :, this.ui_));
                % Find which robots are not assigned tasks
                free_robots= sum(this.data_(:,:,this.ji_),2) == 0;
                                
                % Actual motivation has zero motivation for robots with
                % tasks, and taken tasks
                actual_motiv = this.data_(:,:,this.mi_);
                actual_motiv(free_robots == 0, :) = 0;
                actual_motiv(:, free_tasks == 0) = 0;
                
                % Find which robot is the most motivated for each task, and
                % which task has the highest motivation
                [highest_motivs, best_robots] = max(actual_motiv);
                [~, best_task] = max(highest_motivs);
                                
                % Assign the best task if this robot is the most motivated 
                % towards it, and the motivation is above the threshold
                if((best_robots(best_task) == robot_id) && (highest_motivs(best_task) > this.theta_))
                    % Assign the task
                    this.data_(robot_id, best_task, this.ji_) = 1;
                    
                    % Reset all other motivation toward this task if this is
                    % the first time it is being attempted
                    if (this.data_(robot_id, best_task, this.vi_) == 0)
                        robots_not_on_task = sum(this.data_(:, best_task, this.ji_), 2) == 0;
                        this.data_(robots_not_on_task, best_task, this.mi_) = 0;
                    end
                end
            else                
                % Check acquiescence if the task should be given up
                acquiscence =  this.data_(robot_id, :, this.ai_);
                if(sum(acquiscence, 2) > 0)
                    this.giveUpTask(robot_id);
                end
            end
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %   getCurrentTask
        %
        %   Returns the currently assigned task id. If no task is assigned
        %   it returns zero.
        %
        %   INPUTS:
        %   robot_id = ID number of robot
        
        function task_id = getCurrentTask(this, robot_id)
            % Get which task is currently assigned
            task_id = find(this.data_(robot_id, :, this.ji_), 1);
            
            % Should return zero if no task is assigned
            if(isempty(task_id))
               task_id = 0; 
            end
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %   updateImpatience
        %
        %   Determines the impatiance rate for the inputted robot to each
        %   task. The rates are calculated as described in 
        %   [Lynne Parker, 1998]. The calculated values are then saved in
        %   the data matrix.
        %
        %   INPUTS:
        %   robot_id = ID number of robot
        
        function updateImpatience(this, robot_id)
            
            % COOPERATION NOT IMPLEMENTED YET
            
            % Loop through each task (since impatiance rates vary)
            for task = 1:this.num_tasks_
                % Find which robot is assigned this task
                robot_on_task = find(this.data_(:, task, this.ji_), 1);
                
                if (isempty(robot_on_task))
                    % No robot assigned to task, so grow at fast rate
                    high = max(max(this.data_(:,:,this.tau_i_)));
                    low = min(min(this.data_(:,:,this.tau_i_)));
                    scale_factor = (this.max_delay_ - this.min_delay_)/(high - low);
                    task_time = this.data_(robot_id, task, this.tau_i_);
                    
                    [~, best_robots] = min(this.data_(:, :, this.tau_i_));
                    
                    if (best_robots(task) == robot_id)
                        % This robot is expected to be the best (Z case 2)
                        fast_rate = this.theta_ / (this.min_delay_ + (task_time - low)*scale_factor);
                    else
                        % Another robot is expected to be the best (Z case 1)
                        fast_rate = this.theta_ / (this.max_delay_ + (task_time - low)*scale_factor);
                    end
                    this.data_(robot_id, task, this.pi_) = fast_rate;
                else
                    % Robot assigned to task, so grow at slow rate
                    slow_rate = this.theta_ / this.data_(robot_on_task, task, this.psi_i_);
                    this.data_(robot_id, task, this.pi_) = slow_rate;
                end
            end
            
            % Multiply for how many iterations between updates
            this.data_(robot_id, :, this.pi_) = this.data_(robot_id, :, this.pi_).*this.motiv_freq_;
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %   updateMotivation
        %
        %   Determines the acquiescence towards each task by finding for
        %   which tasks has the robot been enagaged longer than the max
        %   time allowed. This is then saved to the acquiescence property.
        %
        %   INPUTS:
        %   robot_id = ID number of robot
        
        function updateMotivation(this, robot_id)
            % Update acquiescence
            acquiescence = (this.data_(robot_id, :, this.psi_i_) > this.data_(robot_id, :, this.di_)); 
            acquiescence = acquiescence.*this.data_(robot_id, :, this.ji_);
            this.data_(robot_id, :, this.ai_) = acquiescence;
            
            % Create a gating array for motivation update. Need to prevent
            % motivation updates for tasks that the robot should acquiesce,
            % and tasks that are completed.
            gating = (1-this.data_(robot_id, :, this.ai_));
            gating = gating.*gating.*(1-this.data_(robot_id, :, this.ui_));
            
            % Update motivation (Equation (1) in [Lynne Parker, 1998])
            motiv_prev = this.data_(robot_id, :, this.mi_);
            impatience = this.data_(robot_id, :, this.pi_);
            motiv = (motiv_prev + impatience).*gating;
            
            % Save the motivation
            this.data_(robot_id, :, this.mi_) = motiv;
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %   reset
        %
        %   Resets all the necessary data for performing consecutive runs,
        %   while maintatining learning data
        
        function reset(this)
            this.data_(:, :, this.mi_) = 0;     % No motivation
            this.data_(:, :, this.ji_) = 0;     % No tasks
            this.data_(:, :, this.ai_) = 0;     % No acquiescence
            this.data_(:, :, this.psi_i_) = 0;  % No time on task
            this.data_(:, :, this.ui_) = 0;     % No completed tasks
            this.data_(:, :, this.ci_) = 0;     % No cooperation
        end
        
    end
    
    methods (Access = private)
                        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %   updateTau
        %
        %   Updates the average trial time with a cumulative moving average
        %   of the time on a specific task
        %
        %   INPUTS:
        %   robot_id = ID number of robot to update
        %   task_id = ID number of task to update
        
        function updateTau(this, robot_id, task_id)
            % COOPERATION NOT IMPLEMENTED YET
            % Don't save tau's if we are cooperating
%             if(this.use_cooperation_==1 && this.use_cooperation_limit_ == 1)
%                 if( this.data_(robot_id, task_id, this.ci_) == 1)
%                     this.data_(robot_id, task_id, this.ci_) = 0;
%                     return;
%                 end
%             end
            
            % Update new tau value according to method dictated in config
            if (strcmp(this.trial_time_update_, 'moving_average'))
                % Calculate a cumulative moving average for the tau values
                tau_old = this.data_(robot_id, task_id, this.tau_i_);
                time_on_task = this.data_(robot_id, task_id, this.psi_i_);
                tau_new = tau_old + (time_on_task - tau_old)/2;
            elseif (strcmp(this.trial_time_update_, 'recursive_stochastic'))
                % Update according to formulation in [Girard, 2015]
                theta2 = this.stochastic_update_theta2_;
                theta3 = this.stochastic_update_theta3_;
                theta4 = this.stochastic_update_theta4_;
                f = this.data_(robot_id, task_id, this.vi_);
                beta = exp(f / theta4)/(theta3 + exp(f / theta4));
                
                tau_old = this.data_(robot_id, task_id, this.tau_i_);
                time_on_task = this.data_(robot_id, task_id, this.psi_i_);
                
                tau_new = beta*(tau_old + (theta2 / f)*(time_on_task - tau_old));
            end
            
            % Save the new tau value
            this.data_(robot_id, task_id, this.tau_i_) = tau_new;
        end
                                                                
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %   finishTask
        %
        %   For when a task is completed (as reported by the RobotState),
        %   its completion will be set for all agents, the task
        %   completion counter will be increased, and the assigned task
        %   will be reset.
        %
        %   INPUTS:
        %   robot_id = ID number of robot
        %   task_id = ID number of task
        
        function finishTask(this, robot_id, task_id)
            % Set task as finished for all robots
            this.data_(:, task_id, this.ui_) = 1;
            % Increment the task attempts
            this.data_(robot_id, task_id, this.vi_) = this.data_(robot_id, task_id, this.vi_) + 1;
            % Update the taus
            this.updateTau(robot_id, task_id);
            
            % Reset the time on task
            this.data_(robot_id, task_id, this.psi_i_) = 0;
            % Reset task assignment to zero for this robot
            this.data_(robot_id, :, this.ji_) = 0;
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %   giveUpTask
        %
        %   Unassign the task from this robot, and zero all related
        %   L-Alliance parameters
        %
        %   INPUTS:
        %   robot_id = ID number of robot
        
        function giveUpTask(this, robot_id)
            % Find the assigned task id
            [~, task_id] = find(this.data_(robot_id, :, this.ji_));
            % Increment the task attempts
            this.data_(robot_id, task_id, this.vi_) = this.data_(robot_id, task_id, this.vi_) + 1;
            % Update the taus
            this.updateTau(robot_id, task_id);
            
            % Unassign the task, zero the motivation, zero the acquiesence,
            % zero the time on task, and zero the cooperation
            this.data_(robot_id, task_id, this.ji_) = 0;
            this.data_(robot_id, task_id, this.mi_) = 0;
            this.data_(robot_id,:,this.ai_) = 0;
            this.data_(robot_id, task_id, this.psi_i_) = 0;
            this.data_(robot_id,:,this.ci_) = 0;
        end
                                        
    end
    
end
