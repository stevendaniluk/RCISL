classdef Advice < handle
    % Advice - Advice sharing mechanism for RCISL
    
    properties
        % Configuration settings
        config_ = [];
        mechanism_ = [];
        num_robots_ = [];
        robots_ = [];
        id_ = [];
        epoch_ = [];
        
        % Advisor Properties
        advisor_handle_ = [];
        advisor_id_ = [];
        advisor_quality_ = [];
        
        % Tracking metrics
        total_actions_ = [];
        advised_actions_ = [];
        cond_a_true_count_ = [];
        cond_b_true_count_ = [];
        cond_c_true_count_ = [];
        
        % Advice Exchange Data
        cq_ = [];           % Realtive current average quality
        best_cq_ = [];      % Best value for cq, and robot id
        bq_ = [];           % Relative best average quality
        best_bq_ = [];      % Best value for bq, and robot id
        
        % Advice Exchange Properties
        alpha_ = [];        % Coefficient for current average quality update
        beta_ = [];         % Coefficient for best average quality update
        delta_ = [];        % Coefficient for quality comparison
        rho_ = [];          % Coefficient for quality comparison
        
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
            this.config_ = config;
            this.mechanism_ = config.advice_mechanism;
            this.id_ = id;
            this.num_robots_ = config.numRobots;
            this.epoch_ = 1;
            this.total_actions_ = 0;
            this.advised_actions_ = 0;
                        
            % Set Advice Exchange Properties
            this.alpha_ = config.advice_alpha;       
            this.beta_ = config.advice_beta;
            this.delta_ = config.advice_delta;
            this.rho_ = config.advice_rho;
            
            % Intialize Advice Exchange metrics
            this.cq_ = 0;
            this.best_cq_ = struct('id', [], 'value', 0);
            this.bq_ = 0;
            this.best_bq_ = struct('id', [], 'value', 0);
            this.cond_a_true_count_ = 0;
            this.cond_b_true_count_ = 0;
            this.cond_c_true_count_ = 0;
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
            
            this.total_actions_ = this.total_actions_ + 1;
            
            % Get advice from selected mechanism
            if (strcmp(this.mechanism_, 'advice_exchange'))
                quality_out = this.adviceExchange(state_vector, quality_in);
            elseif (strcmp(this.mechanism_, 'entropy'))
                  quality_out = this.adviceEntropy(state_vector, quality_in);  
            end
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %   adviceEntropy
        %
        %   TODO
        %
        %   INPUTS:
        %   quality_in = Vector of quality values for this robots state
        %
        %   OUTPUTS:
        %   quality_out = Advised quality values
        
        function quality_out = adviceEntropy(this, state_vector, quality_in)
            % TODO
            quality_out = quality_in;
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
                cond_a = avg_quality < (this.best_cq_.value - this.delta_*this.best_cq_.value);
                
                % Compare best quality
                advisor_bq = this.requestData(this.advisor_id_, 'bq');
                cond_b = this.bq_ < advisor_bq;
                
                % Compare qualities for current action
                % NOT EVALUATED IN MATLABCISL FROM JUSTIN GIRARD
                % cond_c = sum(quality_in) < this.rho_*sum(this.advisor_quality_);
                cond_c = true;
                
                % All conditions must be satisfied to give advice
                if (cond_a && cond_b && cond_c)
                    quality_out = this.advisor_quality_;
                    this.advised_actions_ = this.advised_actions_ + 1;
                else
                    quality_out = quality_in;
                    this.advisor_id_ = [];
                end
                
                % Track how often each is true
                this.cond_a_true_count_ = this.cond_a_true_count_ + cond_a;
                this.cond_b_true_count_ = this.cond_b_true_count_ + cond_b;
                this.cond_c_true_count_ = this.cond_c_true_count_ + cond_c;
            else
                quality_out = quality_in;
                this.advisor_id_ = [];
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
            this.cq_ = (1 - this.alpha_)*avg_quality + this.alpha_*this.cq_;
            this.bq_ = max(avg_quality, this.beta_*this.bq_);

            % Store our tracking metrics in the AdviceDatabase
            data_map = containers.Map;
            data_map('cq') = this.cq_;
            data_map('bq') = this.bq_;
            this.storeData(this.id_, data_map);
            
            % Increment epochs
            this.epoch_ = this.epoch_ + 1;
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
        %   pullIndividualMetrics
        %
        %   Pulls all the individual tracking metrics for other robots from
        %   the AdviceDatabase, so that this robot has knowledge about
        %   other robots itnernal advice data.
        
        function pullIndividualMetrics (this)
            % TODO
        end
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %   resetTrackingMetrics
        %
        %   Resets all tracking metrics for the next run
        
        function resetTrackingMetrics (this)
            this.total_actions_ = 0;
            this.advised_actions_ = 0;
            this.cond_a_true_count_ = 0;
            this.cond_b_true_count_ = 0;
            this.cond_c_true_count_ = 0;
        end
        
        
    end
    
end

