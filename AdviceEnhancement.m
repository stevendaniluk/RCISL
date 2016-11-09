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
            
            % Initialize mechanism properties
            this.eps_ = 1/this.num_robot_actions_;            
            this.epoch_start_iters_ = 1;
            
            % Advice data being recorded
            this.advice_data_.a_enh.k_o_bar_iter = 0;
            this.advice_data_.a_enh.k_hat_bar_iter = 0;
            this.advice_data_.a_enh.delta_k_iter = 0;
            this.advice_data_.a_enh.beta_m_iter = 0;
            this.advice_data_.a_enh.beta_hat_iter = 0;
            this.advice_data_.a_enh.max_p_a_in_iter = 0;
            this.advice_data_.a_enh.max_p_a_out_iter = 0;
            
            this.advice_data_.a_enh.k_o_bar_epoch = 0;
            this.advice_data_.a_enh.k_hat_bar_epoch = 0;
            this.advice_data_.a_enh.delta_k_epoch = 0;
            this.advice_data_.a_enh.beta_m_epoch = 0;
            this.advice_data_.a_enh.beta_hat_epoch = 0;
            this.advice_data_.a_enh.max_p_a_in_epoch = 0;
            this.advice_data_.a_enh.max_p_a_out_epoch = 0;
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
            
            % Get knowledge from each agent
            k_vals = zeros(this.num_robots_, this.num_robot_actions_);
            for i = 1:this.num_robots_
                if i == this.id_
                    q = quality_in;
                else
                    adviser_handle = this.requestData(i, 'robot_handle');
                    [q, ~] = adviser_handle.individual_learning_.q_learning_.getUtility(state_vector);
                end
                
                % Convert to action selection probability
                p_a = exp(q/this.il_softmax_temp_)/sum(exp(q/this.il_softmax_temp_));
                
                % Convert to knowledge values
                k_denom = 1 - this.eps_;
                k_vals(i,:) = abs(p_a - this.eps_).*(p_a - this.eps_)/k_denom;
            end
            
            % From knowledge vectors
            k_o = k_vals(this.id_, :);
            k_o_bar = sum(abs(k_o));
            
            k_m = sum(k_vals, 1) - k_o;
            k_m_bar = sum(abs(k_m), 2);
            beta_m = k_m*k_o';
            
            % Enhance knowledge
            k_hat = (k_o + k_m)/(1 + k_m_bar);
            k_hat_bar = sum(abs(k_hat));
            beta_hat = k_hat*k_o';
            delta_k = k_hat_bar - k_o_bar;
                                                
            % Convert from K values to action selection probability
            p_a_new = this.eps_ + sign(k_hat).*sqrt((1 - this.eps_)*abs(k_hat));
            action_prob = p_a_new/sum(p_a_new);
            
            rand_action = rand;
            for i=1:length(k_hat)
                if (rand_action < sum(action_prob(1:i)))
                    action_id = i;
                    break;
                elseif (i == this.config_.num_actions)
                    action_id = i;
                end
            end
            
            % Get action probability matrics
            max_p_a_in = max(exp(quality_in/this.il_softmax_temp_)/sum(exp(quality_in/this.il_softmax_temp_)));
            max_p_a_out = max(action_prob);
                              
            % Record tracking metrics
            this.advice_data_.a_enh.k_o_bar_iter(this.iters_) = k_o_bar;
            this.advice_data_.a_enh.k_hat_bar_iter(this.iters_) = k_hat_bar;
            this.advice_data_.a_enh.delta_k_iter(this.iters_) = delta_k;
            this.advice_data_.a_enh.beta_m_iter(this.iters_) = beta_m;
            this.advice_data_.a_enh.beta_hat_iter(this.iters_) = beta_hat;
            this.advice_data_.a_enh.max_p_a_in_iter(this.iters_) = max_p_a_in;
            this.advice_data_.a_enh.max_p_a_out_iter(this.iters_) = max_p_a_out;
            
            this.postAdviceUpdate();
            
            % Output the result
            result = action_id;
        end
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %   resetForNextRun
        %
        %   Resets all tracking metrics for the next run
        
        function resetForNextRun(this)            
            % Save epoch data
            num_iters = this.iters_ - this.epoch_start_iters_ + 1;
            this.advice_data_.a_enh.k_o_bar_epoch(this.epoch_) = sum(this.advice_data_.a_enh.k_o_bar_iter(this.epoch_start_iters_:this.iters_))/num_iters;
            this.advice_data_.a_enh.k_hat_bar_epoch(this.epoch_) = sum(this.advice_data_.a_enh.k_hat_bar_iter(this.epoch_start_iters_:this.iters_))/num_iters;
            this.advice_data_.a_enh.delta_k_epoch(this.epoch_) = sum(this.advice_data_.a_enh.delta_k_iter(this.epoch_start_iters_:this.iters_))/num_iters;
            this.advice_data_.a_enh.beta_m_epoch(this.epoch_) = sum(this.advice_data_.a_enh.beta_m_iter(this.epoch_start_iters_:this.iters_))/num_iters;
            this.advice_data_.a_enh.beta_hat_epoch(this.epoch_) = sum(this.advice_data_.a_enh.beta_hat_iter(this.epoch_start_iters_:this.iters_))/num_iters;
            this.advice_data_.a_enh.max_p_a_in_epoch(this.epoch_) = sum(this.advice_data_.a_enh.max_p_a_in_iter(this.epoch_start_iters_:this.iters_))/num_iters;
            this.advice_data_.a_enh.max_p_a_out_epoch(this.epoch_) = sum(this.advice_data_.a_enh.max_p_a_out_iter(this.epoch_start_iters_:this.iters_))/num_iters;

            this.epoch_start_iters_ = this.iters_;

            % Increment epochs
            this.epoch_ = this.epoch_ + 1;
            this.data_initialized_ = false;
        end
                        
    end
    
end

