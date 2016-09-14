classdef AdviceDev < Advice
    % AdviceDev - Developmental advice mechanism
    
    properties
        % Configuration properties
        num_robot_actions_ = [];
        
        % Advice learning properties
        q_learning_ = [];             % Q-learning object
        learning_initialized_ = [];   % Flag for learning initialized
        state_resolution_ = [];       % Discritization of states
        state_encoded_ = [];          % State vector
        prev_state_encoded_ = [];     % Previous state vector
        il_softmax_temp_ = [];        % Temp setting for IL softmax distribution  
        advice_softmax_temp_ = [];    % Temp setting for advce softmax distribution
        h_max_ = [];                  % Maximum possible IL entropy
        accept_advice_ = [];          % If the advice is being accepted
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
            this.advice_softmax_temp_ = config.a_dev_softmax_temp;
            this.h_max_ =  -config.num_actions*(1/config.num_actions)*log2(1/config.num_actions);
            
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
            
            % Initialize structure for data to save
            this.advice_data_.a_dev.h = 0;
            this.advice_data_.a_dev.delta_q = 0;
            this.advice_data_.a_dev.delta_h = 0;
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
            if(~this.data_initialized_)
                this.advice_data_.a_dev.h(1, this.epoch_) = 0;
                this.advice_data_.a_dev.delta_q(1, this.epoch_) = 0;
                this.advice_data_.a_dev.delta_h(1, this.epoch_) = 0;
            end
            this.preAdviceUpdate();
            
            % Get individual learning quality values for each robot
            q_vals = zeros(this.num_robots_, this.num_robot_actions_);
            for i = 1:this.num_robots_
                if (i == this.id_)
                    q_vals(i, :) = quality_in;
                else
                    robot_handle = this.requestData(i, 'robot_handle');
                    [q_vals(i, :), ~] = robot_handle.individual_learning_.q_learning_.getUtility(state_vector);
                end
            end
            
            % Evaluate entropy of quality values
            q_exponents = exp(q_vals/this.il_softmax_temp_);
            q_prob = bsxfun(@rdivide, q_exponents, sum(q_exponents, 2));
            h_vals = sum(-q_prob.*log2(q_prob), 2);
            
            % Randomly select advisor
            advisors = randperm(this.num_robots_);
            this.advisor_id_ = advisors(1);
            
            % Convert entropy to state values
            % Map entropy value to between 0 and state_resolution_
            this.prev_state_encoded_ = this.state_encoded_;
            this.state_encoded_ = round((h_vals(this.advisor_id_)/this.h_max_)*(this.state_resolution_ - 1));
            
            % Learn from previous advice
            if (this.learning_initialized_)                
                % Get change in individual learning quality
                delta_q = this.requestData(this.id_, 'delta_q');
                this.advice_data_.a_dev.delta_q(this.iters_) = delta_q;
                
                % Get change in entropy of individual learning quality
                delta_h = this.requestData(this.id_, 'delta_h');
                this.advice_data_.a_dev.delta_h(this.iters_) = delta_h;
                                
                % Determine reward from change in quality
                reward = delta_q;
                                
                % Q-learning update
                this.q_learning_.learn(this.prev_state_encoded_, this.state_encoded_, this.accept_advice_ + 1, reward);
            else
                this.learning_initialized_ = true;
            end
                        
            % Get advice quality
            quality = this.q_learning_.getUtility(this.state_encoded_);
            
            % Choose to accept advice or not
            exponents = exp(quality/this.advice_softmax_temp_);
            action_prob = exponents/sum(exponents);
            rand_action = rand;
            if (rand_action < action_prob(1))
                this.accept_advice_ = true;
            else
                this.accept_advice_ = false;
                this.advisor_id_ = this.id_;
            end
                  
            quality_out = q_vals(this.advisor_id_, :);
            
            % Store the entropy data
            this.advice_data_.a_dev.h(this.iters_) = h_vals(this.advisor_id_);
            
            this.postAdviceUpdate();
        end
                        
    end
    
end

