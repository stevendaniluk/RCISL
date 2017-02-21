classdef LAlliance < handle
  % LALLIANCE - L-Alliance algorithm for task allocation
  %
  % Based off the algorithm presented in [Lynne Parker, 1998], with
  % additional modoifications described in [Girard, 2015].
  %
  % Monitors the performance of all agents towards each tasks, then uses
  % those beliefs to assign new tasks to agents, and determine when to
  % give up on a task.
  
  properties (Access = public)
    config_;  % Configuration object
    
    % data_ is a multidimensional matrix, with rows for robots, columns
    % for tasks, and pages for each of the twelve parameters
    data_;
  end
  
  properties (Constant)
    % Indices for data array
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
    std_ = 12       % Standard deviation of tau values
  end
  
  methods (Access = public)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %   Constructor
    
    function this= LAlliance(config)
      this.config_ = config;
      
      %Create empty multidimensional data array
      this.data_ = zeros(this.config_.scenario.num_robots, this.config_.scenario.num_targets, 12);
      this.data_(:, :, this.di_) = this.config_.TL.LA.max_task_time;
      % Set initial average trial time to half of max allowed time
      % with some noise, so not all robots are equal
      this.data_(:,:,this.tau_i_) = normrnd(0.5*this.config_.TL.LA.max_task_time, 20, [this.config_.scenario.num_robots, this.config_.scenario.num_targets]);
      
      % Initialize the tau standard deviation
      task_standard_dev = std(this.data_(:, :, this.tau_i_), 0, 2);
      this.data_(:, :, this.std_) = repelem(task_standard_dev, 1, this.config_.scenario.num_targets);
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
    %   robot_id = Id number of the robot to be updated
    %   world_state = WorldState object
    
    function updatetaskProperties(this, robot_id, world_state)
      
      % Get which task is currently assigned
      task_id = find(this.data_(robot_id, :, this.ji_), 1);
      
      % If a task is assigned, and if it is completed, finish it
      if(~isempty(task_id))
        % Increment psi (count of time on task)
        this.data_(robot_id, task_id, this.psi_i_) = this.data_(robot_id, task_id, this.psi_i_) + 1;
        
        if world_state.targets_(task_id).returned == 1
          this.finishTask(robot_id, task_id);
        end
        
        % Acquiesce if we've been on the task too long
        if (this.data_(robot_id, task_id, this.psi_i_) > this.data_(robot_id, task_id, this.di_))
          this.giveUpTask(robot_id);
        end
      end
      
      % Make sure there is not more than one task assigned
      if(sum(this.data_(robot_id, :, this.ji_), 2) > 1)
        error('More than one task assigned to robot %d', robot_id);
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
      % If a task is not assigned, one needs to be. If a task is
      % assigned, need to determine if it should still be pursued.
      if(sum(this.data_(robot_id, :, this.ji_), 1) == 0)
        
        % Task type categories
        category1 = zeros(this.config_.scenario.num_targets, 1);
        category2 = zeros(this.config_.scenario.num_targets, 1);
        
        for i=1:this.config_.scenario.num_targets
          % Tasks are considered available when they are incomplete,
          % and either no avatar is assigned, or the assigned avatar
          % has been attempting the task for longer than their tau value
          % plus one standard deviation of their taus
          uncomplete = sum(this.data_(:, i,this.ui_)) == 0;
          unassigned = sum(this.data_(:, i,this.ji_)) == 0;
          can_takover = this.data_(:, i, this.psi_i_) > (this.data_(:, i, this.tau_i_) + this.data_(:, i, this.std_));
          can_takover = sum(can_takover) ~= 0;
          
          if (uncomplete && (unassigned || can_takover))
            % Only look at motivation and trial time of free robots
            motiv = this.data_(:, i,this.mi_);
            
            if (motiv(robot_id) == 0)
              % Must have some motivation to avoid defaulting
              % to the first robot in the list
              break;
            end
            
            motiv(sum(this.data_(:,:,this.ji_), 2) == 1) = -inf;
            [~, most_motivated] = max(motiv);
            
            task_time = this.data_(:, i,this.tau_i_);
            task_time(sum(this.data_(:,:,this.ji_), 2) == 1) = inf;
            [~, fastest] = min(task_time);
            
            if (most_motivated == robot_id)
              if (fastest == robot_id)
                % Expected to be the best, so assign to category 1
                category1(i) = this.data_(robot_id, i, this.tau_i_);
              else
                % Another robot is expected to be better, so
                % assign to category 2
                category2(i) = this.data_(robot_id, i, this.tau_i_);
              end
              
            end
          end
          
        end
        
        % Take the longest task from category 1, or if no tasks
        % belong to category 1 take the shortest task from category 2
        if (sum(category1) ~= 0)
          % There is a task this avatar is expected to be the best at
          [~, best_task] = max(category1);
        elseif (sum(category2 ~= 0))
          % This avatar is not expected to be the best at any available task
          category2(category2 == 0) = inf;
          [~, best_task] = min(category2);
        else
          best_task = 0;
        end
        
        if (best_task ~= 0)
          % Check if another avatar was assigned and must acquiesce
          assigned_robot = find(this.data_(:, best_task, this.ji_));
          if(~isempty(assigned_robot))
            % Make sure this task can be taken over
            can_takover = this.data_(assigned_robot, best_task, this.psi_i_) ...
              > (this.data_(assigned_robot, best_task, this.tau_i_) ...
              + this.data_(assigned_robot, best_task, this.std_));
            if (can_takover)
              % Make it acquisce
              this.giveUpTask(assigned_robot);
            else
              % Cannot assign this task
              return;
            end
          end
          
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
        acquiescence = (this.data_(robot_id, :, this.psi_i_) > this.data_(robot_id, :, this.di_));
        acquiescence = acquiescence.*this.data_(robot_id, :, this.ji_);
        
        if(sum(acquiescence, 2) > 0)
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
        task_id = -1;
      end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %   updateImpatience
    %
    %   Determines the impatiance rate for the inputted robot to each
    %   task. The rates are calculated as described in
    %   [Lynne Parker, 1998], with the modification from [Girard, 2015]
    %   for pareto-optimal task selection.
    %
    %   INPUTS:
    %   robot_id = ID number of robot
    
    function updateImpatience(this, robot_id)
      % Loop through each task (since impatiance rates vary)
      for task = 1:this.config_.scenario.num_targets
        if (this.data_(robot_id, task, this.ui_) == 1 || this.data_(robot_id, task, this.ji_) == 1)
          % Task belongs to this robot, or is completed, so no
          % impatience needed
          this.data_(robot_id, task, this.pi_) = 0;
        else
          % Grow at slow rate
          slow_rate = this.config_.TL.LA.theta1 / this.data_(robot_id, task, this.tau_i_);
          this.data_(robot_id, task, this.pi_) = slow_rate;
        end
      end
      
      % Multiply for how many iterations between updates
      this.data_(robot_id, :, this.pi_) = this.data_(robot_id, :, this.pi_).*this.config_.TL.LA.motiv_freq;
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
      % Update new tau value according to method dictated in config
      if (strcmp(this.config_.TL.LA.trial_time_update, 'moving_avg'))
        % Calculate a cumulative moving average for the tau values
        tau_old = this.data_(robot_id, task_id, this.tau_i_);
        time_on_task = this.data_(robot_id, task_id, this.psi_i_);
        tau_new = tau_old + (time_on_task - tau_old)/2;
      elseif (strcmp(this.config_.TL.LA.trial_time_update, 'stochastic'))
        % Update according to formulation in [Girard, 2015]
        theta2 = this.config_.TL.LA.theta2;
        theta3 = this.config_.TL.LA.theta3;
        theta4 = this.config_.TL.LA.theta4;
        f = this.data_(robot_id, task_id, this.vi_);
        beta = exp(f / theta4)/(theta3 + exp(f / theta4));
        
        tau_old = this.data_(robot_id, task_id, this.tau_i_);
        time_on_task = this.data_(robot_id, task_id, this.psi_i_);
        
        tau_new = beta*(tau_old + exp(-f/theta2)*(time_on_task - tau_old));
      end
      
      % Save the new tau value
      this.data_(robot_id, task_id, this.tau_i_) = tau_new;
      
      % Update tau standard deviation
      this.data_(robot_id, :, this.std_) = std(this.data_(robot_id, :, this.tau_i_));
      
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
