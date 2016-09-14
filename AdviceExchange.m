classdef AdviceExchange < Advice
    % AdviceExchange - Implements the Advice Exchange Algorithm from [Girard, 2015]
    
    % Tracks metrics about the advisee and each potential advisor, then
    % selects the agent with the highest best average quality as the
    % potential advisor and checks some conditions to determine if advice
    % should be accepted from this advisor or not.
    
    properties        
        % Advice Exchange properties
        alpha_ = [];        % Coefficient for current average quality update
        beta_ = [];         % Coefficient for best average quality update
        delta_ = [];        % Coefficient for quality comparison
        rho_ = [];          % Coefficient for quality comparison
        cq_ = [];           % Realtive current average quality
        bq_ = [];           % Relative best average quality
        best_bq_ = [];      % Best value for cq, and robot id
    end

    methods
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %   Constructor
        %
        %   Loads in configuration data and a copy of each robot to add
        %   listeners, and initializes properties.
        
        function this = AdviceExchange (config, id)
            % Pass arguments to superclass
            this@Advice(config, id);
                                    
            % Initialize Advice Exchange Properties
            this.alpha_ = config.ae_alpha;
            this.beta_ = config.ae_beta;
            this.delta_ = config.ae_delta;
            this.rho_ = config.ae_rho;
            this.cq_ = 0;
            this.bq_ = 0;
            this.best_bq_ = struct('id', [], 'value', 0);
            
            % Initialize structure for data to save
            this.advice_data_.ae.avg_q = 0;
            this.advice_data_.ae.cq = 0;
            this.advice_data_.ae.bq = 0;
            this.advice_data_.ae.cond_a_true_count = 0;
            this.advice_data_.ae.cond_b_true_count = 0;
            this.advice_data_.ae.cond_c_true_count = 0;
        end
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %   getAdvice
        %
        %   Implements the Advice Exchange algorithm, by comparing current
        %   average and best qualities, as well as the quality values of
        %   the current state, to potential advisor robots. Implemented
        %   according to [Girard, 2015].
        %
        %   NOTE: In MatlabCISL from Justin Girard, it appears that
        %   condition C is never evaluated.
        %
        %   INPUTS:
        %   quality_in = Vector of quality values for this robots state
        %
        %   OUTPUTS:
        %   quality_out = Advised quality values
        
        function quality_out = getAdvice(this, state_vector, quality_in)
            % Prepare data
            if(~this.data_initialized_)
                this.advice_data_.ae.avg_q(1, this.epoch_) = 0;
                this.advice_data_.ae.cq(1, this.epoch_) = 0;
                this.advice_data_.ae.bq(1, this.epoch_) = 0;
                this.advice_data_.ae.cond_a_true_count(1, this.epoch_) = 0;
                this.advice_data_.ae.cond_b_true_count(1, this.epoch_) = 0;
                this.advice_data_.ae.cond_c_true_count(1, this.epoch_) = 0;
            end
            this.preAdviceUpdate();
            
            % Do nothing during the first epoch (need data first)
            if(this.epoch_ <= 1)
                quality_out = quality_in;
                return;
            end      
            
            % An advisor must have a better current average quality
            if (this.cq_ < this.best_bq_.value)
                
                % Advisor id
                this.advisor_id_ = this.best_bq_.id;
                this.advisor_handle_ = this.requestData(this.advisor_id_, 'robot_handle');
                [advisor_quality_, ~] = this.advisor_handle_.individual_learning_.q_learning_.getUtility(state_vector);
                
                % Compare this epochs current average quality, to advisors
                % relative current average quality
                avg_quality = this.requestData(this.id_, 'epoch_avg_quality');
                cond_a = avg_quality < (this.best_bq_.value - this.delta_*this.best_bq_.value);
                
                % Compare best quality
                advisor_bq = this.requestData(this.advisor_id_, 'ae_bq');
                cond_b = this.bq_ < advisor_bq;
                
                % Compare qualities for current action
                % NOT EVALUATED IN MATLABCISL FROM JUSTIN GIRARD
                cond_c = sum(quality_in) < this.rho_*sum(advisor_quality_);
                
                % All conditions must be satisfied to give advice
                if (cond_a && cond_b && cond_c)
                    quality_out = advisor_quality_;
                else
                    quality_out = quality_in;
                    this.advisor_id_ = this.id_;
                end
                
                % Track how often each is true
                this.advice_data_.ae.cond_a_true_count(1, this.epoch_) = this.advice_data_.ae.cond_a_true_count(1, this.epoch_) + cond_a;
                this.advice_data_.ae.cond_b_true_count(1, this.epoch_) = this.advice_data_.ae.cond_b_true_count(1, this.epoch_) + cond_b;
                this.advice_data_.ae.cond_c_true_count(1, this.epoch_) = this.advice_data_.ae.cond_c_true_count(1, this.epoch_) + cond_c;
            else
                quality_out = quality_in;
                this.advisor_id_ = this.id_;
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
            this.advice_data_.ae.avg_q(1, this.epoch_) = epoch_avg_quality;
            this.advice_data_.ae.cq(1, this.epoch_) = this.cq_;
            this.advice_data_.ae.bq(1, this.epoch_) = this.bq_;
            
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

