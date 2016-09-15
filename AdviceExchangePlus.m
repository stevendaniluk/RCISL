classdef AdviceExchangePlus < Advice
    % AdviceExchangePlus - Learning version of Advice Exchange Algorithm
    
    % Tracks metrics about the advisee and each potential advisor, and
    % learns when to accept or reject advice based on these metrics.
        
    properties
        % Configuration properties
        expert_on_ = [];
        expert_id_ = [];
        
        % Advice Exchange properties
        alpha_ = [];        % Coefficient for current average quality update
        beta_ = [];         % Coefficient for best average quality update
        delta_ = [];        % Coefficient for quality comparison
        rho_ = [];          % Coefficient for quality comparison
        cq_ = [];           % Realtive current average quality
        bq_ = [];           % Relative best average quality
        best_bq_ = [];      % Best value for cq, and robot id
        
        % Advice learning properties
        q_learning_ = [];             % Q-learning object
        learning_initialized_ = [];   % Flag for learning initialized
        state_resolution_ = [];       % Discritization of states
        state_encoded_ = [];          % State vector
        prev_state_encoded_ = [];     % Previous state vector
        advice_softmax_temp_ = [];    % Temp setting for advce softmax distribution
        accept_advice_ = [];          % If the advice is being accepted
    end

    methods
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %   Constructor
        %
        %   Loads in configuration data and a copy of each robot to add
        %   listeners, and initializes properties.
        
        function this = AdviceExchangePlus (config, id)
            % Pass arguments to superclass
            this@Advice(config, id);
            
            this.expert_on_ = config.expert_on;
            this.expert_id_ = config.expert_id;
            this.advice_softmax_temp_ = config.aep_softmax_temp;
            
            % Initialize Q-learning
            this.state_resolution_ = config.aep_state_resolution;
            num_state_vrbls = length(this.state_resolution_);
            num_actions = 2;
            this.q_learning_ = QLearning(config.aep_gamma, config.aep_alpha_denom, ...
                                        config.aep_alpha_power, config.aep_alpha_max, ...
                                        num_state_vrbls, this.state_resolution_, ...
                                        num_actions);

            this.state_encoded_ = zeros(1, num_state_vrbls);
            this.prev_state_encoded_ = zeros(1, num_state_vrbls);
                                    
            % Initialize Advice Exchange Properties
            this.alpha_ = config.ae_alpha;
            this.beta_ = config.ae_beta;
            this.delta_ = config.ae_delta;
            this.rho_ = config.ae_rho;
            this.cq_ = 0;
            this.bq_ = 0;
            this.best_bq_ = struct('id', [], 'value', 0);
            
            % Initialize structure for data to save
            this.advice_data_.aep.avg_q = 0;
            this.advice_data_.aep.cq = 0;
            this.advice_data_.aep.bq = 0;
            this.advice_data_.aep.delta_q = 0;
        end
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %   getAdvice
        %
        %   Implements the Advice Exchange Plus algorithm, which learns the
        %   conditions to accept advice with a Q-Learning algorithm
        %
        %   INPUTS:
        %   quality_in = Vector of quality values for this robots state
        %
        %   OUTPUTS:
        %   quality_out = Advised quality values
        
        function quality_out = getAdvice(this, state_vector, quality_in)
            % Prepare data
            if(~this.data_initialized_)
                this.advice_data_.aep.avg_q(1, this.epoch_) = 0;
                this.advice_data_.aep.cq(1, this.epoch_) = 0;
                this.advice_data_.aep.bq(1, this.epoch_) = 0;
            end
            this.preAdviceUpdate();
            
            % Do nothing during the first epoch (need data first)
            if(this.epoch_ <= 1)
                quality_out = quality_in;
                return;
            end
            
            % Select advisor
            if (this.expert_on_)
                % Default to expert
                this.advisor_id_ = this.expert_id_;
            else
                % Must select an advisor
                if (this.num_robots_ == 2)
                    % Advise each other
                    if (this.id_ == 1)
                        this.advisor_id_ = 2;
                    else
                        this.advisor_id_ = 1;
                    end
                else
                    % Randomly select an advisor
                    advisors = randperm(this.num_robots_);
                    advisors(advisors == this.id_) = [];
                    this.advisor_id_ = advisors(1);
                end
            end
            
            % Get matrics for the advisor
            advisor_cq = this.requestData(this.advisor_id_, 'ae_cq');
            advisor_bq = this.requestData(this.advisor_id_, 'ae_bq');
            
            % Get ratios and constrain to [0.5, 1.5]
            min_ratio = 0.5;
            max_ratio = 1.5;
            cq_ratio = min(max(advisor_cq/this.cq_, min_ratio), max_ratio);
            bq_ratio = min(max(advisor_bq/this.bq_, min_ratio), max_ratio);
            
            % Form state
            this.prev_state_encoded_ = this.state_encoded_;
            this.state_encoded_ = [floor((this.state_resolution_(1) - 1)*(cq_ratio - min_ratio)),...
                                   floor((this.state_resolution_(1) - 1)*(bq_ratio - min_ratio))];
            
            % Learn from previous advice
            if (this.learning_initialized_)                
                % Get change in individual learning quality
                delta_q = this.requestData(this.id_, 'delta_q');
                this.advice_data_.aep.delta_q(this.iters_) = delta_q;
                                                
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
            this.accept_advice_ = rand_action < action_prob(1);
            
            if (this.accept_advice_)
                this.advisor_handle_ = this.requestData(this.advisor_id_, 'robot_handle');
                [quality_out, ~] = this.advisor_handle_.individual_learning_.q_learning_.getUtility(state_vector);
            else
                this.advisor_id_ = this.id_;
                quality_out = quality_in;
            end
            
            this.postAdviceUpdate();
        end
        
                
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %   publishPerfMetrics
        %
        %   Updates our own tracking metrics when a training epoch is
        %   completed, then publishes them on the AdviceDatabase. To be
        %   called once after an epoch is completed.
        
        function publishPerfMetrics(this)
            % Update our own tracking metrics
            epoch_avg_quality = this.requestData(this.id_, 'epoch_avg_quality');
            this.cq_ = (1 - this.alpha_)*epoch_avg_quality + this.alpha_*this.cq_;
            this.bq_ = max(epoch_avg_quality, this.beta_*this.bq_);
            
            % Save the tracking metrics
            this.advice_data_.aep.avg_q(1, this.epoch_) = epoch_avg_quality;
            this.advice_data_.aep.cq(1, this.epoch_) = this.cq_;
            this.advice_data_.aep.bq(1, this.epoch_) = this.bq_;
            
            % Store our tracking metrics in the AdviceDatabase
            data_map = containers.Map;
            data_map('ae_cq') = this.cq_;
            data_map('ae_bq') = this.bq_;
            this.storeData(this.id_, data_map);
        end
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %   updateIndividualMetrics
        %
        %   Updates this robots individual tracking metrics by pulling the
        %   newly updated data about other robots. This finds the robots
        %   with the best cq and bq, updates the self confidence, then 
        %   publishes this data on the AdviceDatabase. To be called 
        %   after publishPerfMetrics.
        
        function updateIndividualMetrics (this)
            % Update the best tracking metrics of other robots
            this.best_bq_.value = 0;
            this.best_bq_.id = [];
            for i = 1:this.num_robots_
                if (i ~= this.id_)
                    [cq, bq] = this.requestData(i, 'ae_cq', 'ae_bq');
                    
                    if (cq > this.best_bq_.value)
                        this.best_bq_.value = cq;
                        this.best_bq_.id = i;
                    end
                    
                    if (bq > this.best_bq_.value)
                        this.best_bq_.value = bq;
                        this.best_bq_.id = i;
                    end
                end
            end

        end
                
    end
    
end

