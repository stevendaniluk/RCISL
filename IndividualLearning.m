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
        robot_id_ = [];                 % Id number for owner robot
        q_learning_ = [];               % QLearning object
        state_vector_ = [];             % Current state vector
        policy_ = [];                   % The policy being used
        epoch_iterations_ = [];         % Counter for iterations in each epoch
        learning_iterations_ = [];      % Counter for how many times learning is performed
        prev_learning_iterations_ = []; % For tracking iterations between epochs
        random_actions_ = [];           % Counter for number of random actions
        learned_actions_ = [];          % Counter for number of learned actions
        softmax_temp_ = [];             % Temperature for policy softmax distribution
        advised_actions_ = [];          % Counter for number of advised actions
        state_resolution_ = [];               % Bits in state_vector
        look_ahead_dist_ = [];          % Distance robot looks ahead for obstacle state info
        reward_data_ = [];              % For tracking reward at each iteration
        state_q_data_ = [];             % For tracking Q values at each step
        
        advice_on_ = [];
        advice_ = [];               % Advice mechanism between robots
        greedy_override_ = [];
        
    end
    
    events
        PerfMetrics;
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
        
        function this = IndividualLearning(config, id)
            this.config_ = config;
            this.robot_id_ = id;
            this.epoch_iterations_ = 0;
            this.learning_iterations_ = 0;
            this.prev_learning_iterations_ = 0;
            this.random_actions_ = 0;
            this.advised_actions_ = 0;
            this.policy_ = config.policy;
            this.softmax_temp_ = config.softmax_temp;
            this.state_resolution_ = config.state_resolution;
            this.look_ahead_dist_ = config.look_ahead_dist;
            
            % Initialize Q-learning
            this.q_learning_ = QLearning(config.gamma, config.alpha_denom, ...
                                config.alpha_power, config.alpha_max, ...
                                config.num_state_vrbls, config.state_resolution, ...
                                config.num_actions);
            
            % Form structure for tracking Q values
            % Need to know the values, and if a +ve reward was received
            this.state_q_data_.q_vals = [];
            this.state_q_data_.state_vector = [];
            this.state_q_data_.action = [];
            this.state_q_data_.reward = [];
            this.state_q_data_.delta_q = [];
            this.state_q_data_.delta_h = [];
            
            this.advice_on_ = config.advice_on;
            if (this.advice_on_)
                this.advice_ = Advice(config, id);
                this.greedy_override_ = config.greedy_override;
            end
            
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %   getAction
        %
        %   Returns the action from the individual learning layer
        %
        %   INPUTS
        %   robot_state = Current robot state (i.e. robot state variables)
        %
        %   OUTPUTS
        %   action = Action to take
        
        function action_id = getAction(this, robot_state)
            this.epoch_iterations_ = this.epoch_iterations_ + 1;
            
            % Get state matrix, and convert to encoded state vector
            this.state_vector_ = this.stateMatrixToStateVector(robot_state.state_matrix_);
            
            % Get our quality and experience from state vector
            [quality, ~] = this.q_learning_.getUtility(this.state_vector_);
            
            % Get advised action (if necessary)
            if (this.advice_on_)
                % Get advice from advisor (overwrite quality and experience)
                [quality] = this.advice_.getAdvice(this.state_vector_, quality);
                
                % Select action with policy (including greedy override)
                action_id = this.Policy(quality, this.greedy_override_);
                
                this.advised_actions_ = this.advised_actions_ + 1;
            else
                % Select action with our policy (no greedy override)
                greedy_override = false;
                action_id = this.Policy(quality, greedy_override);
            end
                        
            % Notify AdviceDatabase listener of quality update
            this.notify('PerfMetrics', PerfMetricsEventData('quality', this.robot_id_, quality(action_id), this.epoch_iterations_));
            
            % Assign and output the action that was decided
            robot_state.action_id_ = action_id;
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %   learn
        %
        %   Updates the utility values, based on the reward
        
        function learn(this, robot_state)
            this.learning_iterations_ = this.learning_iterations_ + 1;
            
            % Find reward, and store it as well
            reward = this.determineReward(robot_state);
            this.reward_data_(this.learning_iterations_, 1) = reward;
            
            % Get previous state vector for Q-learning
            prev_state_vector = this.stateMatrixToStateVector(robot_state.prev_state_matrix_);
            [prev_quality, ~] = this.q_learning_.getUtility(prev_state_vector);
            
            % Do one step of QLearning
            this.q_learning_.learn(prev_state_vector, this.state_vector_, robot_state.action_id_, reward);
            
            % Save q values and reward
            this.state_q_data_.q_vals(size(this.state_q_data_.q_vals, 1) + 1, :) = prev_quality';
            this.state_q_data_.state_vector(size(this.state_q_data_.state_vector, 1) + 1, :) = prev_state_vector;
            this.state_q_data_.action(size(this.state_q_data_.action, 1) + 1, :) = robot_state.action_id_;
            this.state_q_data_.reward(size(this.state_q_data_.reward, 1) + 1, 1) = reward;
            
            % Notify AdviceDatabase listener of change in quality
            [new_quality, ~] = this.q_learning_.getUtility(prev_state_vector);
            delta_q = new_quality(robot_state.action_id_) - prev_quality(robot_state.action_id_);
            this.state_q_data_.delta_q(size(this.state_q_data_.delta_q, 1) + 1, 1) = delta_q;
            this.notify('PerfMetrics', PerfMetricsEventData('delta_q', this.robot_id_, delta_q, this.learning_iterations_));
            
            % Notify AdviceDatabase listener of change in entropy
            q_exponents = exp(prev_quality/this.softmax_temp_);
            q_prob = q_exponents./sum(q_exponents);
            old_h = sum(-q_prob.*log2(q_prob));
            q_exponents = exp(new_quality/this.softmax_temp_);
            q_prob = q_exponents./sum(q_exponents);
            new_h = sum(-q_prob.*log2(q_prob));
            
            delta_h = new_h - old_h;
            this.state_q_data_.delta_h(size(this.state_q_data_.delta_h, 1) + 1, 1) = delta_h;
            this.notify('PerfMetrics', PerfMetricsEventData('delta_h', this.robot_id_, delta_h, this.learning_iterations_));
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %   resetForNextRun
        %
        %   Resets all the necessary data for performing consecutive runs,
        %   while maintatining learning data
        
        function resetForNextRun(this)
            this.prev_learning_iterations_ = this.learning_iterations_;
            this.epoch_iterations_ = 0;
        end
        
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
                                
            % In case an values are outside the world bounds, they need to
            % be adjusted to be within the bounds by at least this much
            delta = 0.0001;
            
            % Get orientation, will be Z element, in second row
            orient = state_matrix(2, 3);
            orient = mod(orient, 2*pi);
            
            % Encode target type
            target_type = state_matrix(3,1);
            
            % Find euclidean distances from target/goal/obstacle, make sure
            % it is within the look ahead distance, then convert to the
            % proper state resolution
            target_dist = sqrt(state_matrix(4, 1).^2 + state_matrix(4, 2).^2);
            target_dist = min(target_dist, this.look_ahead_dist_ - delta);
            target_dist = floor((target_dist/this.look_ahead_dist_)*this.state_resolution_(2));
            
            goal_dist = sqrt(state_matrix(5, 1).^2 + state_matrix(5, 2).^2);
            goal_dist = min(goal_dist, this.look_ahead_dist_ - delta);
            goal_dist = floor((goal_dist/this.look_ahead_dist_)*this.state_resolution_(4));
            
            obst_dist = sqrt(state_matrix(6, 1).^2 + state_matrix(6, 2).^2);
            obst_dist = min(obst_dist, this.look_ahead_dist_ - delta);
            obst_dist = floor((obst_dist/this.look_ahead_dist_)*this.state_resolution_(6));            
            
            % Get relative angles of targets/goal/obstacles, offset by half
            % of resolution (so that straight forward is the centre of a
            % quadrant), then convert to the proper state resolution
            target_angle = atan2(state_matrix(4, 2), state_matrix(4, 1)) - orient;
            target_angle = mod((target_angle + 2*pi/this.state_resolution_(3)), 2*pi);
            target_angle = floor(target_angle*this.state_resolution_(3)/(2*pi));
            
            goal_angle = atan2(state_matrix(5, 2), state_matrix(5, 1)) - orient;
            goal_angle = mod((goal_angle + 2*pi/this.state_resolution_(5)), 2*pi);
            goal_angle = floor(goal_angle*this.state_resolution_(5)/(2*pi));
            
            obst_angle = atan2(state_matrix(6, 2), state_matrix(6, 1)) - orient;
            obst_angle = mod((obst_angle + 2*pi/this.state_resolution_(7)), 2*pi);
            obst_angle = floor(obst_angle*this.state_resolution_(7)/(2*pi));
            
            % Assemble, and correct elements in case an are over the max
            % bit amount (shouldn't happen, but if it does we want to know)
            state_vector = [target_type; 
                            target_dist;
                            target_angle;
                            goal_dist;
                            goal_angle;
                            obst_dist;
                            obst_angle]';            
            if (sum(state_vector >= this.state_resolution_) ~= 0)
                warning(['state_vector values greater than max allowed. Reducing to max value. State Vector: ', ...
                         sprintf('%d, %d, %d, %d, %d %d, %d\n', state_vector(1), state_vector(2), state_vector(3), state_vector(4), state_vector(5), state_vector(6), state_vector(7))]);
                state_vector = mod(state_vector, this.state_resolution_');
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
                return;
            end
            
            % Now handle the cases where we have a target
            
            % Useful values
            target_id = robot_state.target_id_;
            target_pos = robot_state.target_pos_(target_id,:);
            prev_target_pos = robot_state.prev_target_pos_(target_id,:);
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
            
            % Rewards depend on if we are going to an item, or carrying one
            if (robot_state.carrying_target_ && delta_item_goal_dist < -threshold)
                % Item has moved closer
                reward = this.config_.item_closer_reward;
            elseif (robot_state.carrying_target_ && delta_item_goal_dist > threshold)
                % Item has moved further away
                reward = this.config_.item_further_reward;
            elseif (~robot_state.carrying_target_ && delta_robot_item_dist < -threshold)
                % Robot moved closer to item
                reward = this.config_.robot_closer_reward;
            elseif (~robot_state.carrying_target_ && delta_robot_item_dist > threshold)
                % Robot moved further away from item
                reward = this.config_.robot_further_reward;
            elseif (target_state ~= 1 && prev_target_state == 1)
                reward = this.config_.return_reward;
            else
                % When no reward is given, make sure empty rewards are not
                % discouraged due to purtebations in item position
                reward = this.config_.empty_reward_value;
            end
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
        %   experience = Array of experience values for the next actions
        %
        %   OUTPUTS
        %   action_index = The ID (index) of the selected action
        
        function action_index = Policy(this, utility_vals, greedy_override)
            % If all utility is zero, select a random action
            if(sum(utility_vals) == 0)
                action_index = ceil(rand*this.config_.num_actions);
                this.random_actions_ = this.random_actions_ + 1;
                return;
            end
            
            % Make all actions with zero quality equal to
            % 0.005*sum(Total Quality), giving it 0.5% probablity to help
            % discover new actions
            total_utility = sum(utility_vals);
            utility_vals(utility_vals == 0) = total_utility.*0.05;
            
            % Use the policy indicated in the configuration
            if (strcmp(this.policy_, 'greedy') || greedy_override)
                % Simply select the max utility
                [~, action_index] = max(utility_vals);
            elseif (strcmp(this.policy_, 'e-greedy'))
                % Epsilon-Greedy Policy
                rand_action = rand;
                if (rand_action <= this.config_.e_greedy_epsilon)
                    action_index = ceil(rand*this.config_.num_actions);
                else
                    [~, action_index] = max(utility_vals);
                end
            elseif (strcmp(this.policy_, 'softmax'))
                % Softmax action selection [Girard, 2015]
                exponents = exp(utility_vals/this.softmax_temp_);
                action_prob = exponents/sum(exponents);
                rand_action = rand;
                for i=1:this.config_.num_actions
                    if (rand_action < sum(action_prob(1:i)))
                        action_index = i;
                        break;
                    elseif (i == this.config_.num_actions)
                        action_index = i;
                    end
                end
            else
                error(['No policy matching ', this.policy_, ...
                    '. Options are "greedy", "e-greedy", or "softmax"']);
            end
            
        end
        
    end
    
end


