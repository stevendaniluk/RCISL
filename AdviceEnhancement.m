classdef AdviceEnhancement < Advice
    % AdviceDev - Developmental advice mechanism
    
    properties
        % General simulation properties
        num_robot_actions_ = [];
        il_softmax_temp_ = [];     % Temp setting for IL softmax distribution 
        
        % Mechanism properties
        evil_adviser_ = [];         % Boolean flag for if adviser is evil
        eps_ = [];                  % Base probability value
        epoch_start_iters_ = [];    % For saving epoch data
        max_advisers_ = [];
        adviser_accept_rate_ = [];
        accept_rate_alpha_ = [];
        ask_ratio_alpha_ = [];
        e_greedy_ = [];
        d1_ = [];
        d2_ = [];
        fake_advisers_on_ = [];
        fake_advisers_ = [];
        ask_ratio_ = [];
        ask_ratio_factor_ = [];
        
        % Learning properties
        q_learning_ = [];           % Q-learning object
        ql_state_res_ = [];
        ql_num_actions_ = [];
        ql_state_ = [];
        ql_prev_state_ = [];
        ql_initialized_ = [];
        action_ = [];
        reward_ = [];
        reward_p1_ = [];
        reward_p2_ = [];
        
    end
    
    properties (Constant)
        % Action definitions
        accept_ = 1;
        reject_ = 2;
        cease_advice_ = 3;
    end
    
    methods
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %   Constructor
        %
        %   Loads in configuration data, initializes properties and data to
        %   be recorded.
        
        function this = AdviceEnhancement(config, id)
            % Pass arguments to superclass
            this@Advice(config, id);
            
            % Get parameters from config
            this.num_robot_actions_ = config.num_actions;
            this.il_softmax_temp_ = config.softmax_temp;
            this.evil_adviser_ = config.a_enh_evil_adviser;
            this.ql_state_res_ = config.a_enh_state_resolution;
            this.ql_num_actions_ = config.a_enh_num_actions;
            this.e_greedy_ = config.a_enh_e_greedy;
            this.d1_ = config.a_enh_d1;
            this.d2_ = config.a_enh_d2;
            this.accept_rate_alpha_ = config.a_enh_accept_rate_alpha;
            this.ask_ratio_alpha_ = config.a_enh_ask_ratio_alpha;
            this.fake_advisers_on_ = config.a_enh_fake_advisers;
            
            if (this.fake_advisers_on_)
                this.max_advisers_ = length(config.a_enh_fake_adviser_files);
                
                % Create the fake advisers (first adviser is this agent)
                this.fake_advisers_ = cell(this.max_advisers_ + 1, 1);
                for i = 1:this.max_advisers_
                    % Load the quality and experience files
                    filename = config.a_enh_fake_adviser_files(i);
                    q_tables = [];
                    exp_tables = [];
                    load(['expert_data/', filename{1}, '/q_tables.mat']);
                    load(['expert_data/', filename{1}, '/exp_tables.mat']);
                    
                    % Create a Q-learning object to load data into (only
                    % provide relevant input args)
                    this.fake_advisers_{i + 1} = QLearning(1, 1, 1, config.num_state_vrbls, config.state_resolution, config.num_actions);
                    
                    % Load data into Q-learning object
                    this.fake_advisers_{i + 1}.q_table_ = q_tables{1};
                    this.fake_advisers_{i + 1}.exp_table_ = exp_tables{1};
                end
                
            else
                this.max_advisers_ = min(config.a_enh_num_advisers, this.num_robots_ - 1);
            end
                        
            % Initialize mechanism properties
            this.eps_ = 1/this.num_robot_actions_;            
            this.epoch_start_iters_ = 1;
            this.adviser_accept_rate_ = zeros(this.max_advisers_ + 1, 1);
            this.ask_ratio_ = 0;
            this.ask_ratio_factor_ = 0;
            
            % Instantiate Q-learning
            gamma = config.a_enh_gamma;
            alpha_max = config.a_enh_alpha_max;
            alpha_rate = config.a_enh_alpha_rate;
            num_state_vrbls = length(this.ql_state_res_);
            
            this.q_learning_ = QLearning(gamma, alpha_max, alpha_rate, ...
                                num_state_vrbls, this.ql_state_res_, this.ql_num_actions_);
            
            this.ql_state_ = zeros(1, num_state_vrbls);
            this.ql_prev_state_ = zeros(1, num_state_vrbls);
            this.ql_initialized_ = false;
            this.action_ = 1;
            this.reward_ = 0;
            this.reward_p1_ = 0;
            this.reward_p2_ = 0;
                        
            % Advice data being recorded
            this.advice_data_.a_enh.K_o_norm_iter = 0;
            this.advice_data_.a_enh.K_hat_norm_iter = 0;
            this.advice_data_.a_enh.delta_K_iter = 0;
            this.advice_data_.a_enh.beta_hat_iter = 0;
            this.advice_data_.a_enh.max_p_a_in_iter = 0;
            this.advice_data_.a_enh.max_p_a_out_iter = 0;
            this.advice_data_.a_enh.ask_count_iter = 0;
            this.advice_data_.a_enh.accept_rates_iter = zeros(this.max_advisers_ + 1, 1);
            this.advice_data_.a_enh.accept_ratio_iter = zeros(this.max_advisers_ + 1, 1);
            this.advice_data_.a_enh.reject_ratio_iter = zeros(this.max_advisers_ + 1, 1);
            this.advice_data_.a_enh.cease_ratio_iter = zeros(this.max_advisers_ + 1, 1);
            this.advice_data_.a_enh.accept_delta_K_iter = zeros(this.max_advisers_ + 1, 1);
            this.advice_data_.a_enh.accept_beta_hat_iter = zeros(this.max_advisers_ + 1, 1);
            this.advice_data_.a_enh.reject_delta_K_iter = zeros(this.max_advisers_ + 1, 1);
            this.advice_data_.a_enh.reject_beta_hat_iter = zeros(this.max_advisers_ + 1, 1);
            this.advice_data_.a_enh.cease_K_norm_iter = zeros(this.max_advisers_ + 1, 1);
            this.advice_data_.a_enh.accept_reward_iter = zeros(this.max_advisers_ + 1, 1);
            this.advice_data_.a_enh.reject_reward_iter = zeros(this.max_advisers_ + 1, 1);
            this.advice_data_.a_enh.cease_reward_iter = zeros(this.max_advisers_ + 1, 1);
            this.advice_data_.a_enh.reward_iter = 0;
            this.advice_data_.a_enh.ask_ratio_factor_iter = 0;
            
            this.advice_data_.a_enh.K_o_norm_epoch = 0;
            this.advice_data_.a_enh.K_hat_norm_epoch = 0;
            this.advice_data_.a_enh.delta_K_epoch = 0;
            this.advice_data_.a_enh.beta_hat_epoch = 0;
            this.advice_data_.a_enh.max_p_a_in_epoch = 0;
            this.advice_data_.a_enh.max_p_a_out_epoch = 0;
            this.advice_data_.a_enh.ask_count_epoch = 0;
            this.advice_data_.a_enh.accept_rates_epoch = zeros(this.max_advisers_ + 1, 1);
            this.advice_data_.a_enh.accept_ratio_epoch = zeros(this.max_advisers_ + 1, 1);
            this.advice_data_.a_enh.reject_ratio_epoch = zeros(this.max_advisers_ + 1, 1);
            this.advice_data_.a_enh.cease_ratio_epoch = zeros(this.max_advisers_ + 1, 1);
            this.advice_data_.a_enh.accept_delta_k_epoch = zeros(this.max_advisers_ + 1, 1);
            this.advice_data_.a_enh.accept_beta_hat_epoch = zeros(this.max_advisers_ + 1, 1);
            this.advice_data_.a_enh.reject_delta_k_epoch = zeros(this.max_advisers_ + 1, 1);
            this.advice_data_.a_enh.reject_beta_hat_epoch = zeros(this.max_advisers_ + 1, 1);
            this.advice_data_.a_enh.cease_K_norm_epoch = zeros(this.max_advisers_ + 1, 1);
            this.advice_data_.a_enh.accept_reward_epoch = zeros(this.max_advisers_ + 1, 1);
            this.advice_data_.a_enh.reject_reward_epoch = zeros(this.max_advisers_ + 1, 1);
            this.advice_data_.a_enh.cease_reward_epoch = zeros(this.max_advisers_ + 1, 1);
            this.advice_data_.a_enh.reward_epoch = 0;
            this.advice_data_.a_enh.ask_ratio_factor_epoch = 0;
                        
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
            accept_count = zeros(this.max_advisers_ + 1, 1);
            reject_count = zeros(this.max_advisers_ + 1, 1);
            cease_count = zeros(this.max_advisers_ + 1, 1);
            accept_delta_K = zeros(this.max_advisers_ + 1, 1);
            accept_beta_hat = zeros(this.max_advisers_ + 1, 1);
            reject_delta_K = zeros(this.max_advisers_ + 1, 1);
            reject_beta_hat = zeros(this.max_advisers_ + 1, 1);
            cease_K_norm = zeros(this.max_advisers_ + 1, 1);
            accept_reward = zeros(this.max_advisers_ + 1, 1);
            reject_reward = zeros(this.max_advisers_ + 1, 1);
            cease_reward = zeros(this.max_advisers_ + 1, 1);
            
            A_count = zeros(this.max_advisers_ + 1, 1);
            B_count = zeros(this.max_advisers_ + 1, 1);
            
            % Get advisee's knowledge
            p_o = this.convertQToP(quality_in);
            K_o = this.convertPToK(p_o);
            K_o_initial = K_o;
            K_o_norm_initial = sum(abs(K_o));
            
            % Main advice loop (Algorithm 1)
            action = 0;
            ask_count = 0;
            K_m = K_o;
            adviser_id = this.id_;
            used_advisers = false(this.max_advisers_ + 1, 1);
            while (ask_count < this.max_advisers_ && action ~= this.cease_advice_)
                
                % Get advice from an adviser(only after an agent has "advised" itself)
                if (action ~= 0)
                    K_o = K_hat;
                    
                    % Select next adviser
                    used_advisers(adviser_id) = true;
                    [~, adviser_id] = max((this.adviser_accept_rate_ + 1).*~used_advisers);
                    
                    % Get their advice
                    if (this.fake_advisers_on_)
                        [q_m, ~] = this.fake_advisers_{adviser_id}.getUtility(state_vector);
                    else
                        [q_m, ~] = this.adviser_handles_{adviser_id}.individual_learning_.q_learning_.getUtility(state_vector);
                    end
                    
                    % Make them evil?
                    if (this.evil_adviser_ && adviser_id == 4)
                        % Rearrange the vector so the best action, is now the
                        % worst, and the worst is now the best
                        q_m = min(q_m) + max(q_m) - q_m;
                    end
                    
                    p_m = this.convertQToP(q_m);
                    K_m = this.convertPToK(p_m);
                    
                    ask_count = ask_count + 1;
                end
                
                % Form state
                K_o_norm = sum(abs(K_o));
                K_m_norm = sum(abs(K_m));
                
                K_o_norm_discrit = min(floor(K_o_norm*this.ql_state_res_(1)), this.ql_state_res_(1) - 1);
                K_m_bar = (K_m_norm > K_o_norm);
                beta_m_bar = (K_m'*K_o > 0);
                                
                this.ql_prev_state_ = this.ql_state_;
                this.ql_state_ = [K_o_norm_discrit, K_m_bar, beta_m_bar, ask_count];
                
                % Update Q-learning
                if (this.ql_initialized_)
                    this.q_learning_.learn(this.ql_prev_state_, this.ql_state_, this.action_, this.reward_);
                end
                this.ql_initialized_ = true;
                
                % Get action from Q-learning
                [action_q, ~] = this.q_learning_.getUtility(this.ql_state_);
                
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
                %if (ask_count == 0)
                %    action = this.accept_;
                %end
                
                this.action_ = action;
                                
                % Calculate K_hat
                if (action == this.accept_)
                    K_hat = K_o + ((K_m - K_o)/(1 - this.eps_)).*K_m;
                else
                    K_hat = K_o;
                end
                K_hat_norm = sum(abs(K_hat));
                delta_K = K_hat_norm - K_o_norm;
                
                % Determine reward
                % Coeff A to discourage accepting advice, (increase with
                % number of acceptances)
                A = (1 - (ask_count + 1)*this.d1_*(action ~= this.cease_advice_))^2;
                A_count(adviser_id) = A;
                % Coeff B to encourage achieving a large delta_K
                B = (1 + delta_K - this.d2_)^2;
                B_count(adviser_id) = B;
                % Final reward
                this.reward_ = A + B;
                               
                % For tracking metrics
                if (action == this.accept_)
                    beta_hat = (K_hat'*K_o > 0) - (K_hat'*K_o <= 0);
                                        
                    accept_beta_hat(adviser_id) = beta_hat;    % For tracking metrics
                    accept_delta_K(adviser_id) = delta_K;      % For tracking metrics
                    accept_reward(adviser_id) = this.reward_;  % For tracking metrics
                    accept_count(adviser_id) =  1;             % For tracking metrics
                elseif (action == this.reject_)
                    beta_hat = (K_m'*K_o > 0) - (K_m'*K_o <= 0);
                                        
                    reject_beta_hat(adviser_id) = beta_hat;    % For tracking metrics
                    reject_delta_K(adviser_id) = delta_K;      % For tracking metrics
                    reject_reward(adviser_id) = this.reward_;  % For tracking metrics
                    reject_count(adviser_id) =  1;             % For tracking metrics
                elseif (action == this.cease_advice_)
                    cease_K_norm = cease_K_norm + K_hat_norm;
                    
                    cease_reward(adviser_id) =  this.reward_;     % For tracking metrics
                    cease_count(adviser_id) = 1;                  % For tracking metrics
                else
                    warning('Invalid advice action. Action=%d', action)
                end
                
                % Update adviser acceptance rate
                %accepted = (action == this.accept_);
                %this.adviser_accept_rate_(adviser_id) = this.accept_rate_alpha_*this.adviser_accept_rate_(adviser_id) + (1 - this.accept_rate_alpha_)*accepted;
                this.adviser_accept_rate_(adviser_id) = this.accept_rate_alpha_*this.adviser_accept_rate_(adviser_id) + (1 - this.accept_rate_alpha_)*delta_K;
            end
            
            % Update ask count
            this.ask_ratio_ = this.ask_ratio_alpha_*this.ask_ratio_ + (1 - this.ask_ratio_alpha_)*(ask_count/this.max_advisers_);
            
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
            this.advice_data_.a_enh.K_o_norm_iter(this.iters_) = K_o_norm_initial;
            this.advice_data_.a_enh.K_hat_norm_iter(this.iters_) = K_hat_norm;
            this.advice_data_.a_enh.delta_K_iter(this.iters_) = K_hat_norm - K_o_norm_initial;
            this.advice_data_.a_enh.beta_hat_iter(this.iters_) = K_hat'*K_o_initial;
            this.advice_data_.a_enh.max_p_a_in_iter(this.iters_) = max(p_o);
            this.advice_data_.a_enh.max_p_a_out_iter(this.iters_) = max(action_prob);
            this.advice_data_.a_enh.ask_count_iter(this.iters_) = ask_count;
            this.advice_data_.a_enh.accept_rates_iter(:, this.iters_) = this.adviser_accept_rate_;
            this.advice_data_.a_enh.accept_ratio_iter(:, this.iters_) = accept_count;
            this.advice_data_.a_enh.reject_ratio_iter(:, this.iters_) = reject_count;
            this.advice_data_.a_enh.cease_ratio_iter(:, this.iters_) = cease_count;
            this.advice_data_.a_enh.accept_delta_K_iter(:, this.iters_) = accept_delta_K;
            this.advice_data_.a_enh.accept_beta_hat_iter(:, this.iters_) = A_count;%accept_beta_hat;
            this.advice_data_.a_enh.reject_delta_K_iter(:, this.iters_) = reject_delta_K;
            this.advice_data_.a_enh.reject_beta_hat_iter(:, this.iters_) = B_count;%reject_beta_hat;
            this.advice_data_.a_enh.cease_K_norm_iter(:, this.iters_) = cease_K_norm;
            this.advice_data_.a_enh.accept_reward_iter(:, this.iters_) = accept_reward;
            this.advice_data_.a_enh.reject_reward_iter(:, this.iters_) = reject_reward;
            this.advice_data_.a_enh.cease_reward_iter(:, this.iters_) = cease_reward;
            this.advice_data_.a_enh.reward_iter(:, this.iters_) = this.reward_/(ask_count + 1);
            this.advice_data_.a_enh.ask_ratio_factor_iter(:, this.iters_) = this.ask_ratio_factor_;
            
            this.postAdviceUpdate();
            
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
        %   resetForNextRun
        %
        %   Resets all tracking metrics for the next run
        
        function resetForNextRun(this)            
            % Save epoch data
            num_iters = this.iters_ - this.epoch_start_iters_ + 1;
            
            this.advice_data_.a_enh.K_o_norm_epoch(this.epoch_) = sum(this.advice_data_.a_enh.K_o_norm_iter(this.epoch_start_iters_:this.iters_))/num_iters;
            this.advice_data_.a_enh.K_hat_norm_epoch(this.epoch_) = sum(this.advice_data_.a_enh.K_hat_norm_iter(this.epoch_start_iters_:this.iters_))/num_iters;
            this.advice_data_.a_enh.delta_K_epoch(this.epoch_) = sum(this.advice_data_.a_enh.delta_K_iter(this.epoch_start_iters_:this.iters_))/num_iters;
            this.advice_data_.a_enh.beta_hat_epoch(this.epoch_) = sum(this.advice_data_.a_enh.beta_hat_iter(this.epoch_start_iters_:this.iters_))/num_iters;
            this.advice_data_.a_enh.max_p_a_in_epoch(this.epoch_) = sum(this.advice_data_.a_enh.max_p_a_in_iter(this.epoch_start_iters_:this.iters_))/num_iters;
            this.advice_data_.a_enh.max_p_a_out_epoch(this.epoch_) = sum(this.advice_data_.a_enh.max_p_a_out_iter(this.epoch_start_iters_:this.iters_))/num_iters;
            this.advice_data_.a_enh.ask_count_epoch(this.epoch_) = sum(this.advice_data_.a_enh.ask_count_iter(this.epoch_start_iters_:this.iters_))/num_iters;
            this.advice_data_.a_enh.accept_rates_epoch(:, this.epoch_) = sum(this.advice_data_.a_enh.accept_rates_iter(:, this.epoch_start_iters_:this.iters_), 2)/num_iters;
            this.advice_data_.a_enh.accept_ratio_epoch(:, this.epoch_) = sum(this.advice_data_.a_enh.accept_ratio_iter(:, this.epoch_start_iters_:this.iters_), 2)/num_iters;
            this.advice_data_.a_enh.reject_ratio_epoch(:, this.epoch_) = sum(this.advice_data_.a_enh.reject_ratio_iter(:, this.epoch_start_iters_:this.iters_), 2)/num_iters;
            this.advice_data_.a_enh.cease_ratio_epoch(:, this.epoch_) = sum(this.advice_data_.a_enh.cease_ratio_iter(:, this.epoch_start_iters_:this.iters_), 2)/num_iters;
            this.advice_data_.a_enh.accept_delta_K_epoch(:, this.epoch_) = sum(this.advice_data_.a_enh.accept_delta_K_iter(:, this.epoch_start_iters_:this.iters_), 2)/num_iters;
            this.advice_data_.a_enh.accept_beta_hat_epoch(:, this.epoch_) = sum(this.advice_data_.a_enh.accept_beta_hat_iter(:, this.epoch_start_iters_:this.iters_), 2)/num_iters;
            this.advice_data_.a_enh.reject_delta_K_epoch(:, this.epoch_) = sum(this.advice_data_.a_enh.reject_delta_K_iter(:, this.epoch_start_iters_:this.iters_), 2)/num_iters;
            this.advice_data_.a_enh.reject_beta_hat_epoch(:, this.epoch_) = sum(this.advice_data_.a_enh.reject_beta_hat_iter(:, this.epoch_start_iters_:this.iters_), 2)/num_iters;
            this.advice_data_.a_enh.cease_K_norm_epoch(:, this.epoch_) = sum(this.advice_data_.a_enh.cease_K_norm_iter(:, this.epoch_start_iters_:this.iters_), 2)/num_iters;
            this.advice_data_.a_enh.accept_reward_epoch(:, this.epoch_) = sum(this.advice_data_.a_enh.accept_reward_iter(:, this.epoch_start_iters_:this.iters_), 2)/num_iters;
            this.advice_data_.a_enh.reject_reward_epoch(:, this.epoch_) = sum(this.advice_data_.a_enh.reject_reward_iter(:, this.epoch_start_iters_:this.iters_), 2)/num_iters;
            this.advice_data_.a_enh.cease_reward_epoch(:, this.epoch_) = sum(this.advice_data_.a_enh.cease_reward_iter(:, this.epoch_start_iters_:this.iters_), 2)/num_iters;
            this.advice_data_.a_enh.reward_epoch(this.epoch_) = sum(this.advice_data_.a_enh.reward_iter(this.epoch_start_iters_:this.iters_))/num_iters;
            this.advice_data_.a_enh.ask_ratio_factor_epoch(this.epoch_) = sum(this.advice_data_.a_enh.ask_ratio_factor_iter(this.epoch_start_iters_:this.iters_))/num_iters;

            this.epoch_start_iters_ = this.iters_;

            % Increment epochs
            this.epoch_ = this.epoch_ + 1;
            this.data_initialized_ = false;
        end
                        
    end
    
end

