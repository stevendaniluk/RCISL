classdef IndividualLearning < handle
    % INDIVIDUALLEARNING - Contains learning capabilities for one robot
    
    % The IndividualLearning class is responsible for all the learning
    % functionality for each robot. One instance of IndividualLearning will
    % exist for each robot.
    %
    % The interaction with the Robot class will be through the getAction
    % and learn methods, which will return the "learned" action to be
    % performed, or perform learning from the previous action.
    %
    % The actual learning updates and learning data is contained in a
    % seperate class, since IndividualLearning is intended to be an
    % interface class with Robot, which can be filled out for different
    % learning mechanisms.
    %
    % IndividualLearning also contains the functionality for:
    %       - The policy for selecting actions
    %       - Extracting the state variables from RobotState
    %       - Compressing the state variables to a vector of integers
    
    properties
        config_ = [];                   % Current configuration object
        q_learning_ = [];               % QLearning object
        policy_ = [];                   % The policy being used
        min_utility_threshold_ = [];    % Minimum utility for policy (from config)
        learning_iterations_ = [];      % Counter for how many times learning is performed
    end
    
    methods (Access = public)
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %   Constructor
        %
        %   Loads in configuration data, and instantiates a QLearning
        %   object.
        %
        %   INPUTS
        %   config = Configuration object
        
        function this = IndividualLearning(config)
            this.config_ = config;
            this.policy_ = config.policy;
            this.min_utility_threshold_ = config.min_utility_threshold;
            this.q_learning_ = QLearning(config);
            this.learning_iterations_ = 0;
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %   getAction
        %
        %   Returns the action from the individual learning layer
        %
        %   INPUTS
        %   world_state = Current world state (i.e. world state variables)
        %   robot_state = Current robot state (i.e. robot state variables)
        %
        %   OUTPUTS
        %   action = Action to take
        
        function action_id = getAction(this, robot_state)
            % Get state matrix, and convert to encoded state vector
            state_vector = this.stateMatrixToStateVector(robot_state.state_matrix_);
            
            % Get our quality and experience from state vector
            [quality, robot_state.experience_] = this.q_learning_.getUtility(state_vector);
            
            % Select action with policy
            action_id = this.Policy(quality); 
            
            % Kind of a hack for L-Alliance, if it forces us to drop a task
            % We hack that action into the framework
            robot_state.acquiescence_ = 0;
            if(robot_state.target_id_ ~= robot_state.prev_target_id_ && robot_state.target_id_ == 0)
                %override default action to be "drop box" action.
                action_id = 7; %This is the drop action
                robot_state.acquiescence_ = 1;
            end
            
            % Assign and output the action that was decided
            robot_state.action_id_ = action_id;
        end
                
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %   learn
        %
        %   Updates the utility values, based on the reward
        
        function learn(this, robot_state)
            % Find reward
            reward = this.determineReward(robot_state);
            
            % Get current and previous state vectors for Q-learning
            state_vector = this.stateMatrixToStateVector(robot_state.state_matrix_);
            prev_state_vector = this.stateMatrixToStateVector(robot_state.prev_state_matrix_);
            
            %do one step of QLearning
            this.q_learning_.learn(prev_state_vector, state_vector, robot_state.action_id_, reward);
            
            this.learning_iterations_ = this.learning_iterations_ + 1;
        end
                
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %   resetForNextRun
        %
        %   Resets all the necessary data for performing consecutive runs,
        %   while maintatining learning data
        
        function resetForNextRun(this)
            % Set the matrix of learning data back to zero
            this.q_learning_.resetLearningData();
        end

    end
    
    methods (Access = private)
                
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   stateMatrixToStateVector
        %
        %   Converts a state matrix to an encoded state vector, with all
        %   state variables being represented by a set of n-bit integers,
        %   where n, the number of bits, is dictated in the configuration
        %   file.
        %   
        %   INPUTS:
        %   state_matrix - Matrix of all state variables
        %       Contents of each row are:
        %       1: Robot position
        %       2: Robot orientation
        %       3: target Type
        %       4: Relative Target Position
        %       5: Relative Goal Position
        %       6: Relative position of closest obstacle (obstacle or wall)
        %
        %   OUTPUTS:
        %   state_vector = Vector of encoded state variables
        %       Vector contents: [position, target_type, rel_target, 
        %                         rel_goal, rel_obstacle]
        
        function state_vector = stateMatrixToStateVector(this, state_matrix)
            %   Example of representing two parameters, alpha and beta, using
            %   5 bits is shown below. Since there are 5 bits, the values
            %   for alpha and beta will be divided into 4 equal ranges, with
            %   the resulting code shown below being assigned.
            %
            %    Code     alpha     beta  |   Code     alpha     beta
            %      0        1        1    |     8        3        1
            %      1        1        2    |     9        3        2
            %      2        1        3    |     10       3        3
            %      3        1        4    |     11       3        4
            %      4        2        1    |     12       4        1
            %      5        2        2    |     13       4        2
            %      6        2        3    |     14       4        3
            %      7        2        4    |     15       4        4
            
            % Some parameters which should be loaded from the config file
            
            % Find bits are required to represent state values and action
            bits = this.config_.num_state_bits;
            
            width = this.config_.world_Height;
            height = this.config_.world_Width;
            
            % In case an values are outside the world bounds, they need to
            % be adjusted to be within the bounds by at least this much
            delta = 0.0001;
            
            % Encode robot position
            % Find size of increments for position
            x_range = width/(bits);
            y_range = height/(bits);
            % Extract positions from state matrix
            pos_x = state_matrix(1,1);
            pos_y = state_matrix(1,2);
            % Make sure they are within the world limits
            % (necessary because of noise)
            if (pos_x > width)
                pos_x = width - delta;
            end
            if (pos_y > height)
                pos_y = height - delta;
            end
                        
            % Convert to bits
            pos = bitshift(floor(pos_x/x_range),2) + floor(pos_y/y_range);
            
            % Encode target type
            target_type = state_matrix(3,1);
            
            % Get orientation, will be Z element, in second row
            orient = state_matrix(2, 3);
            
            % Find angles from x and y coords of each state
            angles = atan2(state_matrix(4:end,2), state_matrix(4:end,1));
            % make angles relative to the orientation
            angles = angles + orient;
            % Make sure it is within [0, 2Pi]
            angles = mod(angles, 2*pi);
            
            % Find euclidean distances from target/goal/obstacle
            dist = sqrt(state_matrix(4:end,1).^2 + state_matrix(4:end,2).^2);
            
            % Find relevant ranges for encoding angle and distance
            angle_range = (2*pi)/(bits);
            dist_range = sqrt(width^2 + height^2)/(bits);
            % Make sure distance is within world bounds
            % (necessary because of noise)
            if (dist > dist_range)
                dist = dist_range - delta;
            end
            
            % Convert to bits
            rel_pos = bitshift(floor(angles/angle_range),2) + floor(dist/dist_range);
            
            % Assemble, and correct elements in case an are over the max
            % bit amount (shouldn't happen, but if it does we want to know)
            state_vector = [pos; target_type; rel_pos];
            if (sum(state_vector(state_vector >= bits^2)) ~= 0)
                warning('state_vector values greater than max allowed. Reducing to max value.');
                state_vector(state_vector >= bits^2) = (bits^2 - 1);
            end
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %   determineReward
        %
        %   Returns the reward from the specified action by looking at the
        %   change in the robot_state. To be used when learning is applied.
        %
        %   INPUTS
        %   robot_state = Current RobotState object
        %
        %   OUTPUTS
        %   reward = Value of the reward for the previous action
        
        function reward = determineReward(this, robot_state)
            % Set distance threshold for rewards            
            threshold = this.config_.reward_activation_dist;
            
            % First handle the case where no target is assigned first, since 
            % we cannot calculate target distance if we don't have a target
            
            % Useful values
            goal_pos = robot_state.goal_pos_;
            pos = robot_state.pos_(robot_state.id_, :);
            prev_pos = robot_state.prev_pos_(robot_state.id_, :);
            
            % Check if we've moved closer to goal
            goal_dist = sqrt(sum((pos - goal_pos).^2));
            prev_goal_dist = sqrt(sum((prev_pos - goal_pos).^2));
            delta_goal_dist = goal_dist - prev_goal_dist;
            
            if (robot_state.target_id_ == 0)
                if (delta_goal_dist < -threshold)
                    reward = 1;
                else
                    reward = this.config_.empty_reward_value;
                end
                % Record reward in robot state
                robot_state.reward_ = reward;
                return;
            end
            
            % Now handle the cases where we have a target
            
            % Useful values
            target_id = robot_state.target_id_;
            target_pos = robot_state.target_pos_(target_id,:);
            prev_target_pos = robot_state.target_pos_(target_id,:);
            target_state = robot_state.target_properties_(target_id, 1);
            prev_target_state = robot_state.prev_target_properties_(target_id, 1);
            
            % Calculate change in distance from target item to goal
            current_item_goal_dist = sqrt(sum((target_pos - goal_pos).^2));
            prev_item_goal_dist = sqrt(sum((prev_target_pos - goal_pos).^2));
            delta_item_goal_dist = current_item_goal_dist - prev_item_goal_dist;
            
            % Calculate change in distance from robot to target item
            current_robot_item_dist = sqrt(sum((target_pos - pos).^2));
            prev_robot_item_dist = sqrt(sum((prev_target_pos - prev_pos).^2));
            delta_robot_item_dist = current_robot_item_dist - prev_robot_item_dist;

            if (delta_item_goal_dist < -threshold)
                % Item hs moved closer
                reward = this.config_.item_closer_reward;
            elseif (delta_item_goal_dist > threshold)
                % Items has moved further away
                reward = this.config_.item_further_reward;
            elseif (delta_robot_item_dist < -threshold)
                % Robot moved closer to item
                reward = this.config_.robot_closer_reward;
            elseif (delta_robot_item_dist > threshold)
                % Robot moved further away from item
                reward = this.config_.robot_further_reward;
            elseif (target_state ~= 1 && prev_target_state == 1)
                reward = this.config_.return_reward;
            else
                % When no reward is given, make sure empty rewards are not
                % discouraged due to purtebations in item position
                reward = this.config_.empty_reward_value;
            end
            
            % Record reward in robot state
            robot_state.reward_ = reward;
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %   Policy
        %
        %   Contains the policy for action selection. Can be multiple of
        %   these, with the desired policy being listed in the configuration
        %
        %   INPUTS
        %   utility_vals = Array of utility values for the next actions
        %
        %   OUTPUTS
        %   action_index = The ID (index) of the selected action
        
        function action_index = Policy(this, utility_vals)
            % TODO - Add something to randomize actions more if we have less
            % experience. Was done with
            % utility_vals = (utility)^(experience/some_factor)
            
            % If all utility is lower than randomness threshold, randomize it
            if(sum(utility_vals) < this.config_.min_utility_threshold)
                utility_vals = rand(size(utility_vals)) * this.config_.min_utility_threshold;
            end
            
            % Make all actions with zero quality equal to
            % 0.005*sum(Total Quality), giving it 0.5% probablity to help
            % discover new actions
            total_utility = sum(utility_vals);
            utility_vals(utility_vals == 0) = total_utility.*0.05;
            
            % Use the policy indicated in the configuration 
            if (strcmp(this.policy_, 'greedy'))
                % Simply select the max utility
                [~, action_index] = max(utility_vals);
            elseif (strcmp(this.policy_, 'justins'))
                % Current policy in the simulation from Justin Girard
                total_utility = sum(utility_vals);
                actionSelect = total_utility*rand(); %pick a number
                i = 0;
                action_index =1;
                num = 0;
                while (num < actionSelect)
                    i = i+1;
                    num = num + utility_vals(i);
                    if num > actionSelect
                        action_index = i;
                        break;
                    end
                end
            end
        end
        
    end
    
end

