classdef TeamLearning < handle
    % TEAMLEARNING - Contains learning capabilities for the team of robots
    
    % Currently merely a wrapper for LAllianceAgent
    
    properties
        id_ = [];
        config_ = [];
        l_alliance_ = [];
    end
    
    methods
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Constructor
        %   
        %   INPUTS
        %   config = Configuration object
        %   robot_id = Id number for this robot
        
        function this = TeamLearning (config, robot_id)
            this.config_ = config;
            this.id_ = robot_id;
            this.l_alliance_ = LAllianceAgent(this.config_, this.id_);
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   getTask
        %   
        %   Calls upon L-Alliance to get a task ID, then assigns that id to
        %   this robot's robot_state
        %
        %   INPUTS
        %   robot_state = RobotState object for this robot
        
        function getTask(this, robot_state)
            % Save the old task
            robot_state.prev_target_id_ = robot_state.target_id_;
            
            this.l_alliance_.UpdateTaskProperties(robot_state);
            this.l_alliance_.ChooseTask();
            this.l_alliance_.Broadcast();
            robot_state.target_id_ = this.l_alliance_.GetCurrentTask();
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   UpdateMotivation
        %   
        %   Calls UpdateMotivation method from LAllianceAgent class, with
        %   the relative target positions
        %
        %   INPUTS
        %   robot_state = RobotState object for this robot
        
        function updateMotivation(this, robot_state) 
            % Get relative target positions, and convert to euclidean
            % distance
            rel_target_pos = robot_state.getRelTargetPositions();
            rel_target_pos = rel_target_pos.^2;
            rel_target_pos = sum(rel_target_pos, 2);
            rel_target_pos = sqrt(rel_target_pos);
            
            % This was implemented, but not sure why yet
            step_size = this.config_.robot_Type(this.id_, 3);
            rel_target_pos = rel_target_pos / step_size;
            
            % L-Alliance expects a row vector
            rel_target_pos = rel_target_pos';
            
            if(this.config_.lalliance_useDistance == 0)
                rel_target_pos = rel_target_pos.*0;
            end
            this.l_alliance_.UpdateMotivation(rel_target_pos);
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

