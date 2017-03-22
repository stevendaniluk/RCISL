classdef AdviceEnhancement < handle
  % AdviceDev - Developmental advice mechanism
  
  properties
    % General properties
    config_;               % Configuration object
    id_;                   % This robot's Id
    iters_;                % Iteration counter during epoch
    epoch_;                % Epoch counter
    advice_data_;          % Structure of data to save
    mechanism_metrics_;    % Mechanism specific metrics for the current epoch (for updating advice_data_)
    adviser_metrics_;      % Adviser specific metrics for the current epoch (for updating advice_data_)
    epoch_start_iters_;    % For saving epoch data
    
    % Mechanism properties
    max_advisers_;         % Number of advisers to use
    eps_;                  % Base probability value
    adviser_trusts_;        % Moving average adviser's accept reward
    q_learning_;           % Q-learning object
    
    % Advisor properties
    advisers_initialized_; % Flag if all adviser data has been set
    all_robots_;           % Handles of all robot objects
    adviser_handles_;      % Cells containing adviser Q-learning objects
    fake_advisers_;        % Cells containing fake adviser Q-learning objects
  end
  
  properties (Constant)
    % Action definitions
    accept_ = 1;
    skip_ = 2;
    cease_ = 3;
  end
  
  events
    RequestRobotHandle;  % For getting robot data from ExecutiveSimulation
  end
  
  methods
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %   Constructor
    %
    %   Loads in configuration data, initializes properties and data to
    %   be recorded.
    
    function this = AdviceEnhancement(config, id)
      % General parameters
      this.config_ = config;
      this.id_ = id;
      this.epoch_ = 1;
      this.iters_ = 0;
      
      % Allocate cells for storing adviser handles
      this.max_advisers_ = min(this.config_.advice.num_advisers, this.config_.scenario.num_robots - 1);
      this.adviser_handles_ = cell(this.config_.scenario.num_robots - 1, 1);
      this.advisers_initialized_ = false;
      
      % When fake advisers are used their data needs to be loaded in
      if (this.config_.advice.fake_advisers)
        num_fake_advisers = length(config.advice.fake_adviser_files);
        % Create the fake advisers (first adviser is this agent)
        this.fake_advisers_ = cell(num_fake_advisers, 1);
        for i = 1:num_fake_advisers
          % Load the quality and experience files
          filename = config.advice.fake_adviser_files(i);
          q_table = [];
          exp_table = [];
          load(['expert_data/', filename{1}, '/q_table.mat']);
          load(['expert_data/', filename{1}, '/exp_table.mat']);
          
          % Create a Q-learning object to load data into (only
          % provide relevant input args)
          this.fake_advisers_{i} = QLearning(1, 1, 1, config.IL.state_resolution, config.IL.num_actions);
          
          % Load data into Q-learning object
          this.fake_advisers_{i}.q_table_ = q_table;
          this.fake_advisers_{i}.exp_table_ = exp_table;
        end
        
        % Add fake advisers to the list
        this.max_advisers_ = this.max_advisers_ + num_fake_advisers;
      end
      this.advice_data_.num_advisers = this.max_advisers_;
      
      % Initialize mechanism properties
      this.eps_ = 1/this.config_.IL.num_actions;
      this.epoch_start_iters_ = 1;
      this.adviser_trusts_ = 0.0*ones(this.max_advisers_, 1);
      
      % Instantiate Q-learning
      gamma = config.advice.QL.gamma;
      alpha_max = config.advice.QL.alpha_max;
      alpha_rate = config.advice.QL.alpha_rate;
      
      this.q_learning_ = QLearning(gamma, alpha_max, alpha_rate, ...
        this.config_.advice.QL.state_resolution, this.config_.advice.num_actions);
      
      % Initialize advice data being recorded
      if(this.config_.sim.save_advice_data)
        this.initializeMetrics();
      end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %   initializeEpochMetrics
    %
    %   Resets the metrics properties for the next epoch
    
    function initializeMetrics(this)
      % Mechanism metrics
      this.mechanism_metrics_.K_o_norm = 0;
      this.mechanism_metrics_.K_hat_norm = 0;
      this.mechanism_metrics_.reward = 0;
      this.mechanism_metrics_.advice_rate = 0;
      this.mechanism_metrics_.requested_advice = 0;
      this.mechanism_metrics_.advisers_polled = 0;
      this.mechanism_metrics_.advice_accepted = 0;
      this.mechanism_metrics_.adviser_trust = zeros(this.max_advisers_, 1);

      % Adviser specific metrics
      this.adviser_metrics_.adviser_usages = zeros(this.max_advisers_, 1);
      
      this.adviser_metrics_.accept_action = zeros(this.max_advisers_, 1);
      this.adviser_metrics_.accept_reward = zeros(this.max_advisers_, 1);
      this.adviser_metrics_.accept_delta_K = zeros(this.max_advisers_, 1);
      this.adviser_metrics_.accept_action_evil = zeros(this.max_advisers_, 1);

      this.adviser_metrics_.cease_action = zeros(this.max_advisers_, 1);
      this.adviser_metrics_.cease_reward = zeros(this.max_advisers_, 1);
      
      this.adviser_metrics_.skip_action = zeros(this.max_advisers_, 1);
      this.adviser_metrics_.skip_reward = zeros(this.max_advisers_, 1);
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %   preAdviceUpdate
    %
    %   To be called before each time advice is retrieved.
    
    function  preAdviceUpdate(this)
      this.iters_ = this.iters_ + 1;
      
      % Need to initialize the advisers once
      if (~this.advisers_initialized_)
        % Get robot handles from ExecutiveSimulation
        this.notify('RequestRobotHandle');
        
        j = 1;
        for i = 1:this.config_.scenario.num_robots
          if i ~= this.id_
            this.adviser_handles_{j, 1} = this.all_robots_(i, 1).individual_learning_.q_learning_;
            j = j + 1;
          end
        end
        this.advisers_initialized_ = true;
      end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %   getAdvice
    %
    %   Performs the main algorithm for the advice enhancement
    %   mechanism.
    %
    %   INPUTS:
    %   state_vector = Vector defining the robots current state
    %   quality_in = Vector of quality values for this robots state
    %
    %   OUTPUTS:
    %   result = Either the action id, or vector of quality values
    
    function result = getAdvice(this, state_vector, quality_in, alpha)
      % Prepare data
      this.preAdviceUpdate();
      
      % Initialze counters for metrics
      accept_count = 0;
      reward_count = 0;
            
      % Get advisee's knowledge
      p_o = this.convertQToP(quality_in);
      K_o = this.convertPToK(p_o);
      K_o_initial = K_o;
      K_hat = K_o;
      
      % Determine order of advisers for this round
      % (when an adviser's rate is zero, randomize it to ensure
      % random selection)
      rates = this.adviser_trusts_;
      random_rates = -rand(this.max_advisers_, 1);
      rates(rates == 0) = random_rates(rates == 0);
      adviser_rank = sortrows([rates, (1:this.max_advisers_)']);
      adviser_order = flipud(adviser_rank(:, 2));
      
      % Get action from Q-learning
      state_initial = this.formState(K_o, K_o, alpha);
      [action_q, ~] = this.q_learning_.getUtility(state_initial);
      action = this.selectAction(action_q);
      request_advice = (action ~= this.cease_);
      
      n = 0;
      if(request_advice)
        % Poll the first adviser
        n = 1;
        m = adviser_order(n);
        [K_m, evil] = this.pollAdviser(m, state_vector);
        state1 = this.formState(K_o, K_m, alpha);
        if(this.config_.sim.save_advice_data)
          this.adviser_metrics_.adviser_usages(m) = 1 + this.adviser_metrics_.adviser_usages(m);
        end
        
        % Start advice polling
        while (n <= this.max_advisers_)
          % Get accept/skip/cease action from Q-learning
          [action_q, ~] = this.q_learning_.getUtility(state1);
          action = this.selectAction(action_q);
          
          % Update adviser trust
          K_o_unit = max(0, K_o/sqrt(sum(K_o.^2)));
          K_m_unit = max(0, K_m/sqrt(sum(K_m.^2)));
          beta = sum(K_o_unit.*K_m_unit);
          this.adviser_trusts_(m) = this.config_.advice.adviser_trust_alpha*this.adviser_trusts_(m) + (1 - this.config_.advice.adviser_trust_alpha)*beta;
          
          % Set the initial knowledge level
          K_o_norm = sum(abs(K_o));
          
          % Handle each action
          poll_another_adviser = false;
          switch action
            case this.accept_
              accept_count = accept_count + 1;
              
              % Update K
              factor = (K_o >= 0).*K_o/(1 - this.eps_) + (K_o < 0).*K_o/(-this.eps_^2/(1 - this.eps_));
              K_hat = K_o + alpha*(1 - factor).*K_m;
              delta_K = sum(abs(K_hat)) - K_o_norm;
              
              % Calculate the reward
              reward = (1 + this.config_.advice.accept_bias*delta_K)^2;
              
              poll_another_adviser = (n < this.max_advisers_);
              
              % Update adviser metrics
              if(this.config_.sim.save_advice_data)
                this.adviser_metrics_.accept_action(m) = 1 + this.adviser_metrics_.accept_action(m);
                this.adviser_metrics_.accept_delta_K(m) = delta_K + this.adviser_metrics_.accept_delta_K(m);
                this.adviser_metrics_.accept_reward(m) = reward + this.adviser_metrics_.accept_reward(m);
                this.adviser_metrics_.accept_action_evil(m) = evil + this.adviser_metrics_.accept_action_evil(m);
              end
            case this.skip_
              K_hat = K_o;
              reward = (1 + K_o_norm)^2;
              
              poll_another_adviser = (n < this.max_advisers_);
              
              % Update adviser metrics
              if(this.config_.sim.save_advice_data)
                this.adviser_metrics_.skip_action(m) = 1 + this.adviser_metrics_.skip_action(m);
                this.adviser_metrics_.skip_reward(m) = reward + this.adviser_metrics_.skip_reward(m);
              end
            case this.cease_
              K_hat = K_o;
              reward = (1 + K_o_norm)^2;
              
              % Update adviser metrics
              if(this.config_.sim.save_advice_data)
                this.adviser_metrics_.cease_action(m) = 1 + this.adviser_metrics_.cease_action(m);
                this.adviser_metrics_.cease_reward(m) = reward + this.adviser_metrics_.cease_reward(m);
              end
            otherwise
              warning('Invalid advice action. Action=%d', action)
          end
          reward_count = reward_count + reward;
          
          % Get advice for next round from the next adviser
          if(poll_another_adviser)
            n = n + 1;
            m = adviser_order(n);
            [K_m, evil] = this.pollAdviser(m, state_vector);
            if(this.config_.sim.save_advice_data)
              this.adviser_metrics_.adviser_usages(m) = 1 + this.adviser_metrics_.adviser_usages(m);
            end
          end
          
          % Update mechanism Q-learning
          state2 = this.formState(K_hat, K_m, alpha);
          if (this.iters_ > 1)
            this.q_learning_.learn(state1, state2, action, reward);
          end
          
          % End the advice round?
          if(action == this.cease_ || ~poll_another_adviser)
            break;
          end
          
          % Set K and state values for the next round
          state1 = state2;
          K_o = K_hat;
        end
      end
      
      % Convert K_hat to action selection probabilities
      p_a_new = this.eps_ + sign(K_hat).*sqrt((1 - this.eps_)*abs(K_hat));
      action_prob = p_a_new/sum(p_a_new);
      
      % Select new action
      rand_action = rand;
      for i=1:length(K_hat)
        if (rand_action < sum(action_prob(1:i)))
          action_id = i;
          break;
        elseif (i == this.config_.IL.num_actions)
          action_id = i;
        end
      end
      
      % Record mechanism metrics
      if(this.config_.sim.save_advice_data)
        this.mechanism_metrics_.K_o_norm = sum(abs(K_o_initial)) + this.mechanism_metrics_.K_o_norm;
        this.mechanism_metrics_.K_hat_norm = sum(abs(K_hat)) + this.mechanism_metrics_.K_hat_norm;
        this.mechanism_metrics_.advice_rate = alpha + this.mechanism_metrics_.advice_rate;
        this.mechanism_metrics_.adviser_trust = this.adviser_trusts_ + this.mechanism_metrics_.adviser_trust;
        this.mechanism_metrics_.requested_advice = request_advice + this.mechanism_metrics_.requested_advice;
        this.mechanism_metrics_.advisers_polled = n/this.max_advisers_ + this.mechanism_metrics_.advisers_polled;
        
        % Count of advice acceptance and reward is averaged of number of
        % polls, but must default to zero when no advisers are polled
        if(request_advice)
          this.mechanism_metrics_.advice_accepted = accept_count/n + this.mechanism_metrics_.advice_accepted;
          this.mechanism_metrics_.reward = reward_count/n + this.mechanism_metrics_.reward;
        end
      end
      
      % Output the result
      result = action_id;
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %   convertPToK
    %
    %   Converts a vector of action selection probability to a vector
    %   of knowledge values
    
    function K = convertPToK(this, p_a)
      K_denom = 1 - this.eps_;
      K = abs(p_a - this.eps_).*(p_a - this.eps_)/K_denom;
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %   convertQToP
    %
    %   Converts a vector of quality values to a vector of action
    %   selection probabilities
    
    function p_a = convertQToP(this, q_a)
      exponents = exp(q_a/this.config_.IL.softmax_temp);
      p_a = exponents/sum(exponents);
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %   pollAdviser
    %
    %   Asks adviser m for their advice, and returns their K values.
    %   Advisers are numbered with real advisers (i.e. other robots)
    %   first, followed by fake advisers.
    
    function [K_m, evil] = pollAdviser(this, m, state_vector)
      % Get their advice
      if (this.config_.advice.fake_advisers && m > (this.config_.scenario.num_robots - 1))
        [q_m, ~] = this.fake_advisers_{m - (this.config_.scenario.num_robots - 1)}.getUtility(state_vector);
      else
        [q_m, ~] = this.adviser_handles_{m}.getUtility(state_vector);
      end
      
      % Make them evil?
      if (rand < this.config_.advice.evil_advice_prob)
        % Rearrange the vector so the best action, is now the
        % worst, and the worst is now the best
        q_m = min(q_m) + max(q_m) - q_m;
        evil = true;
      else
        evil = false;
      end
      
      % Convert Q values to K values
      p_m = this.convertQToP(q_m);
      K_m = this.convertPToK(p_m);
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %   formState
    %
    %   Converts the K_o and K_m values to a discritized state vector
    
    function state = formState(this, K_o, K_m, alpha)
      K_o_norm = sum(abs(K_o));
      K_m_norm = sum(abs(K_m));
      
      K_o_norm_discrit = min(floor(K_o_norm*this.config_.advice.QL.state_resolution(1)), this.config_.advice.QL.state_resolution(1) - 1);
      K_m_bar = (K_m_norm >= K_o_norm);
      alpha_discrit = min(floor(alpha*this.config_.advice.QL.state_resolution(3)), this.config_.advice.QL.state_resolution(3) - 1);
      
      state = [K_o_norm_discrit; K_m_bar; alpha_discrit];
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %   selectAction
    %
    %   Select action with e-greedy policy
    
    function action = selectAction(this, q_vals)
      % Select action with e-greedy policy
      if (rand < this.config_.advice.e_greedy)
        action = ceil(rand*this.config_.advice.num_actions);
      else
        % Pick best action
        indices = find(max(q_vals) == q_vals);
        if (length(indices) > 1)
          % There is more than one optimal action
          action = indices(ceil(rand*length(indices)));
        else
          % There is a single optimal action
          action = indices;
        end
      end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %   resetForNextRun
    %
    %   Resets all tracking metrics for the next run
    
    function resetForNextRun(this)
      % Save epoch data
      if(this.config_.sim.save_advice_data)
        % For the mechanism metrics, simply divide each data field by the 
        % number of iterations to obtain the epoch average
        num_iters = this.iters_ - this.epoch_start_iters_ + 1;
        fields = fieldnames(this.mechanism_metrics_);
        special_fields = {'advice_accepted', 'advisers_polled', 'reward'};
        advice_iters = this.mechanism_metrics_.requested_advice;
        for i = 1:length(fields)
          % The special fields should be average over the number of
          % iterations where advice was requested
          if(isempty(find(ismember(special_fields, fields{i}), 1)))
            divisor = num_iters;
          else
            divisor = advice_iters;
          end
          this.advice_data_.(fields{i})(:, this.epoch_) = this.mechanism_metrics_.(fields{i})/divisor;
        end
        
        % Adviser specific metrics need to be normalized to the usage of
        % each adviser and action
        this.advice_data_.accept_reward(:, this.epoch_) = this.adviser_metrics_.accept_reward./this.adviser_metrics_.accept_action;
        this.advice_data_.accept_delta_K(:, this.epoch_) = this.adviser_metrics_.accept_delta_K./this.adviser_metrics_.accept_action;
        this.advice_data_.accept_action(:, this.epoch_) = this.adviser_metrics_.accept_action./this.adviser_metrics_.adviser_usages;
        this.advice_data_.accept_action_evil(:, this.epoch_) = this.adviser_metrics_.accept_action_evil./this.adviser_metrics_.adviser_usages;
        
        this.advice_data_.skip_reward(:, this.epoch_) = this.adviser_metrics_.skip_reward./this.adviser_metrics_.skip_action;
        this.advice_data_.skip_action(:, this.epoch_) = this.adviser_metrics_.skip_action./this.adviser_metrics_.adviser_usages;
        
        this.advice_data_.cease_reward(:, this.epoch_) = this.adviser_metrics_.cease_reward./this.adviser_metrics_.cease_action;
        this.advice_data_.cease_action(:, this.epoch_) = this.adviser_metrics_.cease_action./this.adviser_metrics_.adviser_usages;
                
        this.advice_data_.adviser_usages(:, this.epoch_) = this.adviser_metrics_.adviser_usages/sum(this.adviser_metrics_.adviser_usages);
        
        % When an adviser is not used, the normalized metrics will come out
        % as NaN, which needs to be corrected to zero
        fields = fieldnames(this.adviser_metrics_);
        for i = 1:length(fields)
          temp = this.advice_data_.(fields{i})(:, this.epoch_);
          temp(isnan(temp)) = 0;
          this.advice_data_.(fields{i})(:, this.epoch_) = temp;
        end
        
        % Reset the metrics for the next round
        this.initializeMetrics();
      end
      
      % Increment counters
      this.epoch_start_iters_ = this.iters_ + 1;
      this.epoch_ = this.epoch_ + 1;
    end
    
  end
  
end

