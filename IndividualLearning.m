classdef IndividualLearning < handle
  % INDIVIDUALLEARNING - Contains learning capabilities for one robot
  
  % The IndividualLearning class is responsible for all the learning
  % functionality for each robot. One instance of IndividualLearning will
  % exist for each robot.
  %
  % The robot's policy is developed through a Q-Learning algorithm.
  %
  % The interaction with the Robot class will be through the getAction,
  % postActionUpdate, and learn methods.
  %
  % IndividualLearning also contains the functionality for:
  %       - The policy method for selecting actions
  %       - Extracting the state variables from RobotState and WorldState
  %       - Determining the reward for the robot's actions
  
  properties
    config_;             % Current configuration object
    id_;                 % Id number for owner robot
    q_learning_;         % Q-Learning object
    advice_;             % Advice mechanism object
    learning_enabled_;   % Flag for if learning should be updated
    action_;             % Action index selected
    state_vector_;       % Current state vector
    prev_state_vector_;  % Previous state vector
    reward_data_;        % Struct of data for calculation reward
    %   robot_goal_dist - Distance moved for longitudinal movements
    %   robot_target_dist - Angle rotated for rotational movements
    %   target_goal_dist - Flag for if the robot is strong
    %   target_id - Distance a robot can grab a target from
    prev_reward_data_;   % Struct of data for calculation reward, from previous iteration
    %   Same fields as reward_data_
    epoch_reward_;       % Counter for total reward this epoch
    state_data_;         % Struct for storing state data at each iteration
    %   state_vector - Discritized vector for current state
    %   utility - Utility values for each action
    %   reward - Reward received from the action
    %   action - Selected action
    %   learning_rate - Q-Learning learning rate
    %   experience - Maximum experience in the state
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
    
    function this = IndividualLearning(id, config, world_state, robot_state)
      this.config_ = config;
      this.id_ = id;
      
      % No learning when this robot is an expert
      if (this.config_.IL.expert_on && sum(this.id_ == this.config_.IL.expert_id) ~= 0)
        this.learning_enabled_ = false;
      else
        this.learning_enabled_ = this.config_.IL.enabled;
      end
      
      % Initialize Q-learning
      this.q_learning_ = QLearning(this.config_.IL.QL.gamma, this.config_.IL.QL.alpha_max, this.config_.IL.QL.alpha_rate, ...
        this.config_.IL.state_resolution, this.config_.IL.num_actions);
      
      this.epoch_reward_ = 0;
      
      % Load expert (if necessary)
      % Looks within the "expert_data" directory in the folder name
      % specified for Q-table and experience table data
      if (this.config_.IL.expert_on)
        index = find(this.id_ == this.config_.IL.expert_id);
        if (~isempty(index) && this.id_ == this.config_.IL.expert_id(index))
          filename = this.config_.IL.expert_filename(index);
          try
            load(['expert_data/', filename{1}, '/q_table.mat']);
            load(['expert_data/', filename{1}, '/exp_table.mat']);
            
            table_size = prod(this.config_.IL.state_resolution)*this.config_.IL.num_actions;
            if(table_size ~= length(q_table) || table_size ~= length(exp_table))
              warning('When loading expert data the Configuration and loaded table sizes do not match');
            end
            
            this.q_learning_.q_table_ = q_table;
            this.q_learning_.exp_table_ = exp_table;
          catch
            warning('Expert data file does not exist for agent %d', this.id_);
          end
        end
      end
      
      % Initialize reward data
      % (Only need to initialize robot_goal_dist and target_id, as
      % they are the only fields that can be used for the reward
      % calculation after the first iteration)
      robot_goal_dist.x = robot_state.goal_.x - robot_state.pose_.x;
      robot_goal_dist.y = robot_state.goal_.y - robot_state.pose_.y;
      this.reward_data_.robot_goal_dist = sqrt(robot_goal_dist.x^2 + robot_goal_dist.x^2);
      this.reward_data_.target_id = -1;
      
      % Initialize the state vector
      this.state_vector_ = this.getStateVector(robot_state, world_state);
      
      % Initialize structure for recording state data
      if(this.config_.sim.save_IL_data)
        this.state_data_.q_vals = [];
        this.state_data_.state_vector = [];
        this.state_data_.action = [];
        this.state_data_.reward = [];
        this.state_data_.learning_rate = [];
        this.state_data_.experience = [];
      end
      
      % Instantiate advice (if needed)
      if (this.config_.advice.enabled)
        if(strcmp(this.config_.advice.mechanism, 'advice_enhancement'))
          this.advice_ = AdviceEnhancement(this.config_, this.id_);
        elseif(strcmp(this.config_.advice.mechanism, 'advice_exchange'))
          this.advice_ = AdviceExchange(this.config_, this.id_);
        end
      end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %   getAction
    %
    %   Returns the action from the individual learning layer
    %
    %   OUTPUTS
    %   action_id = Id number of action to perform
    
    function action_id = getAction(this)
      % Get our quality and experience from state vector
      [quality, experience] = this.q_learning_.getUtility(this.state_vector_);
      alpha = this.q_learning_.calcLearningRate(mean(experience));
      
      % Save the state data
      if(this.config_.sim.save_IL_data)
        this.state_data_.q_vals(size(this.state_data_.q_vals, 1) + 1, :) = quality';
        this.state_data_.learning_rate(size(this.state_data_.learning_rate, 1) + 1, :) = alpha;
        this.state_data_.experience(size(this.state_data_.experience, 1) + 1, :) = max(experience);
      end
      
      % Default to our own policy
      [action_id, ~] = this.Policy(quality, experience);
      
      % Get advised action (if necessary)
      if (this.config_.advice.enabled)
        % Get advice from advisor (overwrite quality and experience)
        result = this.advice_.getAdvice(this.state_vector_, quality, experience);
        
        if length(result) ~= 1
          % Advice has returned Q values
          % Select action with policy (including greedy override)
          [action_id, ~] = this.Policy(quality, experience);
        else
          % Advice has returned an action id
          action_id = result;
        end
      end
      this.action_ = action_id;
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %   postActionUpdate
    %
    %   Updates the state vector, so that the learning update can use
    %   the previous state, the performed action, and the resulting
    %   state.
    %
    %   INPUTS
    %   robot_state = RobotState object
    %   world_state = WorldState object
    
    function postActionUpdate(this, robot_state, world_state)
      this.prev_state_vector_ = this.state_vector_;
      this.state_vector_ = this.getStateVector(robot_state, world_state);
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %   learn
    %
    %   Updates the utility values, based on the reward
    
    function learn(this, world_state, robot_state, properties)
      % Find reward, and store it as well
      reward = this.determineReward(world_state, robot_state, properties);
      this.epoch_reward_ = this.epoch_reward_ + reward;
      
      % Do one step of QLearning
      if (this.learning_enabled_)
        this.q_learning_.learn(this.prev_state_vector_, this.state_vector_, this.action_, reward);
      end
      
      % Save the state data
      if(this.config_.sim.save_IL_data)
        this.state_data_.state_vector(size(this.state_data_.state_vector, 1) + 1, :) = this.prev_state_vector_;
        this.state_data_.action(size(this.state_data_.action, 1) + 1, :) = this.action_;
        this.state_data_.reward(size(this.state_data_.reward, 1) + 1, 1) = reward;
      end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %   getStateVector
    %
    %   Converts the current robot_state to a discritized state vector.
    %   The resulting state vector elements are :
    %     1) Relative goal distance
    %     2) Relatve goal angle
    %     3) Target type
    %     4) Relative target distance
    %     5) Relatve target angle
    %     6) Relative closest obstacle distance
    %     7) Relatve closest obstacle angle
    %
    %   All quantities are discritized into integers within their
    %   allowable ranges, determined by IL.state_resolution parameter
    %   from the configuration.
    %
    %   All distances are limited to within the distance from the
    %   IL.look_ahead_dist parameter. All relative angles are divided
    %   into quadrants, with one quadrant being centred forward from
    %   the robot.
    %
    %   Reward distance measures are also updated here, since many of
    %   the required values are already calculated.
    %
    %   INPUTS
    %   robot_state = RobotState object
    %   world_state = WorldState object
    %
    %   OUTPUTS
    %   state_vector = Vector of discritied state values
    
    function state_vector = getStateVector(this, robot_state, world_state)
      % Save the old reward data
      this.prev_reward_data_ = this.reward_data_;
      
      state_res = this.config_.IL.state_resolution;
      max_dist = this.config_.IL.look_ahead_dist;
      
      state_vector = zeros(length(state_res), 1);
      
      % When values are outside the world bounds, they need to be
      % adjusted to be atleast within the bounds for discritization
      delta = 0.0001;
      
      % Relative goal distance and orientation
      rel_goal.x = robot_state.goal_.x - robot_state.pose_.x;
      rel_goal.y = robot_state.goal_.y - robot_state.pose_.y;
      
      rel_goal.d = sqrt(rel_goal.x^2 + rel_goal.y^2);
      state_vector(1) = floor((min(rel_goal.d, max_dist - delta)/max_dist)*state_res(1));
      
      rel_goal.theta = atan2(rel_goal.y, rel_goal.x) - robot_state.pose_.theta;
      rel_goal.theta = mod((rel_goal.theta + pi/state_res(2)), 2*pi);
      state_vector(2) = floor(rel_goal.theta*state_res(2)/(2*pi));
      
      % Save the goal distance for reward calculations
      this.reward_data_.robot_goal_dist = rel_goal.d;
      
      % Target type, and relative distance and orientation
      if(robot_state.target_.id == -1)
        % No target assigned, default to goal position
        state_vector(3) = 0;
        state_vector(4) = state_vector(1);
        state_vector(5) = state_vector(2);
        
        % Save the target distances for reward calculations
        this.reward_data_.target_goal_dist = 0;
        this.reward_data_.robot_target_dist = 0;
      else
        % Set the target type
        if(strcmp(world_state.targets_(robot_state.target_.id).type, 'light'))
          % Light item
          state_vector(3) = 1;
        elseif(strcmp(world_state.targets_(robot_state.target_.id).type, 'heavy'))
          % Heavy item
          state_vector(3) = 2;
        else
          warning('Invalid target type. Setting state vector as "No Target".');
        end
        
        rel_target.x = robot_state.target_.x - robot_state.pose_.x;
        rel_target.y = robot_state.target_.y - robot_state.pose_.y;
        
        rel_target.d = sqrt(rel_target.x^2 + rel_target.y^2);
        state_vector(4) = floor((min(rel_target.d, max_dist - delta)/max_dist)*state_res(4));
        
        rel_target.theta = atan2(rel_target.y, rel_target.x) - robot_state.pose_.theta;
        rel_target.theta = mod((rel_target.theta + pi/state_res(5)), 2*pi);
        state_vector(5) = floor(rel_target.theta*state_res(5)/(2*pi));
        
        % Save the target distances for reward calculations
        this.reward_data_.target_goal_dist = sqrt((robot_state.goal_.x - robot_state.target_.x)^2 + (robot_state.goal_.y - robot_state.target_.y)^2);
        this.reward_data_.robot_target_dist = rel_target.d;
      end
      
      % Save the target id for reward calculations
      this.reward_data_.target_id = robot_state.target_.id;
      
      % Scan detection rays
      ray_ranges = max_dist*ones(this.config_.IL.num_obstacle_rays, 1);
      max_ray_angle = ((this.config_.IL.num_obstacle_rays - 1)/2)*this.config_.IL.obstacle_ray_angle;
      for i = 1:this.config_.IL.num_obstacle_rays
        hit = false;
        terrain = false;
        
        rel_ray_angle = max_ray_angle - (i - 1)*this.config_.IL.obstacle_ray_angle;
        ray_angle = robot_state.pose_.theta + rel_ray_angle;
        ray_angle = mod(ray_angle, 2*pi);
        
        % Use circle intersection method for obstacles and terrain
        % Express ray as a line y = mx + b
        slope = tan(ray_angle);
        intercept = robot_state.pose_.y - slope*robot_state.pose_.x;
        for j = 1:this.config_.scenario.num_obstacles
          % Check if ray can even reach the obstacle to potentially
          % skip the expensive linecirc call
          min_dx = robot_state.pose_.x - robot_state.obstacles_(j).x;
          min_dy = robot_state.pose_.y - robot_state.obstacles_(j).y;
          min_d = sqrt(min_dx^2 + min_dy^2) - 0.5*this.config_.scenario.obstacle_size;
          if(min_d > max_dist)
            continue;
          end
          
          % Matlab's circle intersection returns pts for each intersection
          [hit_x, hit_y] = linecirc(slope, intercept, robot_state.obstacles_(j).x, robot_state.obstacles_(j).y, 0.5*this.config_.scenario.obstacle_size);
          if(sum(isnan(hit_x)) == 0 && sum(isnan(hit_y)) == 0)
            % Intersections have to be in the right direction (line is
            % treated as infinite)
            rel_x = hit_x - robot_state.pose_.x;
            rel_y = hit_y - robot_state.pose_.y;
            for k = 1:length(rel_x)
              if(sign(rel_x(k)) == sign(cos(ray_angle)))
                d = sqrt(rel_x(k)^2 + rel_y(k)^2);
                if(d < ray_ranges(i))
                  ray_ranges(i) = d;
                  hit = true;
                end
              end
            end
          end
        end
        
        if(this.config_.scenario.terrain_on)
          RO_x = robot_state.terrain_.x - robot_state.pose_.x;
          RO_y = robot_state.terrain_.y - robot_state.pose_.y;
          
          % When inside circle, range is zero
          if(sqrt(RO_x^2 + RO_y^2) <= 0.5*this.config_.scenario.terrain_size)
            ray_ranges(i) = 0;
            hit = true;
            terrain = true;
          else
            % Check dot product between Robot-Terrain and Robot-Ray vectors
            % to potentially skip the expensive linecirc call
            RR_x = max_dist*cos(ray_angle);
            RR_y = max_dist*sin(ray_angle);
            if((RO_x*RR_x + RO_y*RR_y) < 0)
              continue;
            end
            
            % Matlab's circle intersection returns pts for each intersection
            [hit_x, hit_y] = linecirc(slope, intercept, robot_state.terrain_.x, robot_state.terrain_.y, 0.5*this.config_.scenario.terrain_size);
            if(sum(isnan(hit_x)) == 0 && sum(isnan(hit_y)) == 0)
              % Intersections have to be in the right direction (line is
              % treated as infinite)
              rel_x = hit_x - robot_state.pose_.x;
              rel_y = hit_y - robot_state.pose_.y;
              for k = 1:length(rel_x)
                if(sign(rel_x(k)) == sign(cos(ray_angle)))
                  d = sqrt(rel_x(k)^2 + rel_y(k)^2);
                  if(d < ray_ranges(i))
                    ray_ranges(i) = d;
                    hit = true;
                    terrain = true;
                  end
                end
              end
            end
          end
        end
        
        % When no hits, check for world boundaries
        if(~hit)
          % Find end point of ray
          end_pt.x = robot_state.pose_.x + max_dist*cos(ray_angle);
          end_pt.y = robot_state.pose_.y + max_dist*sin(ray_angle);
          
          % Limit end point to be within world boundaries
          end_pt.x = max(0, min(this.config_.scenario.world_width, end_pt.x));
          end_pt.y = max(0, min(this.config_.scenario.world_height, end_pt.y));
          
          % Evaluate new ray length
          ray_ranges(i) = sqrt((end_pt.x - robot_state.pose_.x)^2 + (end_pt.y - robot_state.pose_.y)^2);
        end
        
        % Form state for each ray
        state_indice = 6 + 2*(i - 1);
        state_vector(state_indice) = floor((min(ray_ranges(i), max_dist - delta)/max_dist)*state_res(state_indice));
        state_vector(state_indice + 1) = terrain;
      end
      
      % Correct if elements are over the max allowable value
      % (shouldn't happen, but if it does we want to know)
      if (sum(state_vector >= state_res) ~= 0)
        state_string = '[';
        for i = 1:length(state_vector)
          state_string = sprintf('%s%d, ', state_string, state_vector(i));
        end
        state_string(end - 1:end) = '] ';
        
        warning(['state_vector values greater than max allowed. Reducing to max value. State Vector: ', state_string]);
        state_vector = mod(state_vector, state_res');
      end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %   determineReward
    %
    %   Returns the reward from the performed action based on changes
    %   in the RobotState. The distances used in the calculations are
    %   determined in the getStateVector, since most values are already
    %   calculated there.
    %
    %   Reward is based on the robot moving closer/further to/from the
    %   taerget item, or the target moving closer/further to/from the
    %   collection zone. When the robot's target changes between
    %   iterations no reward is given, since the changes in distances
    %   will not be valid.
    %
    %   INPUTS
    %   robot_state = RobotState object
    %
    %   OUTPUTS
    %   reward = Value of the reward for the action
    
    function reward = determineReward(this, world_state, robot_state, prop)
      % Check if the target has changed from the previous iteration
      if(this.reward_data_.target_id ~= this.prev_reward_data_.target_id)
        
        % Handle item delivered to collection zone
        if(this.prev_reward_data_.target_id ~= -1)
          if(world_state.targets_(this.prev_reward_data_.target_id).returned == true)
            reward = this.config_.IL.return_reward;
            return;
          end
        end
        
        % Task assignment change
        reward = 0;
        return;
      end
      
      % Set distance threshold for rewards
      thresh = this.config_.IL.reward_activation_dist*prop.step_size;
      
      % Handle the case where no target is assigned first, since
      % a target is needed to calculate the target distance
      
      % Reward is based on movement relative to goal (want to go
      % closer to the colelction zone)
      if(this.reward_data_.target_id == -1)
        delta_goal_dist = this.reward_data_.robot_goal_dist; - this.prev_reward_data_.robot_goal_dist;
        
        if (delta_goal_dist < -thresh)
          reward = 2*this.config_.IL.empty_reward_value;
        else
          reward = this.config_.IL.empty_reward_value;
        end
        return;
      end
      
      % Now handle cases where a target has been assigned
      
      % Rewards depend on if the robot is going towards an item,
      % or already carrying one. When none of the reward criteria are
      % met, assign the empty reward value.
      if(robot_state.target_.carrying)
        delta_target_goal_dist = this.reward_data_.target_goal_dist - this.prev_reward_data_.target_goal_dist;
        
        if(delta_target_goal_dist < -thresh)
          reward = this.config_.IL.item_closer_reward;
        elseif(delta_target_goal_dist > thresh)
          reward = this.config_.IL.item_further_reward;
        else
          reward = this.config_.IL.empty_reward_value;
        end
      else
        delta_robot_target_dist = this.reward_data_.robot_target_dist - this.prev_reward_data_.robot_target_dist;
        
        if(delta_robot_target_dist < -thresh)
          reward = this.config_.IL.robot_closer_reward;
        elseif(delta_robot_target_dist > thresh)
          reward = this.config_.IL.robot_further_reward;
        else
          reward = this.config_.IL.empty_reward_value;
        end
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
    
    function [action_index, action_prob] = Policy(this, utility_vals, experience)
      action_prob = ones(size(utility_vals))/this.config_.IL.num_actions;
      
      % If all utility is zero, select a random action
      if(sum(utility_vals) == 0)
        action_index = ceil(rand*this.config_.IL.num_actions);
        return;
      end
      
      % Make all actions with zero quality equal to
      % 0.005*sum(Total Quality), giving it 0.5% probablity to help
      % discover new actions
      total_utility = sum(utility_vals);
      utility_vals(utility_vals == 0) = total_utility.*0.05;
      
      % Use the policy indicated in the configuration
      if (strcmp(this.config_.IL.policy, 'greedy'))
        % Simply select the max utility
        [~, action_index] = max(utility_vals);
      elseif (strcmp(this.config_.IL.policy, 'e-greedy'))
        % Epsilon-Greedy Policy
        rand_action = rand;
        if (rand_action <= this.config_.e_greedy_epsilon)
          action_index = ceil(rand*this.config_.num_actions);
        else
          [~, action_index] = max(utility_vals);
        end
      elseif (strcmp(this.config_.IL.policy, 'boltzmann'))
        % Boltzmann exploration
        exponents = exp(this.config_.IL.boltzmann_temp*utility_vals);
        action_prob = exponents/sum(exponents);
        rand_action = rand;
        for i=1:this.config_.IL.num_actions
          if (rand_action < sum(action_prob(1:i)))
            action_index = i;
            break;
          elseif (i == this.config_.IL.num_actions)
            action_index = i;
          end
        end
      elseif (strcmp(this.config_.IL.policy, 'GLIE'))
        %  Greedy in the Limit Infinite Exploration (using boltzmann
        %  exploration) [Convergence Results for Single-Step
        %  On-Policy Reinforcement Learning Algorithms, Singh et al., 2000]
        %  with a modification to set a minimum allowable probability
        %  (voids greedy in the limit with >0)
        if(sum(experience) >= 1 || sum(utility_vals == 0) ~= length(utility_vals))
          n = this.config_.IL.num_actions;
          alpha = this.config_.IL.GLIE_min_p;
          tau = log((1 - n*alpha)/sum(experience) + n*alpha)/(min(utility_vals) - max(utility_vals));
          exponents = exp(min(tau*utility_vals, 100));  % Need to prevent infinity
          action_prob = exponents/sum(exponents);
        end
        rand_action = rand;
        for i=1:this.config_.IL.num_actions
          if (rand_action < sum(action_prob(1:i)))
            action_index = i;
            break;
          elseif (i == this.config_.IL.num_actions)
            action_index = i;
          end
        end
      else
        error(['No policy matching ', this.config_.IL.policy, ...
          '. Options are "greedy", "e-greedy", "boltzmann", or "GLIE"']);
      end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %   resetForNextRun
    %
    %   Resets all the necessary data for performing consecutive runs,
    %   while maintatining learning data
    
    function resetForNextRun(this)
      this.epoch_reward_ = 0;
      if (this.config_.advice.enabled)
        this.advice_.resetForNextRun();
      end
    end
    
  end
  
end
