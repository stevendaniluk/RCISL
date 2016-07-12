classdef TeamLearning < handle
    % TEAMLEARNING - Contains learning capabilities for the team of robots
    
    % Merely a wrapper for LAlliance that provides an interface to be
    % used by ExecutiveSimulation
    
    properties
        config_ = [];
        l_alliance_ = [];
        num_robots_ = [];               % Number of robots
        num_targets_ = [];              % Number of targets
        iterations_ = [];
        task_allocation_ = [];
    end
    
    methods
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Constructor
        %   
        %   INPUTS:
        %   config = Configuration object
        
        function this = TeamLearning (config)
            this.config_ = config;
            this.task_allocation_ = config.task_allocation;
            this.num_robots_ = config.numRobots;
            this.num_targets_ = config.numTargets;
            this.iterations_ = 0;
            
            if (strcmp(this.task_allocation_, 'l_alliance'))
                this.l_alliance_ = LAlliance(this.config_);
            elseif (strcmp(this.task_allocation_, 'fixed'))
                if(this.num_robots_ ~= this.num_targets_)
                    error('Must have equal amounts of robots and targets with fixed task allocation strategy');
                end
            end
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   getTasks
        %   
        %   Calls upon L-Alliance to select the task, then stores in the
        %   RobotState for each robot
        %
        %   INPUTS:
        %   robots = Array of robot objects
        
        function getTasks(this, robots)
            for i = 1:this.num_robots_
                % Save the old task
                robots(i,1).robot_state_.prev_target_id_ = robots(i,1).robot_state_.target_id_;
                
                % Use appropriate task allocation strategy
                if (strcmp(this.task_allocation_, 'l_alliance'))
                    % Update task states
                    this.l_alliance_.updatetaskProperties(robots(i,1).robot_state_);
                    
                    % Recieve the updated task, and assign it
                    this.l_alliance_.chooseTask(robots(i,1).robot_state_.id_);
                    robots(i,1).robot_state_.target_id_ = this.l_alliance_.getCurrentTask(robots(i,1).robot_state_.id_);
                    
                elseif (strcmp(this.task_allocation_, 'fixed'))
                    
                    prelim_task_id = robots(i,1).robot_state_.id_;
                    
                    % Only assign the task if it is not complete
                    target_state = robots(i,1).robot_state_.target_properties_(prelim_task_id, 1);
                    if target_state == 1
                        robots(i,1).robot_state_.target_id_ = 0;
                    else
                        robots(i,1).robot_state_.target_id_ = prelim_task_id;
                    end
                    
                end
            end
            
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   learn
        %   
        %   Updates all task properties, and when necessary it will update
        %   the motivation of each robot towards the task
        %
        %   INPUTS:
        %   robots = Array of robot objects
        
        function learn(this, robots)
            this.iterations_ = this.iterations_ + 1;
            % Update the motivation if necessary
            if (mod(this.iterations_, this.config_.motiv_freq) == 0)
                for i = 1:this.num_robots_
                    if (strcmp(this.task_allocation_, 'l_alliance'))
                        this.l_alliance_.updateImpatience(robots(i,1).robot_state_.id_);
                        this.l_alliance_.updateMotivation(robots(i,1).robot_state_.id_);
                    end
                end
            end
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %   resetForNextRun
        %
        %   Resets all the necessary data for performing consecutive runs,
        %   while maintatining learning data
        
        function resetForNextRun(this)
            if (strcmp(this.task_allocation_, 'l_alliance'))
                this.l_alliance_.reset();
            end
        end
        
    end
    
end

