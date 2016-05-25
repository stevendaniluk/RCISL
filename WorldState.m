classdef WorldState < handle
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % 
    %   WorldState
    %   
    %   World State is in charge of the physical simulation
    %   it maintains the ground truth for the world,
    %   and performs all needed physics simulation

    properties
        
        config_ = [];
        iterations_ = 0;
        
        % World parameters set by Configuration
        world_width_ = [];  % World X size
        world_height_ = []; % World Y size
        world_depth_ = [];  % World Z size
        
        grid_size_ = [];                % Grid sizing for random initial positions
        random_pos_padding_ = [];       % Padding distance between objects when randomizing world state
        random_border_padding_ = [];    % Padding distance between objects and world borders when randomizing world state
        
        num_robots_ = [];               % Number of robots
        num_targets_ = [];              % Number of tagerts
        num_obstacles_ = [];            % Number of obstacles
        
        robot_size_ = [];               %
        robot_mass_ = [];
        
        obstacle_size_ = [];
        obstacle_mass_ = [];
        
        target_size_ = [];
        target_mass_ = [];
        
        goal_size_ = [];
                
        % Current state variables
        % One row for each robot/target/obstacle
        robot_pos_ = [];            % [x, y, z,] positions
        robot_orient_ = [];         % [rx, ry, rz,] angles
        robot_vel_ = [];            % [vx, vy, vz] velocities
        
        obstacle_pos_ = [];         % [x, y, z,] positions
        obstacle_orient_ = [];      % [rx, ry, rz,] angles
        obstacle_vel_ = [];         % [vx, vy, vz] velocities
        
        target_pos_ = [];           % [x, y, z,] positions
        target_orient_ = [];        % [rx, ry, rz,] angles
        target_vel_ = [];           % [vx, vy, vz] velocities
        
        goal_pos_ = [];             % [x, y, z,] positions
        
        % Robot type (ss, sf, ws, wf), one row for each robot
        robot_type_ = [];
        
        % Is this world all 'finished' == 1
        converged_ = 0;
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        % Robot Properties array and indicies 
        robotProperties = [];
        rpid_currentTarget = 1;
        rpid_rotationStep = 2;
        rpid_mass = 3;
        rpid_typeId = 4;
        rpid_reachId = 5;
        
        % Target Properties  array and indicies      
        targetProperties = [];
        tpid_isReturned = 1;
        tpid_weight = 2;
        tpid_type12 = 3;
        tpid_carriedBy = 4;
        tpid_size = 5;
        tpid_lastRobotToCarry = 6;
                
        %types in the world. Not currently used effectively
        TYPE_ROBOT = 2;
        TYPE_TARGET = 3;
        
        ID_CARRIED_BY = 4;
        ID_CARRIED_BY_2 = 7;
        
        % Configures whether or not the boxes may be 
        % 'Picked Up'
        boxPickup = [];
        groupPickup = [];
        
    end
    
    methods

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Constructor
        %   
        %   Loads a configuration, then signs all loaded parameters and
        %   saves all initial parameters
        
        function this = WorldState(config)
            this.config_ = config;
            
            % Load configuration
            this.world_width_ = config.world_width;
            this.world_height_ = config.world_height;
            this.world_depth_ = config.world_depth;
            this.grid_size_ = config.grid_size;
            this.random_pos_padding_ = config.random_pos_padding;
            this.random_border_padding_ = config.random_border_padding;
            this.num_robots_ = config.numRobots;
            this.num_targets_ = config.numTargets;
            this.num_obstacles_ = config.numObstacles;
            this.robot_size_ = config.robot_size;
            this.robot_mass_ = config.robot_mass;
            this.obstacle_size_ = config.obstacle_size;
            this.obstacle_mass_ = config.obstacle_mass;
            this.target_size_ = config.target_size;
            this.target_mass_ = config.target_mass;
            this.goal_size_ = config.goal_size;
            
            % Assign all robot and target properties
            this.assignProperties();
                                 
            % Randomize the positions and orientatons for all objects
            this.randomizeState();
            
            % set the realism level accordingly
            % at the first realism level, we let the boxes be 'picked up'
            % by a robot. At later sim levels this is not the case.
            if(config.simulation_Realism == 0)
                this.boxPickup = 1;
            else
                this.boxPickup =0;
            end
            if(config.simulation_Realism == 2)
                this.groupPickup = 1;
            else
                this.groupPickup =0;
            end 
        end
                
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   assignProperties
        %   
        %   Assigns all robot and target properties according to the arrays
        %   formed in the configuration
        
        function assignProperties (this)
            % Form robot properties array
            this.robotProperties = [zeros(this.num_robots_, 1), ...
                ones(this.num_robots_, 1)*0.5, ...
                ones(this.num_robots_, 1), ...
                ones(this.num_robots_, 2), ...
                ones(this.num_robots_, 1)*this.config_.robot_Reach, ...
                zeros(this.num_robots_, 1)];
            
            % Form target properties array
            this.targetProperties = [zeros(this.num_targets_, 1), ...
                0.5*ones(this.num_targets_, 1), ...
                ones(this.num_targets_, 1), ...
                zeros(this.num_targets_, 1), ...
                ones(this.num_targets_, 1)*0.5, ...
                zeros(this.num_targets_, 1), ...
                zeros(this.num_targets_, 1)];
            
            % Get how many types of robots have been defined
            robotTypes = this.config_.robot_Type;
            [num_robot_types, ~] = size(robotTypes);
            
            properties_indices = [this.rpid_rotationStep this.rpid_mass ...
                this.rpid_typeId this.rpid_reachId ];
            
            % Loop through each robot and assign properties
            for i=1:this.num_robots_
                % Loop back to first type, if there aren't enough defined
                type_index = mod((i - 1), num_robot_types) + 1;

                this.robotProperties(i, properties_indices) = robotTypes(type_index, :);
            end
            
            % Get how many types of targets have been defined
            targetTypes = this.config_.target_Type;
            [num_target_types, ~] = size(targetTypes);
            
            % Loop through each target and assign properties
            for i=1:this.num_targets_
                % Loop back to first type, if there aren't enough defined
                type_index = mod((i - 1), num_target_types) + 1;

                this.targetProperties(i, this.tpid_size) = targetTypes(type_index, 1);      % Size
                this.targetProperties(i, this.tpid_weight) = targetTypes(type_index, 2);    % Weight
                this.targetProperties(i, this.tpid_type12) = targetTypes(type_index, 3);    % Type
            end
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   randomizeState
        %   
        %   Begin to form random positions by discritizing the world,
        %   getting all the unique positions, then selecting enough
        %   positions that are valid, and do not violate the random
        %   position padding dictated in the configuration

        function randomizeState(this)
            % Must initialize velocity, since it is not randomly set
            this.obstacle_vel_ = zeros(this.num_obstacles_, 3);
            this.robot_vel_ = zeros(this.num_robots_, 3);
            this.target_vel_ = zeros(this.num_targets_, 3);
            
            % Total potential positions
            num_x_pos = (this.world_width_ - 2*this.random_border_padding_)/this.grid_size_ - 1;
            num_y_pos = (this.world_height_ - 2*this.random_border_padding_)/this.grid_size_ - 1;
            
            % Vectors of each potential positions in each direction
            x_grid = linspace(this.random_border_padding_, (this.world_width_ - this.random_border_padding_), num_x_pos);
            y_grid = linspace(this.random_border_padding_, (this.world_height_ - this.random_border_padding_), num_y_pos);
            
            % Total amount of valid positions we need
            num_positions = this.num_robots_ + this.num_targets_ + this.num_obstacles_ + 1;
            
            % Form empty arrays
            positions = zeros(num_x_pos * num_y_pos, 3);
            valid_positions = zeros(num_positions, 3);
            
            % Put all potential position combinations in an ordered array
            for i=1:num_x_pos
                for j=1:num_y_pos
                    positions((i-1)*num_y_pos + j, 1) = x_grid(i);
                    positions((i-1)*num_y_pos + j, 2) = y_grid(j);
                end
            end
            
            valid_positions_found = false;
            
            while (~valid_positions_found)
                % Take random permutations of positions in each direction
                random_positions = positions(randperm(num_x_pos * num_y_pos), :);
                
                % Loop through assigning random positions, while checking if any new random
                % positions conflict with old ones.
                index = 1;
                valid_positions(index,:) = random_positions(index,:);
                
                for i=1:num_positions
                    % If we've checked all positions, break and generate
                    % new ones
                    if (index > num_x_pos*num_y_pos)
                        break;
                    end
                    
                    % Loop through random positions until one is valid                                        
                    position_valid = false;
                    while(~position_valid)
                        % Separation distance
                        x_delta_dist = abs(valid_positions(1:i, 1) - random_positions(index, 1));
                        y_delta_dist = abs(valid_positions(1:i, 2) - random_positions(index, 2));
                        % Check the violations
                        x_violations = x_delta_dist < this.random_pos_padding_;
                        y_violations = y_delta_dist < this.random_pos_padding_;
                        % Get instances where there are x and y violations
                        violations = x_violations.*y_violations;
                        
                        if (sum(violations) == 0)
                            position_valid = true;
                            % Save our valid position
                            valid_positions(i,:) = random_positions(index, :);
                        end
                        
                        index = index + 1;
                        % If we've checked all positions, break and generate
                        % new ones
                        if (index > num_x_pos*num_y_pos)
                            break;
                        end
                    end
                    % If we've checked all positions, break and generate
                    % new ones
                    if (index > num_x_pos*num_y_pos)
                        break;
                    end
                end
                
                % Only finish if we have enough positions, and haven't
                % surpassed the index
                if ((i == num_positions) && (index <= num_x_pos*num_y_pos))
                    valid_positions_found = true;
                end
            end            
            
            % Assign the random positions to robots, targets, obstacles, 
            % and the goal, as well as random orientations                  
            index = 1;
            this.robot_pos_ = valid_positions(index:(index + this.num_robots_ - 1), :);
            this.robot_orient_ = [zeros(this.num_robots_, 2), rand(this.num_robots_, 1)*2*pi];
            
            index = index + this.num_robots_;
            this.target_pos_ = valid_positions(index:(index + this.num_targets_ - 1), :);
            this.target_orient_ = [zeros(this.num_targets_, 2) rand(this.num_targets_, 1)*2*pi];
            
            index = index + this.num_targets_;
            this.obstacle_pos_ = valid_positions(index:(index + this.num_obstacles_ - 1), :);
            this.obstacle_orient_ = [zeros(this.num_obstacles_, 2) rand(this.num_obstacles_, 1)*2*pi];
            
            index = index + this.num_obstacles_;
            this.goal_pos_ = valid_positions(index, :);
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   SetRobotAdvisor
        %   
        %   For advice exchange (not used yet) 

        function SetRobotAdvisor(this,robotId,advisorId)
            this.robotProperties(robotId,7) = advisorId;
        end
                
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   GetConvergence
        %   
        %   Check if all the items have been returned to the goal area
 
        function conv = GetConvergence(this)
            num_returned = sum(this.targetProperties(:,this.tpid_isReturned));
            
            if num_returned == this.num_targets_
                this.converged_ = true;
            else
                this.converged_ = false;
            end
            conv = this.converged_;
        end       
                                
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   UpdateRobotTarget
        %   
        %   set the RobotId of a certain target to be
        %   equal to id.
  
        function UpdateRobotTarget(this,id,targetId)
            this.robotProperties(id,1) = targetId;
            if(targetId > 0 )
                assigned = this.robotProperties(:,1) == targetId;
                totalOnTask = sum(assigned);
                if(totalOnTask >2)
                    disp('Too many robots on a task!');
                    %rolled back gracefully
                    this.robotProperties(id,1) = 0;
                else
                    this.targetProperties(targetId,this.tpid_lastRobotToCarry) = id;
                end
            end
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   GetSnapshot
        %   
        %   Get a copy of the entire world.
  
        function [robot_pos, robot_orient,obstacle_pos, target_pos, goal_pos, target_properties, robot_properties ] ...
                = GetSnapshot(this)
            robot_pos = this.robot_pos_;
            robot_orient = this.robot_orient_;
            obstacle_pos = this.obstacle_pos_;
            target_pos = this.target_pos_;
            goal_pos = this.goal_pos_;
            target_properties = this.targetProperties;
            robot_properties = this.robotProperties;
        end
        
    end
    
end

