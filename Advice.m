classdef Advice < handle
    % Advice - Advice sharing mechanism for RCISL
    
    properties
        % Configuration settings
        config_ = [];
        mechanism_ = [];
        num_robots_ = [];
        robots_ = [];
        id_ = [];
        iters_ = [];
        epoch_ = [];
        num_state_vrbls_ = [];
        
        % Advisor Properties
        advisor_handle_ = [];
        advisor_id_ = [];
        prev_advisor_id_ = [];
        advisor_quality_ = [];
        
        % Entropy parameters
        entropy_q_learning_ = [];
        entropy_state_bits_ = [];
        il_softmax_temp_ = [];
        entropy_softmax_temp_ = [];     % Temp setting for softmax distribution
        entropy_max_ = [];
        entropy_state_ = [];
        prev_entropy_state_ = [];
        initialized_ = [];
        
        % Advice Exchange Parameters
        ae_alpha_ = [];        % Coefficient for current average quality update
        ae_beta_ = [];         % Coefficient for best average quality update
        ae_delta_ = [];        % Coefficient for quality comparison
        ae_rho_ = [];          % Coefficient for quality comparison
        cq_ = [];              % Realtive current average quality
        best_cq_ = [];         % Best value for cq, and robot id
        bq_ = [];              % Relative best average quality
        best_bq_ = [];         % Best value for bq, and robot id
                
        
        % Structure of data to save
        advice_data_ = [];
        
        % Properties accessed by AdviceDatabase class
        request_data_ = []; % List of parameters to be ready by AdviceDatabase
        data_return_ = [];  % Array of data written by AdviceDatabase
        store_data_ = [];   % Map of data for AdviceDatabase to read and store
        
    end

    events
        RequestData;
        StoreData;
    end
    
    methods
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %   Constructor
        %
        %   Loads in configuration data and a copy of each robot to add
        %   listeners, and initializes properties.
        
        function this = Advice (config, id)
            % General parameters
            this.config_ = config;
            this.mechanism_ = config.advice_mechanism;
            this.id_ = id;
            this.num_robots_ = config.numRobots;
            this.iters_ = 0;
            this.epoch_ = 1;
            this.num_state_vrbls_ = config.num_state_vrbls;
            this.advisor_id_ = this.id_;
            this.initialized_ = false;
            
            % Initialize structure for data to save
            this.advice_data_.advisor = [];
            this.advice_data_.total_actions = 0;
            this.advice_data_.advised_actions = 0;
            this.advice_data_.advised_actions_ratio = [];
            this.advice_data_.ae.cond_a_true_count = 0;
            this.advice_data_.ae.cond_b_true_count = 0;
            this.advice_data_.ae.cond_c_true_count = 0;
            this.advice_data_.entropy.entropy = [];
            this.advice_data_.entropy.delta_q = [];
            
            % Set Entropy properties
            if (strcmp(this.mechanism_, 'entropy'))
                this.il_softmax_temp_ = config.softmax_temp;
                this.entropy_softmax_temp_ = config.entropy_softmax_temp;
                this.entropy_max_ =  -config.num_actions*(1/config.num_actions)*log2(1/config.num_actions);
                
                % Initialize Q-learning
                num_state_vrbls = 2;
                this.entropy_state_bits_ = config.entropy_state_bits;
                num_state_bits_ = [ceil(log2(this.num_robots_)), this.entropy_state_bits_];
                num_actions = 1;
                this.entropy_q_learning_ = QLearning(config.gamma, config.alpha_denom, ...
                                        config.alpha_power, config.alpha_max, ...
                                        num_state_vrbls, num_state_bits_, ...
                                        num_actions);
                
                this.entropy_state_ = (2^this.entropy_state_bits_ - 1)*ones(this.num_robots_, 1);
                this.prev_entropy_state_ = (2^this.entropy_state_bits_ - 1)*ones(this.num_robots_, 1);
            end
            
            % Initialize Advice Exchange Properties
            this.ae_alpha_ = config.ae_alpha;
            this.ae_beta_ = config.ae_beta;
            this.ae_delta_ = config.ae_delta;
            this.ae_rho_ = config.ae_rho;
            this.cq_ = 0;
            this.best_cq_ = struct('id', [], 'value', 0);
            this.bq_ = 0;
            this.best_bq_ = struct('id', [], 'value', 0);
            
        end
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %   getAdvice
        %
        %   Checks if this robot needs advice, by comparing its current and
        %   best average qualities to those of other robots, as well is
        %   checking if it is confused about its own state.
        %
        %   INPUTS:
        %   quality_in = Vector of quality values for this robots state
        %
        %   OUTPUTS:
        %   quality_out = Advised quality values
        
        function quality_out = getAdvice(this, state_vector, quality_in)
            
            % Update data
            this.iters_ = this.iters_ + 1;
            this.advice_data_.total_actions(this.epoch_) = this.advice_data_.total_actions(this.epoch_) + 1;
            this.prev_advisor_id_ = this.advisor_id_;
            
            % Get advice from selected mechanism
            if (strcmp(this.mechanism_, 'advice_exchange'))
                quality_out = this.adviceExchange(state_vector, quality_in);
            elseif (strcmp(this.mechanism_, 'entropy'))
                  quality_out = this.adviceEntropy(state_vector, quality_in);  
            end
            
            % Save advice data
            if (this.advisor_id_ ~= this.id_)
                this.advice_data_.advised_actions(this.epoch_) = this.advice_data_.advised_actions(this.epoch_) + 1;
            end
            this.advice_data_.advisor_(this.iters_) = this.advisor_id_;
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %   adviceEntropy
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
        
        function quality_out = adviceEntropy(this, state_vector, quality_in)
                        
            % Get individual learning quality values for each robot
            q_vals = zeros(this.num_robots_, this.num_state_vrbls_);
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
            entropy_vals = sum(-q_prob.*log2(q_prob), 2);
            
            % Convert entropy to state values
            % Map entropy value to between 0 and 2^entropy_state_bits_
            this.prev_entropy_state_ = this.entropy_state_;
            this.entropy_state_ = round((entropy_vals/this.entropy_max_)*(2^this.entropy_state_bits_ - 1));
            
            % Learn from previous advice
            if (this.initialized_)
                % Form states
                prev_advice_state = [this.prev_advisor_id_, this.prev_entropy_state_(this.prev_advisor_id_)];
                current_advice_state = [this.prev_advisor_id_, this.entropy_state_(this.prev_advisor_id_)];
                
                % Determine reward from change in quality (minus a small
                % amount for convergence)
                delta_quality = this.requestData(this.id_, 'delta_quality');
                reward = delta_quality - 0.0001;
                this.advice_data_.entropy.delta_q(this.iters_) = delta_quality;
                
                % Q-learning update
                this.entropy_q_learning_.learn(prev_advice_state, current_advice_state, 1, reward);
            else
                this.initialized_ = true;
            end
                        
            % Get advice quality for each advisor (based on their entropy)
            advisor_quality = zeros(this.num_robots_, 1);
            for i = 1:this.num_robots_
                state = [i, this.entropy_state_(i)];
                advisor_quality(i) = this.entropy_q_learning_.getUtility(state);
            end
            
            % Select advisor based on softmax distribution of advisor quality
            exponents = exp(advisor_quality/this.entropy_softmax_temp_);
            action_prob = exponents/sum(exponents);
            rand_action = rand;
            for i=1:this.num_robots_
                if (rand_action < sum(action_prob(1:i)))
                    action = i;
                    break;
                elseif (i == this.num_robots_)
                    action = i;
                end
            end
            this.advisor_id_ = action;
            
            % Accept advice
            quality_out = q_vals(this.advisor_id_, :);
            
            % Store the entropy data
            this.advice_data_.entropy.entropy(this.iters_) = entropy_vals(this.advisor_id_);
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %   adviceExchange
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
        
        function quality_out = adviceExchange(this, state_vector, quality_in)
            % Do nothing during the first epoch (need data first)
            if(this.epoch_ <= 1)
                quality_out = quality_in;
                return;
            end      
            
            % An advisor must have a better current average quality
            if (this.cq_ < this.best_cq_.value)
                
                % Advisor id
                this.advisor_id_ = this.best_cq_.id;
                this.advisor_handle_ = this.requestData(this.advisor_id_, 'robot_handle');
                [this.advisor_quality_, ~] = this.advisor_handle_.individual_learning_.q_learning_.getUtility(state_vector);
                
                % Compare this epochs current average quality, to advisors
                % relative current average quality
                avg_quality = this.requestData(this.id_, 'avg_quality');
                cond_a = avg_quality < (this.best_cq_.value - this.ae_delta_*this.best_cq_.value);
                
                % Compare best quality
                advisor_bq = this.requestData(this.advisor_id_, 'bq');
                cond_b = this.bq_ < advisor_bq;
                
                % Compare qualities for current action
                % NOT EVALUATED IN MATLABCISL FROM JUSTIN GIRARD
                % cond_c = sum(quality_in) < this.ae_rho_*sum(this.advisor_quality_);
                cond_c = true;
                
                % All conditions must be satisfied to give advice
                if (cond_a && cond_b && cond_c)
                    quality_out = this.advisor_quality_;
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
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %   requestData
        %
        %   Communicates with the AdviceDatabase to request data about a
        %   particular robot. A list of parameters is given, and their
        %   corresponding values for that robot are received.
        %
        %   INPUTS:
        %   id = Id number for robot of interest
        %   varagin = Strings with names of parameters to fetch
        %
        %   OUTPUTS:
        %   varagout = Array of values for input parameters
        
        function varargout = requestData(this, id, varargin)
            % Pack data to be observed by AdviceData
            this.request_data_{1, 1} = id;
            for i = 1:length(varargin)
                this.request_data_{i + 1, 1} = varargin{i};
            end
            
            % Send the request
            this.notify('RequestData');
            
            % Unpack data
            varargout = cell(1, length(varargin));
            for i = 1:length(varargin)
                varargout{i} = this.data_return_{i};
            end
        end
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %   storeData
        %
        %   Communicates with the AdviceDatabase to store data about a
        %   particular robot. A map of parameter names and values is given,
        %   which is then read by AdviceDataBase
        %
        %   INPUTS:
        %   id = Id number for robot of interest
        %   data_map = Map of parameter names and values to be stored
        
        function storeData(this, id, data_map)
            % Add id to the map
            data_map('id') = id;
            this.store_data_ = data_map;
           
            % Send the request
            this.notify('StoreData');
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
            avg_quality = this.requestData(this.id_, 'avg_quality');
            this.cq_ = (1 - this.ae_alpha_)*avg_quality + this.ae_alpha_*this.cq_;
            this.bq_ = max(avg_quality, this.ae_beta_*this.bq_);

            % Store our tracking metrics in the AdviceDatabase
            data_map = containers.Map;
            data_map('cq') = this.cq_;
            data_map('bq') = this.bq_;
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
            this.best_cq_.value = 0;
            this.best_cq_.id = [];
            for i = 1:this.num_robots_
                if (i ~= this.id_)
                    [cq, bq] = this.requestData(i, 'cq', 'bq');
                    
                    if (cq > this.best_cq_.value)
                        this.best_cq_.value = cq;
                        this.best_cq_.id = i;
                    end
                    
                    if (bq > this.best_bq_.value)
                        this.best_bq_.value = bq;
                        this.best_bq_.id = i;
                    end
                end
            end

        end
                
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %   resetTrackingMetrics
        %
        %   Resets all tracking metrics for the next run
        
        function resetTrackingMetrics (this)
            %{
            this.advice_data_.advised_actions_ratio(this.epoch_) = ... 
                this.advice_data_.advised_actions(this.epoch_) ...
                /this.advice_data_.total_actions(this.epoch_);
            %}
            % Increment epochs
            this.epoch_ = this.epoch_ + 1;
            
            % Allocate a spot in the arrays for next the epoch
            this.advice_data_.advised_actions_ratio_(1, this.epoch_) = 0;
            this.advice_data_.advised_actions(1, this.epoch_) = 0;
            this.advice_data_.total_actions(1, this.epoch_) = 0;
            this.advice_data_.ae.cond_a_true_count(1, this.epoch_) = 0;
            this.advice_data_.ae.cond_b_true_count(1, this.epoch_) = 0;
            this.advice_data_.ae.cond_c_true_count(1, this.epoch_) = 0;
        end
        
    end
    
end

