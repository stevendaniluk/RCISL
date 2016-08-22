classdef RobotState < handle 
    % ROBOTSTATE - Contains all robot specific state info for one robot
    
    properties
        config_ = [];
        world_state_ = [];
        
        % Robot details
        id_ = [];
        step_size_ = [];
        rot_size_ = [];
        type_ = [];
        robot_properties_ = [];
        
        % Current state variables
        pos_ = [];
        orient_ = [];
        obstacle_pos_ = [];
        target_pos_ = [];
        goal_pos_ = [];
        
        % State matrices
        state_matrix_ = [];
        prev_state_matrix_ = [];
        
        % State variables from the previous iteration
        prev_pos_ = [];
        prev_orient_ = [];
        prev_obstacle_pos_ = [];
        prev_target_pos_ = [];
        
        % Target information
        target_id_ = [];    % [0,num_targets]
        target_type_ = [];  % 1=light, 2=heavy
        target_properties_ = [];
        prev_target_id_ = [];
        prev_target_properties_ = [];
        carrying_target_ = [];
        
        % Action information
        action_id_ = [];
        experience_ = [];
        action_label_ = [];
        effort_ = [];               % Counter for how many times it has moved an item
                
        % Noise/Particle filter related
        noise_sigma_ = [];
        particle_filer_on_ = [];
        particle_filter_ = [];
        belief_task = [0 0];
        belief_self = [0 0 0];
        belief_goal = [0 0];     
    end
    
    methods
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Constructor
        %
        %   INPUTS
        %   id = Robot ID number
        %   world_state = WorldState object
        %   config = Configuration object
 
        function this = RobotState(id, world_state, config)
           this.id_ = id;
           this.config_ = config;
           this.world_state_ = world_state;
       
           % Must initialize appropriately
           this.target_id_ = 0;
           this.prev_target_id_ = 0;
           this.carrying_target_ = false;
           this.effort_ = 0;
           
           this.step_size_ = this.world_state_.robotProperties(this.id_, 4);
           this.rot_size_ = this.world_state_.robotProperties(this.id_, 2);
           
           % Set the robot type
           type = this.world_state_.robotProperties(this.id_, 5);
           if(type == 1)
                this.type_ = 'ss-';
            elseif(type == 2)
                this.type_ = 'wf-';
            elseif(type == 3)
                this.type_ = 'ws-';
            else
                this.type_ = 'sf-';
            end
           
           this.particle_filter_ = [ParticleFilter(); ParticleFilter(); ParticleFilter()];
           this.particle_filer_on_ = config.particle_filer_on;
           this.noise_sigma_ = config.noise_sigma;
        end
        
                
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   saveState
 
        function  saveState(this)
            this.prev_pos_ = this.pos_;
            this.prev_orient_ = this.orient_;
            this.prev_obstacle_pos_ = this.obstacle_pos_;
            this.prev_target_pos_ = this.target_pos_;
            this.prev_state_matrix_ = this.state_matrix_;
            this.prev_target_properties_ = this.target_properties_;            
        end
                
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   update
  
        function update(this)
            % Update our state from the world state
            [robot_pos, robot_orient, obstacle_pos, target_pos, goal_pos, target_properties, robot_properties] = ...
            this.world_state_.GetSnapshot();
            
            % Update the state variables
            this.pos_ = robot_pos;
            this.orient_ = robot_orient;
            this.obstacle_pos_ = obstacle_pos;
            this.target_pos_ = target_pos;
            this.goal_pos_ = goal_pos;
            this.target_properties_ = target_properties;
            this.robot_properties_ = robot_properties;
            
            % Must assign target type and carrying status properly when no 
            % target is given
            if(this.target_id_ == 0)
                this.target_type_ = 0;
                this.carrying_target_ = false;
            else
                % Have to manually choose the target type, should be fixed
                this.target_type_ = this.target_properties_(this.target_id_, 3);
                
                % Set if we are carrying our target
                if (this.target_properties_(this.target_id_, 4) == this.id_)
                    this.carrying_target_ = true;
                    % Also increment the effort counter;
                    this.effort_ = this.effort_ + 1;
                else
                    this.carrying_target_ = false;
                end
            end
                        
           %Apply noise to state if requested
           if(this.noise_sigma_ > 0)
               this.ApplyNoise();
               
               % Apply particle filter to noisy data (if requested)
               if(this.particle_filer_on_)
                   this.ApplyParticleFilter();
               end
               
               % Assign our "beliefs" about the positions of ourself, the 
               % goal, and the targets
               this.belief_self = [this.pos_(this.id_,1:2) this.orient_(this.id_,3)];
               this.belief_goal = this.goal_pos_(1:2);
               if(this.target_id_ > 0)
                   this.belief_task = this.target_pos_(this.target_id_,1:2) ;
               end
            end

            % Calculate our state matrix
            this.state_matrix_ = this.getStateMatrix();
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   ApplyNoise
 
        function ApplyNoise(this)
            
            mu = 0;
            sigma = this.noise_sigma_;
            
            % Add noise to robot position
            sz = size(this.pos_) ;
            this.pos_ = this.pos_ + normrnd(mu,sigma,sz(1),sz(2));
            
            % Add noise to robot orientation
            sz = size(this.orient_(:,1:2)) ;
            this.orient_(:,1:2) = this.orient_(:,1:2) + normrnd(mu,sigma,sz(1),sz(2));
            
            if(this.orient_(3) < 0)
                this.orient_(3) = this.orient_(3) + 2*pi;
            end
            
            % Add noise to obstacle positions
            sz = size(this.obstacle_pos_) ;
            this.obstacle_pos_ = this.obstacle_pos_ + normrnd(mu,sigma,sz(1),sz(2));
            
            % Add noise to target positions
            sz = size(this.target_pos_) ;
            this.target_pos_ = this.target_pos_ + normrnd(mu,sigma,sz(1),sz(2));
            
            % Add noise to goal positions
            sz = size(this.goal_pos_) ;
            this.goal_pos_ = this.goal_pos_ + normrnd(mu,sigma,sz(1),sz(2));    
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   ApplyParticleFilter
        %   

        function ApplyParticleFilter(this)
            taskId = this.target_id_;
            
            %if we have no task, we don't update the filter.
            %This function adjusts our sensor values for certain objects (but
            %not all!)
            %Currently this is
            %   - Position of the closest target
            %   - Orientation of ourself
            %   - the robots position
            %   - the goal position
            %   - the xy position
           
            rPos = this.pos_(this.id_,1:2);
            rOrient = this.orient_(this.id_,3);
            
            tCarriedByMe  =0;
            validMove = 1;
            
            if taskId > 0
                tPos = this.target_properties_(taskId,1:2) ;
                tCarriedBy = this.target_properties_(taskId,4);
                tCarriedBy2 = this.target_properties_(taskId,7);
                rType = this.robot_properties_(this.id_,5);
                tType = this.target_properties_(taskId,3);
                rHasTeammate = this.target_properties_(taskId,4) > 0 ...
                    && this.target_properties_(taskId,7) > 0;
                validMove = 1;
                if(tType == 2) 
                    %if the box is heavy
                    if(rType == 2 || rType == 3) 
                        if(rHasTeammate == 0)
                        %And you are weak, and can't budge it, because you
                        %are alone . . .
                            validMove = 0;
                        end
                    end
                end
                if(tCarriedBy  == this.id_ || tCarriedBy2  == this.id_ )
                    tCarriedByMe = 1;
                else
                    tCarriedByMe = 0;
                end
            else
                
                tPos = [0 0];
            end
            tGoal = this.goal_pos_(1:2);
            
            pfVec = [rPos rOrient; tPos 0; tGoal 0];
            
            targMove = [0 0];
            selfMove = [0 0 0];
            goalMove = [0 0];
            
            pfAction = [selfMove; targMove 0; goalMove 0];

            pfSample = this.GetFilteredValues(pfVec, pfAction, taskId);

            this.pos_(this.id_,1:2) = pfSample(1,1:2);
            this.orient_(this.id_,3) = pfVec(1,3);
            
            if taskId > 0
                this.target_pos_(taskId,1:2) =  pfSample(2,1:2);
            end
            
            this.goal_pos_(1:2) = pfSample(3,1:2);
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   GetFilteredValues

        function values = GetFilteredValues(this, reading, action, taskId)
            sz = size(reading);
            values = [];
            
            numParticles = this.config_.particle_Number;
            pruneThreshold = this.config_.particle_PruneNumber;
            resampleStd = this.config_.particle_ResampleNoiseSTD;
            controlStd =  this.config_.particle_ControlStd;
            sensorStd  = this.config_.particle_SensorStd;
            
            for i=1:sz(1)
                % initalize if new
                if(this.particle_filter_(i).uninitalized == 1)
                    this.particle_filter_(i).Initalize(reading(i,1:2),numParticles,pruneThreshold,resampleStd,controlStd,sensorStd  );  
                % initalize if target changes
                elseif(this.prev_target_id_ ~= taskId && i ==2)
                    this.particle_filter_(i).Initalize(reading(i,1:2),numParticles,pruneThreshold,resampleStd,controlStd,sensorStd  );  
                end
                %update beliefs
                this.particle_filter_(i).UpdateBeliefs(reading(i,1:2),action(i,1:2));
                %resample
                this.particle_filter_(i).Resample();
                values = [values ; this.particle_filter_(i).Sample()];
            end
            
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   getStateVariables
        %   
        %   Returns  a mtrix with the current state variables 
        %
        %   State variables are:
        %     1: Robot position
        %     2: Robot orientation
        %     3: target Type
        %     4: Relative Target Position
        %     5: Relative Goal Position
        %     6: Relative position of closest obstacle (obstacle or wall)
            
        function [state_matrix] = getStateMatrix(this)
            % Robot position
            robot_pos = this.pos_(this.id_, :);
            
            % Robot position
            robot_orient = this.orient_(this.id_, :);
            
            % Realitive distance from robot, to goal point
            rel_goal_dist = this.goal_pos_ - robot_pos;
            
            % Relative distance from robot, to target (must account for the
            % case when no target is assigned)
            if(this.target_id_ == 0)
                % We want to go to the goal when we have not target
                rel_target_pos = rel_goal_dist;
                target_type = zeros(1, 3);
            else
                rel_target_pos = this.target_pos_(this.target_id_,:) - robot_pos;
                % Have to manually choose the target type, should be fixed
                target_type = this.target_type_*ones(1, 3);
            end
            
            % Relative distances from robot to borders
            rel_border_pos_left = -robot_pos(1);
            rel_border_pos_right = this.config_.world_width - robot_pos(1);
            rel_border_pos_bottom = -robot_pos(2);
            rel_border_pos_top = this.config_.world_height - robot_pos(2);
            % Relative distances from robot to all obstacles
            rel_obstacle_pos_x = this.obstacle_pos_(:,1) - robot_pos(1);
            rel_obstacle_pos_y = this.obstacle_pos_(:,2) - robot_pos(2);
            rel_obstacle_angle = atan2(rel_obstacle_pos_y, rel_obstacle_pos_x);
            rel_obstacle_pos_x = rel_obstacle_pos_x - cos(rel_obstacle_angle)*this.config_.obstacle_size;
            rel_obstacle_pos_y = rel_obstacle_pos_y - sin(rel_obstacle_angle)*this.config_.obstacle_size;
            rel_obstacle_pos_l = sqrt(rel_obstacle_pos_x.^2 + rel_obstacle_pos_y.^2);
            % Combine them into an array
            rel_obstacle_pos = [abs(rel_border_pos_left),   rel_border_pos_left,   0; ...
                                abs(rel_border_pos_right),  rel_border_pos_right,  0; ...
                                abs(rel_border_pos_bottom), 0,                     rel_border_pos_bottom; ...
                                abs(rel_border_pos_top),    0,                     rel_border_pos_top; ...
                                rel_obstacle_pos_l,         rel_obstacle_pos_x,    rel_obstacle_pos_y];
            % Find index for the minimum euclidean distance
            [~, index] = min(rel_obstacle_pos(:,1));
            % Take the x and y distances of the closest obstacle
            closest_obstacle_pos = [rel_obstacle_pos(index, 2:3), 0];
            
            % Pack all state variables into one matrix
            state_matrix = [robot_pos;
                            robot_orient;
                            target_type;
                            rel_target_pos;
                            rel_goal_dist;
                            closest_obstacle_pos];
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   getRelTargetPositions
        %   
        %   Returns the relative positions of all targets. Used in
        %   determining the confidence in L-Alliance
        
        function [rel_target_pos] = getRelTargetPositions(this)
            % Relative distance from robot, to target (
            rel_target_pos_x = this.target_pos_(:,1) - this.pos_(this.id_, 1);
            rel_target_pos_y = this.target_pos_(:,2) - this.pos_(this.id_, 2);
            rel_target_pos_z = this.target_pos_(:,3) - this.pos_(this.id_, 3);
            
            rel_target_pos = [rel_target_pos_x, rel_target_pos_y, rel_target_pos_z];
        end
        
    end
    
end

