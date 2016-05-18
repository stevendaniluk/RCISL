classdef TeamLearning < handle
    % TEAMLEARNING - Contains learning capabilities for the team of robots
    
    % Currently merely a wrapper for LAllianceAgent
    
    properties
        config_ = [];
        l_alliance_ = [];
        iterations_ = [];
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
            this.l_alliance_ = LAlliance(this.config_);
            this.iterations_ = 0;
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
            for i = 1:length(robots)
                % Save the old task
                robots(i,1).robot_state_.prev_target_id_ = robots(i,1).robot_state_.target_id_;
                
                % Recieve the updated task, and assign it
                this.l_alliance_.ChooseTask(robots(i,1).robot_state_.id_);
                robots(i,1).robot_state_.target_id_ = this.l_alliance_.GetCurrentTask(robots(i,1).robot_state_.id_);
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
            
            for i = 1:length(robots)
                % Update task states
                this.l_alliance_.UpdateTaskProperties(robots(i,1).robot_state_);
                
                % Update the motivation if necessary
                if (mod(this.iterations_, this.config_.lalliance_motiv_freq) == 0)                    
                    % Get relative target positions, and convert to euclidean
                    % distance
                    rel_target_pos = robots(i,1).robot_state_.getRelTargetPositions();
                    rel_target_pos = rel_target_pos.^2;
                    rel_target_pos = sum(rel_target_pos, 2);
                    rel_target_pos = sqrt(rel_target_pos);
                    
                    % This was implemented, but not sure why yet
                    rel_target_pos = rel_target_pos / robots(i,1).robot_state_.step_size_;
                    
                    % L-Alliance expects a row vector
                    rel_target_pos = rel_target_pos';
                    
                    if(this.config_.lalliance_useDistance == 0)
                        rel_target_pos = rel_target_pos.*0;
                    end
                    this.l_alliance_.UpdateMotivation(robots(i,1).robot_state_.id_, rel_target_pos);
                end
            end
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %   resetForNextRun
        %
        %   Resets all the necessary data for performing consecutive runs,
        %   while maintatining learnign data
        
        function resetForNextRun(this)
            this.l_alliance_.Reset();
        end
        
    end
    
end

