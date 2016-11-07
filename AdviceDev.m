classdef AdviceDev < Advice
    % AdviceDev - Developmental advice mechanism
    
    properties
        % Configuration properties
        num_robot_actions_ = [];
        
        % Advice learning properties
        q_learning_ = [];             % Q-learning object
        learning_initialized_ = [];   % Flag for learning initialized
        e_greedy_epsilon_ = [];
        state_resolution_ = [];       % Discritization of states
        short_decay_rate_ = [];
        long_decay_rate_ = [];
        local_avg_factor_ = [];
        sigmoid_coeff_ = [];
        state_encoded_ = [];          % State vector
        prev_state_encoded_ = [];     % Previous state vector
        il_softmax_temp_ = [];        % Temp setting for IL softmax distribution 
        h_max_ = [];                  % Maximum possible IL entropy
        accept_advice_ = [];          % If the advice is being accepted
        epoch_start_iters_ = [];      % For saving epoch data
        
        % Advisor data
        evil_advisor_ = [];
        advisor_q_ = [];
        advisor_h_ = [];
        advisor_q_learning_ = [];
        advisor_avg_q_ = [];
        advisor_local_avg_ = [];
        advisee_avg_q_ = [];
        advisee_local_avg_ = [];
        
        prev_max_q_ = [];
        pride_ = [];
        prev_pride_ = [];
        advised_actions_ratio_ = [];
    end
    
    methods
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %   Constructor
        %
        %   Loads in configuration data and a copy of each robot to add
        %   listeners, and initializes properties.
        
        function this = AdviceDev (config, id)
            % Pass arguments to superclass
            this@Advice(config, id);
            
            this.num_robot_actions_ = config.num_actions;
            this.il_softmax_temp_ = config.softmax_temp;
            this.h_max_ =  -config.num_actions*(1/config.num_actions)*log2(1/config.num_actions);
            this.short_decay_rate_ = config.a_dev_short_decay_rate;
            this.long_decay_rate_ = config.a_dev_long_decay_rate;
            this.e_greedy_epsilon_ = config.a_dev_e_greedy_epsilon;
            this.local_avg_factor_ = config.a_dev_local_avg_factor;
            this.sigmoid_coeff_ = config.a_dev_sigmoid_coeff;
            this.evil_advisor_ = config.a_dev_evil_advisor;
            
            % Initialize Q-learning
            this.state_resolution_ = config.a_dev_state_resolution;
            num_state_vrbls = length(this.state_resolution_);
            num_actions = 2;
            this.q_learning_ = QLearning(config.a_dev_gamma, config.a_dev_alpha_denom, ...
                                        config.a_dev_alpha_power, config.a_dev_alpha_max, ...
                                        num_state_vrbls, this.state_resolution_, ...
                                        num_actions);

            this.state_encoded_ = zeros(1, num_state_vrbls);
            this.prev_state_encoded_ = zeros(1, num_state_vrbls);
            this.accept_advice_ = 1;
            this.prev_max_q_ = 0;
            this.pride_ = 0;
            this.prev_pride_ = 0;
            this.advised_actions_ratio_ = 0.5;
            
            % Load the advisor data
            file = config.a_dev_expert_filename;
            load(['advisor_data/', file, '/h.mat']);
            load(['advisor_data/', file, '/q.mat']);
            load(['advisor_data/', file, '/q_table.mat']);
            this.advisor_h_ = h;
            this.advisor_q_ = q;
            this.advisor_q_learning_ = QLearning(0, 0, 0, 0, config.num_state_vrbls, config.state_resolution, config.num_actions);
            this.advisor_q_learning_.q_table_ = q_table;
            
            % Initialize advisor metrics
            this.advisor_avg_q_ = 0;
            this.advisor_local_avg_ = 0;
            this.advisee_avg_q_ = 0;
            this.advisee_local_avg_ = 0;
            
            % Initialize structure for data to save
            this.advice_data_.a_dev.avg_q_iter = 0;
            this.advice_data_.a_dev.local_avg_iter = 0;
            this.advice_data_.a_dev.delta_q_iter = 0;
            this.advice_data_.a_dev.delta_h_iter = 0;
            this.advice_data_.a_dev.reward_iter = 0;
            this.advice_data_.a_dev.accept_q_iter = 0;
            this.advice_data_.a_dev.reject_q_iter = 0;
            this.advice_data_.a_dev.num_states_visited_iter = 0;
            this.advice_data_.a_dev.advisor_avg_q_iter = 0;
            this.advice_data_.a_dev.advisor_local_avg_iter = 0;
            this.advice_data_.a_dev.advice_state_val_iter = 0;
            this.advice_data_.a_dev.pride_iter = 0;
            this.advice_data_.a_dev.advised_actions_ratio_iter = 0;
            
            this.advice_data_.a_dev.avg_q_epoch = 0;
            this.advice_data_.a_dev.local_avg_epoch = 0;
            this.advice_data_.a_dev.delta_q_epoch = 0;
            this.advice_data_.a_dev.delta_h_epoch = 0;
            this.advice_data_.a_dev.reward_epoch = 0;
            this.advice_data_.a_dev.accept_q_epoch = 0;
            this.advice_data_.a_dev.reject_q_epoch = 0;
            this.advice_data_.a_dev.num_states_visited_epoch = 0;
            this.advice_data_.a_dev.advisor_avg_q_epoch = 0;
            this.advice_data_.a_dev.advisor_local_avg_epoch = 0;
            this.advice_data_.a_dev.advice_state_val_epoch = 0;
            this.advice_data_.a_dev.pride_epoch = 0;
            this.advice_data_.a_dev.advised_actions_ratio_epoch = 0;
            
            this.epoch_start_iters_ = 1;
        end
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %   getAdvice
        %
        %   Evaluates the entropy of the quality values for this robot, and
        %   all potential advisors. At each iteration an advisor is
        %   selected based on their quality entropy. Q-learning is
        %   performed on the advisors, where the input state is their
        %   quality entropy, and the reward is dependent on the change in
        %   quality of the advisee robot.
        %
        %   INPUTS:
        %   quality_in = Vector of quality values for this robots state
        %
        %   OUTPUTS:
        %   quality_out = Advised quality values
        
        function quality_out = getAdvice(this, state_vector, quality_in)
            % Prepare data
            this.preAdviceUpdate();
            
            % Get advice from advisor
            advice = this.advisor_q_learning_.getUtility(state_vector);
            if (this.evil_advisor_)
                % Rearrange the vector so the best action, is now the
                % worst, and the worst is now the best
                advice = min(advice) + max(advice) - advice;               
            end
            advice_prob = exp(advice/this.il_softmax_temp_)/sum(exp(advice/this.il_softmax_temp_));
            advice_h = -sum(advice_prob.*log2(advice_prob));
            
            % Update advisor metrics
            this.advisor_avg_q_ = this.long_decay_rate_*this.advisor_avg_q_ + (1 - this.long_decay_rate_)*this.advisor_q_(this.iters_);            
            this.advisor_local_avg_ = this.short_decay_rate_*this.advisor_local_avg_ + (1 - this.short_decay_rate_)*advice_h;            
            this.advice_data_.a_dev.advisor_avg_q_iter(this.iters_) = this.advisor_avg_q_;
            this.advice_data_.a_dev.advisor_local_avg_iter(this.iters_) = this.advisor_local_avg_;
            
            % Get advisee's avg quality 
            avg_q = this.requestData(this.id_, 'avg_quality_decaying');
            this.advice_data_.a_dev.avg_q_iter(this.iters_) = avg_q;            
            
            % Get advisee's local metric
            action_prob = exp(quality_in/this.il_softmax_temp_)/sum(exp(quality_in/this.il_softmax_temp_));
            my_h = -sum(action_prob.*log2(action_prob));
            this.advisee_local_avg_ = this.short_decay_rate_*this.advisee_local_avg_ + (1 - this.short_decay_rate_)*my_h;  
            this.advice_data_.a_dev.local_avg_iter(this.iters_) = this.advisee_local_avg_;
            
            % Determine alpha coefficients for advisee and advisor
            alpha_advisee = 1 - (this.advisee_local_avg_/this.h_max_ - 0.5)*2*this.local_avg_factor_;
            alpha_advisor = 1 - (this.advisor_local_avg_/this.h_max_ - 0.5)*2*this.local_avg_factor_;
            
            % Form state
            difference = alpha_advisor*this.advisor_avg_q_ - alpha_advisee*avg_q;
            state_value = 1/(1 + exp(-this.sigmoid_coeff_*difference));
            
            [~, best_advised_action] = max(advice);
            [~, best_self_action] = max(quality_in);
            same_action = (best_advised_action == best_self_action);
            
            this.prev_state_encoded_ = this.state_encoded_;
            this.state_encoded_ = [ceil(state_value*this.state_resolution_(1)) - 1, same_action];
            
            this.advice_data_.a_dev.advice_state_val_iter(this.iters_) = state_value;
                        
            % Learn from previous advice
            if (this.learning_initialized_)                
                % Get change in individual learning quality
                delta_q = this.requestData(this.id_, 'delta_q');
                this.advice_data_.a_dev.delta_q_iter(this.iters_ - 1:this.iters_) = [delta_q, 0];
                
                % Get change in entropy of individual learning quality
                delta_h = this.requestData(this.id_, 'delta_h');
                this.advice_data_.a_dev.delta_h_iter(this.iters_ - 1:this.iters_) = [delta_h, 0];
                                
                % Determine reward
                reward = this.pride_;
                
                % DEVELOPMENT
                %{
                if (this.pride_ > 0)
                    reward = (1 - this.advised_actions_ratio_)*this.pride_;
                else
                    reward = this.advised_actions_ratio_*this.pride_;
                end
                %}
                %{
                if (this.pride_ > 0)
                    reward = 1;
                else
                    reward = -1;
                end
                %}
                
                this.advice_data_.a_dev.reward_iter(this.iters_ - 1:this.iters_) = [reward, 0];
                                
                % Q-learning update
                this.q_learning_.learn(this.prev_state_encoded_, this.state_encoded_, this.accept_advice_, reward);
            else
                this.learning_initialized_ = true;
            end
                        
            this.prev_max_q_ = max(quality_in);
            
            % How many states have been visited
            this.advice_data_.a_dev.num_states_visited_iter(this.iters_) = nnz(this.q_learning_.q_table_);
            
            % Get advice quality
            % 1 = Accept Advice
            % 2 = Reject Advice
            quality = this.q_learning_.getUtility(this.state_encoded_);
            this.advice_data_.a_dev.accept_q_iter(this.iters_) = quality(1);
            this.advice_data_.a_dev.reject_q_iter(this.iters_) = quality(2);
            
            % Select with e-greedy policy
            if (rand < this.e_greedy_epsilon_)
                % Random
                this.accept_advice_ = round(rand) + 1;
            else
                [~, this.accept_advice_] = max(quality);
            end
            
            % DEVELOPMENT
            %this.accept_advice_ = 1;
            
            % Receive advice
            if (this.accept_advice_ == 1)
                quality_out = advice;
                this.advisor_id_ = this.id_ + 1;
            else
                quality_out = quality_in;
                this.advisor_id_ = this.id_;
            end
            
            % DEVELOPMENT
            %this.advisor_id_ = this.id_;
            
            % Pride calculation
            this.prev_pride_ = this.pride_;
            [~, best_action] = max(quality_in);
            if (this.accept_advice_ == 1)
                this.pride_ = advice(best_action) - quality_in(best_action);
            else
                this.pride_ = quality_in(best_action) - advice(best_action);
            end
            
            % DEVELOPMENT
            %this.pride_ = (this.pride_ > 0) - (this.pride_ <= 0);
            %this.advice_data_.a_dev.pride_iter(this.iters_) = this.long_decay_rate_*this.prev_pride_ + (1 - this.long_decay_rate_)*this.pride_;
            
            this.advice_data_.a_dev.pride_iter(this.iters_) = this.pride_;
            
            % Advised actions ratio            
            this.advised_actions_ratio_ = this.long_decay_rate_*this.advised_actions_ratio_ + (1 - this.long_decay_rate_)*(2 - this.accept_advice_);
            this.advice_data_.a_dev.advised_actions_ratio_iter(this.iters_) = this.advised_actions_ratio_;
                                    
            this.postAdviceUpdate();
        end
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %   resetForNextRun
        %
        %   Resets all tracking metrics for the next run
        
        function resetForNextRun(this)            
            % Save epoch data
            num_iters = this.iters_ - this.epoch_start_iters_ + 1;
            
            this.advice_data_.a_dev.avg_q_epoch(this.epoch_) = sum(this.advice_data_.a_dev.avg_q_iter(this.epoch_start_iters_:this.iters_))/num_iters;
            this.advice_data_.a_dev.local_avg_epoch(this.epoch_) = sum(this.advice_data_.a_dev.local_avg_iter(this.epoch_start_iters_:this.iters_))/num_iters;
            this.advice_data_.a_dev.delta_q_epoch(this.epoch_) = sum(this.advice_data_.a_dev.delta_q_iter(this.epoch_start_iters_:this.iters_))/num_iters;
            this.advice_data_.a_dev.delta_h_epoch(this.epoch_) = sum(this.advice_data_.a_dev.delta_h_iter(this.epoch_start_iters_:this.iters_))/num_iters;
            this.advice_data_.a_dev.reward_epoch(this.epoch_) = sum(this.advice_data_.a_dev.reward_iter(this.epoch_start_iters_:this.iters_))/num_iters;
            this.advice_data_.a_dev.accept_q_epoch(this.epoch_) = sum(this.advice_data_.a_dev.accept_q_iter(this.epoch_start_iters_:this.iters_))/num_iters;
            this.advice_data_.a_dev.reject_q_epoch(this.epoch_) = sum(this.advice_data_.a_dev.reject_q_iter(this.epoch_start_iters_:this.iters_))/num_iters;
            this.advice_data_.a_dev.num_states_visited_epoch(this.epoch_) = nnz(this.q_learning_.q_table_);
            this.advice_data_.a_dev.advisor_avg_q_epoch(this.epoch_) = sum(this.advice_data_.a_dev.advisor_avg_q_iter(this.epoch_start_iters_:this.iters_))/num_iters;
            this.advice_data_.a_dev.advisor_local_avg_epoch(this.epoch_) = sum(this.advice_data_.a_dev.advisor_local_avg_iter(this.epoch_start_iters_:this.iters_))/num_iters;
            this.advice_data_.a_dev.advice_state_val_epoch(this.epoch_) = sum(this.advice_data_.a_dev.advice_state_val_iter(this.epoch_start_iters_:this.iters_))/num_iters;
            this.advice_data_.a_dev.pride_epoch(this.epoch_) = sum(this.advice_data_.a_dev.pride_iter(this.epoch_start_iters_:this.iters_))/num_iters;
            this.advice_data_.a_dev.advised_actions_ratio_epoch(this.epoch_) = sum(this.advice_data_.a_dev.advised_actions_ratio_iter(this.epoch_start_iters_:this.iters_))/num_iters;

            this.epoch_start_iters_ = this.iters_;
            
            % Increment epochs
            this.epoch_ = this.epoch_ + 1;
            this.data_initialized_ = false;
        end
                        
    end
    
end

