classdef AdviceEnhancement < handle
    % AdviceDev - Developmental advice mechanism
    
    properties
        % Configuration settings
        config_ = [];
        num_robots_ = [];
        id_ = [];
        iters_ = [];
        epoch_ = [];
        
        % Advisor Properties
        adviser_handles_ = [];
        advisers_initialized_ = [];
        all_robots_ = [];
        
        % Structure of data to save
        advice_data_ = [];
                
        % General simulation properties
        num_robot_actions_ = [];     % How many actions each robot can make
        il_softmax_temp_ = [];       % Temp setting for IL softmax distribution 
        epoch_start_iters_ = [];     % For saving epoch data
        
        % Mechanism properties
        max_advisers_ = [];         % Number of advisers to use
        reject_reward_bias_ = [];   % Coefficient applied to reject reward
        eps_ = [];                  % Base probability value
        adviser_value_ = [];        % Moving average adviser's accept reward
        accept_rate_alpha_ = [];    % Coeff. for acceptance rate moving average
        used_advisers_ = [];        % Flags for which advisers have been used this round
        e_greedy_ = [];             % Coefficient for e-greedy action selection
        evil_advice_prob_ = [];     % Probability that an adviser will be evil
        fake_advisers_on_ = [];     % Flag for if fake advisers are used (as opposed to other robots)
        fake_advisers_ = [];        % Cells containing fake adviser Q-learning objects
        all_accept_ = [];           % Flag to override all actions with accept
        all_reject_ = [];           % Flag to override all actions with reject
        
        % Learning properties
        q_learning_ = [];           % Q-learning object
        ql_state_res_ = [];         % Resolution of each state variable
        ql_num_actions_ = [];       % Number of possible actions
        ql_initialized_ = [];       % Flag for if learning has started
        action_ = [];               % Current action selected
        reward_ = [];               % Reward received for current action
        
    end
    
    properties (Constant)
        % Action definitions
        accept_ = 1;
        reject_ = 2;
        skip_ = 3;
    end
    
    events
        RequestRobotHandle;
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
            
            % Get parameters from config
            this.num_robots_ = config.numRobots;
            this.num_robot_actions_ = config.num_actions;
            this.il_softmax_temp_ = config.softmax_temp;
            this.reject_reward_bias_ = config.advice_reject_reward_bias;
            this.evil_advice_prob_ = config.advice_evil_advice_prob;
            this.ql_state_res_ = config.advice_state_resolution;
            this.ql_num_actions_ = config.advice_num_actions;
            this.e_greedy_ = config.advice_e_greedy;
            this.accept_rate_alpha_ = config.advice_accept_rate_alpha;
            this.fake_advisers_on_ = config.advice_fake_advisers;
            this.all_accept_ = config.advice_all_accept;
            this.all_reject_ = config.advice_all_reject;
            this.max_advisers_ = min(config.advice_num_advisers, this.num_robots_ - 1);
            
            % Allocate cells for storing adviser handles
            this.adviser_handles_ = cell(this.num_robots_ - 1, 1);
            this.advisers_initialized_ = false;
            
            % When fake advisers are used their data needs to be loaded in
            if (this.fake_advisers_on_)
                num_fake_advisers = length(config.advice_fake_adviser_files);
                % Create the fake advisers (first adviser is this agent)
                this.fake_advisers_ = cell(num_fake_advisers, 1);
                for i = 1:num_fake_advisers
                    % Load the quality and experience files
                    filename = config.advice_fake_adviser_files(i);
                    q_tables = [];
                    exp_tables = [];
                    load(['expert_data/', filename{1}, '/q_tables.mat']);
                    load(['expert_data/', filename{1}, '/exp_tables.mat']);
                    
                    % Create a Q-learning object to load data into (only
                    % provide relevant input args)
                    this.fake_advisers_{i} = QLearning(1, 1, 1, config.num_state_vrbls, config.state_resolution, config.num_actions);
                    
                    % Load data into Q-learning object
                    this.fake_advisers_{i}.q_table_ = q_tables{1};
                    this.fake_advisers_{i}.exp_table_ = exp_tables{1};
                end
                
                % Add fake advisers to the list
                this.max_advisers_ = this.max_advisers_ + num_fake_advisers;
            end
                                    
            % Initialize mechanism properties
            this.eps_ = 1/this.num_robot_actions_;            
            this.epoch_start_iters_ = 1;
            this.adviser_value_ = 0.0*ones(this.max_advisers_, 1);
            
            % Instantiate Q-learning
            gamma = config.advice_gamma;
            alpha_max = config.advice_alpha_max;
            alpha_rate = config.advice_alpha_rate;
            num_state_vrbls = length(this.ql_state_res_);
            
            this.q_learning_ = QLearning(gamma, alpha_max, alpha_rate, ...
                                num_state_vrbls, this.ql_state_res_, this.ql_num_actions_);
            
            this.ql_initialized_ = false;
            this.action_ = 1;
            this.reward_ = 0;
                        
            % Initialize advice data being recorded
            % Iteration and epoch data will have some common fields
            if(this.config_.save_advice_data)
                common_fields.K_o_norm = 0;
                common_fields.K_hat_norm = 0;
                common_fields.delta_K = 0;
                common_fields.beta_hat = 0;
                common_fields.adviser_value = zeros(this.max_advisers_, 1);
                common_fields.evil_advice = zeros(this.max_advisers_, 1);
                common_fields.accept_action = zeros(this.max_advisers_, 1);
                common_fields.accept_delta_K = zeros(this.max_advisers_, 1);
                common_fields.accept_beta_hat = zeros(this.max_advisers_, 1);
                common_fields.reject_action = zeros(this.max_advisers_, 1);
                common_fields.reject_delta_K = zeros(this.max_advisers_, 1);
                common_fields.reject_beta_hat = zeros(this.max_advisers_, 1);
                common_fields.skip_action = zeros(this.max_advisers_, 1);
                common_fields.accept_reward = zeros(this.max_advisers_, 1);
                common_fields.reject_reward = zeros(this.max_advisers_, 1);
                common_fields.skip_reward = zeros(this.max_advisers_, 1);
                common_fields.round_reward = 0;
                common_fields.round_accept_flag = 0;
                common_fields.round_accept_count = 0;
                
                this.advice_data_.iter = common_fields;
                this.advice_data_.iter.evil_advice = zeros(this.max_advisers_, 1);
                
                this.advice_data_.epoch = common_fields;
                this.advice_data_.epoch.accept_action_benev = zeros(this.max_advisers_, 1);
                this.advice_data_.epoch.accept_action_evil = zeros(this.max_advisers_, 1);
            end
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
                for i = 1:this.num_robots_
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
        
        function result = getAdvice(this, state_vector, quality_in)
            % Prepare data
            this.preAdviceUpdate();
                        
            % Variables for tracking metrics
            if(this.config_.save_advice_data)
                accept_action = zeros(this.max_advisers_, 1);
                accept_delta_K = zeros(this.max_advisers_, 1);
                accept_beta_hat = zeros(this.max_advisers_, 1);
                reject_action = zeros(this.max_advisers_, 1);
                reject_delta_K = zeros(this.max_advisers_, 1);
                reject_beta_hat = zeros(this.max_advisers_, 1);
                accept_reward = zeros(this.max_advisers_, 1);
                reject_reward = zeros(this.max_advisers_, 1);
                skip_reward = zeros(this.max_advisers_, 1);
                skip_action = zeros(this.max_advisers_, 1);
            end
                        
            % Get advisee's knowledge
            p_o = this.convertQToP(quality_in);
            K_o = this.convertPToK(p_o);
            K_o_initial = K_o;
            K_o_norm_initial = sum(abs(K_o));
            
            % Determine order of advisers for this round
            % (when an adviser's rate is zero, randomize it to ensure
            % random selection)
            rates = this.adviser_value_;
            random_rates = -rand(this.max_advisers_, 1);
            rates(rates == 0) = random_rates(rates == 0);
            adviser_rank = sortrows([rates, (1:this.max_advisers_)']);
            adviser_order = flipud(adviser_rank(:, 2));
            
            % Main advice loop
            accept_count = 0;
            this.action_ = 0;
            n = 1;
            m = adviser_order(n);
            K_hat = K_o;
            K_m = this.askAdviser(m, state_vector);
            state1 = this.formState(K_o, K_m);
            while (n <= this.max_advisers_ && this.action_ ~= this.reject_)
                
                % Get action from Q-learning
                [action_q, ~] = this.q_learning_.getUtility(state1);
                
                % Select action with e-greedy policy
                if (rand < this.e_greedy_)
                    action = ceil(rand*this.ql_num_actions_);
                else
                    % Pick best action
                    indices = find(max(action_q) == action_q);
                    if (length(indices) > 1)
                        % There is more than one optimal action
                        action = indices(ceil(rand*length(indices)));
                    else
                        % There is a single optimal action
                        action = indices;
                    end
                end
                
                % DEVELOPMENT
                if(this.all_accept_)
                    this.action_ = this.accept_;
                elseif(this.all_reject_)
                    this.action_ = this.reject_;
                else
                    this.action_ = action;
                end
                
                K_o_norm = sum(abs(K_o));
                beta_m = K_m'*K_o;
                
                if(this.action_ == this.accept_)
                    accept_count = accept_count + 1;
                                        
                    % Update K
                    K_hat = K_o + abs(K_m - K_o).*K_m;
                    delta_K = sum(abs(K_hat)) - K_o_norm;
                    
                    % Calculate the reward (and ensure it is valid)
                    reward = (beta_m >= 0)*((1 + delta_K/(K_o_norm + abs(delta_K)))^2 - 1);
                    if (isnan(reward)); this.reward_ = 0; else this.reward_ = reward; end
                    
                    % Update adviser value
                    this.adviser_value_(m) = this.accept_rate_alpha_*this.adviser_value_(m) + (1 - this.accept_rate_alpha_)*this.reward_;
                    
                    % For data metrics
                    if(this.config_.save_advice_data)
                        accept_action(m) =  1;
                        accept_reward(m) = this.reward_;
                        accept_beta_hat(m) = (beta_m > 0) - (beta_m < 0);
                        accept_delta_K(m) = delta_K;
                    end
                    
                    % Get advice from the next adviser (if available)
                    if(n ~= this.max_advisers_) 
                        m = adviser_order(n + 1);
                        K_m = this.askAdviser(m, state_vector);
                        
                        % Find the new state
                        state2 = this.formState(K_o, K_m);
                    else
                        state2 = this.formState(K_hat, K_m);
                    end
                    
                elseif (this.action_ == this.reject_)
                    state2 = state1;
                    K_hat = K_o;
                    delta_K = 0;
                    this.reward_ = this.reject_reward_bias_*((1 + K_o_norm)^2 - 1);
                    
                    % Update adviser value
                    this.adviser_value_(m) = this.accept_rate_alpha_*this.adviser_value_(m);
                    
                    % For data metrics
                    if(this.config_.save_advice_data)
                        reject_action(m) = 1;
                        reject_reward(m) = this.reward_;
                        reject_beta_hat(m) = (beta_m > 0) - (beta_m < 0);
                        reject_delta_K(m) = delta_K;
                    end
                elseif(this.action_ == this.skip_)
                    K_hat = K_o;
                    delta_K = 0;
                    this.reward_ = this.reject_reward_bias_*((1 + K_o_norm)^2 - 1);
                    
                    % Update adviser value
                    this.adviser_value_(m) = this.accept_rate_alpha_*this.adviser_value_(m);
                    
                    % For data metrics
                    if(this.config_.save_advice_data)
                        skip_action(m) = 1;
                        skip_reward(m) = this.reward_;
                    end
                    
                    % Get advice from the next adviser (if available)
                    if(n ~= this.max_advisers_) 
                        m = adviser_order(n + 1);
                        K_m = this.askAdviser(m, state_vector);
                        
                        % Find the new state
                        state2 = this.formState(K_o, K_m);
                    else
                        state2 = this.formState(K_hat, K_m);
                    end
                else
                    warning('Invalid advice action. Action=%d', this.action_)
                end
                
                % Update Q-learning
                if (this.ql_initialized_)
                    this.q_learning_.learn(state1, state2, this.action_, this.reward_);
                end
                this.ql_initialized_ = true;
                
                state1 = state2;
                K_o = K_hat;
                n = n + 1;
                
            end
            K_hat_norm = sum(abs(K_hat));
            
            % Convert K_hat to action selection probabilities
            p_a_new = this.eps_ + sign(K_hat).*sqrt((1 - this.eps_)*abs(K_hat));
            action_prob = p_a_new/sum(p_a_new);
            
            % Select new action
            rand_action = rand;
            for i=1:length(K_hat)
                if (rand_action < sum(action_prob(1:i)))
                    action_id = i;
                    break;
                elseif (i == this.config_.num_actions)
                    action_id = i;
                end
            end
            
            % Record tracking metrics
            if(this.config_.save_advice_data)
                this.advice_data_.iter.K_o_norm(this.iters_) = K_o_norm_initial;
                this.advice_data_.iter.K_hat_norm(this.iters_) = K_hat_norm;
                this.advice_data_.iter.delta_K(this.iters_) = delta_K;
                this.advice_data_.iter.beta_hat(this.iters_) = K_hat'*K_o_initial;
                this.advice_data_.iter.adviser_value(:, this.iters_) = this.adviser_value_;
                this.advice_data_.iter.accept_action(:, this.iters_) = accept_action;
                this.advice_data_.iter.accept_delta_K(:, this.iters_) = accept_delta_K;
                this.advice_data_.iter.accept_beta_hat(:, this.iters_) = accept_beta_hat;
                this.advice_data_.iter.reject_action(:, this.iters_) = reject_action;
                this.advice_data_.iter.reject_delta_K(:, this.iters_) = reject_delta_K;
                this.advice_data_.iter.reject_beta_hat(:, this.iters_) = reject_beta_hat;
                this.advice_data_.iter.skip_action(:, this.iters_) = skip_action;
                this.advice_data_.iter.accept_reward(:, this.iters_) = accept_reward;
                this.advice_data_.iter.reject_reward(:, this.iters_) = reject_reward;
                this.advice_data_.iter.skip_reward(:, this.iters_) = skip_reward;
                this.advice_data_.iter.round_reward(this.iters_) = (sum(accept_reward) + sum(reject_reward))/(n - 1);
                this.advice_data_.iter.round_accept_flag(this.iters_) = (accept_count >= 1);
                this.advice_data_.iter.round_accept_count(this.iters_) = accept_count;
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
            exponents = exp(q_a/this.il_softmax_temp_);
            p_a = exponents/sum(exponents);
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %   askAdviser
        %
        %   Asks adviser m for their advice, and returns their K values.
        %   Advisers are numbered with real advisers (i.e. other robots)
        %   first, followed by fake advisers.
        
        function K_m = askAdviser(this, m, state_vector)
            % Get their advice
            if (this.fake_advisers_on_ && m > (this.num_robots_ - 1))
                [q_m, ~] = this.fake_advisers_{m - (this.num_robots_ - 1)}.getUtility(state_vector);
            else
                [q_m, ~] = this.adviser_handles_{m}.getUtility(state_vector);
            end
            
            % Make them evil?
            if (rand < this.evil_advice_prob_)
                % Rearrange the vector so the best action, is now the
                % worst, and the worst is now the best
                q_m = min(q_m) + max(q_m) - q_m;
                if(this.config_.save_advice_data)
                    this.advice_data_.iter.evil_advice(m, this.iters_) = 1;
                end
            else
                if(this.config_.save_advice_data)
                    this.advice_data_.iter.evil_advice(m, this.iters_) = 0;
                end
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
        
        function state = formState(this, K_o, K_m)
            K_o_norm = sum(abs(K_o));
            K_m_norm = sum(abs(K_m));
            
            K_o_norm_discrit = min(floor(K_o_norm*this.ql_state_res_(1)), this.ql_state_res_(1) - 1);
            K_m_bar = (K_m_norm > K_o_norm);
            beta_m_bar = (K_m'*K_o >= 0);
            
            state = [K_o_norm_discrit, K_m_bar, beta_m_bar];
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %   resetForNextRun
        %
        %   Resets all tracking metrics for the next run
        
        function resetForNextRun(this)            
            % Save epoch data
            if(this.config_.save_advice_data)
                num_iters = this.iters_ - this.epoch_start_iters_ + 1;
                
                % Average of data over this epoch
                this.advice_data_.epoch.K_o_norm(this.epoch_) = sum(this.advice_data_.iter.K_o_norm(this.epoch_start_iters_:this.iters_))/num_iters;
                this.advice_data_.epoch.K_hat_norm(this.epoch_) = sum(this.advice_data_.iter.K_hat_norm(this.epoch_start_iters_:this.iters_))/num_iters;
                this.advice_data_.epoch.delta_K(this.epoch_) = sum(this.advice_data_.iter.delta_K(this.epoch_start_iters_:this.iters_))/num_iters;
                this.advice_data_.epoch.beta_hat(this.epoch_) = sum(this.advice_data_.iter.beta_hat(this.epoch_start_iters_:this.iters_))/num_iters;
                this.advice_data_.epoch.adviser_value(:, this.epoch_) = sum(this.advice_data_.iter.adviser_value(:, this.epoch_start_iters_:this.iters_), 2)/num_iters;
                this.advice_data_.epoch.accept_action(:, this.epoch_) = sum(this.advice_data_.iter.accept_action(:, this.epoch_start_iters_:this.iters_), 2)/num_iters;
                this.advice_data_.epoch.accept_delta_K(:, this.epoch_) = sum(this.advice_data_.iter.accept_delta_K(:, this.epoch_start_iters_:this.iters_), 2)/num_iters;
                this.advice_data_.epoch.accept_beta_hat(:, this.epoch_) = sum(this.advice_data_.iter.accept_beta_hat(:, this.epoch_start_iters_:this.iters_), 2)/num_iters;
                this.advice_data_.epoch.reject_action(:, this.epoch_) = sum(this.advice_data_.iter.reject_action(:, this.epoch_start_iters_:this.iters_), 2)/num_iters;
                this.advice_data_.epoch.reject_delta_K(:, this.epoch_) = sum(this.advice_data_.iter.reject_delta_K(:, this.epoch_start_iters_:this.iters_), 2)/num_iters;
                this.advice_data_.epoch.reject_beta_hat(:, this.epoch_) = sum(this.advice_data_.iter.reject_beta_hat(:, this.epoch_start_iters_:this.iters_), 2)/num_iters;
                this.advice_data_.epoch.skip_action(:, this.epoch_) = sum(this.advice_data_.iter.skip_action(:, this.epoch_start_iters_:this.iters_), 2)/num_iters;
                this.advice_data_.epoch.accept_reward(:, this.epoch_) = sum(this.advice_data_.iter.accept_reward(:, this.epoch_start_iters_:this.iters_), 2)/num_iters;
                this.advice_data_.epoch.reject_reward(:, this.epoch_) = sum(this.advice_data_.iter.reject_reward(:, this.epoch_start_iters_:this.iters_), 2)/num_iters;
                this.advice_data_.epoch.skip_reward(:, this.epoch_) = sum(this.advice_data_.iter.skip_reward(:, this.epoch_start_iters_:this.iters_), 2)/num_iters;
                this.advice_data_.epoch.round_reward(this.epoch_) = sum(this.advice_data_.iter.round_reward(this.epoch_start_iters_:this.iters_))/num_iters;
                this.advice_data_.epoch.round_accept_flag(this.epoch_) = sum(this.advice_data_.iter.round_accept_flag(this.epoch_start_iters_:this.iters_))/num_iters;
                this.advice_data_.epoch.round_accept_count(this.epoch_) = sum(this.advice_data_.iter.round_accept_count(this.epoch_start_iters_:this.iters_))/num_iters;
                
                % Manually extract the benevolent and evil advice instances
                for i = 1:this.max_advisers_
                    evil_instances = this.advice_data_.iter.evil_advice(i, this.epoch_start_iters_:this.iters_);
                    accept_instances = this.advice_data_.iter.accept_action(i, this.epoch_start_iters_:this.iters_);
                    this.advice_data_.epoch.accept_action_benev(i, this.epoch_) = sum(accept_instances.*(~evil_instances))/num_iters;
                    this.advice_data_.epoch.accept_action_evil(i, this.epoch_) = sum(accept_instances.*evil_instances)/num_iters;
                end
                this.epoch_start_iters_ = this.iters_ + 1;
            end
            % Increment epochs
            this.epoch_ = this.epoch_ + 1;
        end
                        
    end
    
end

