classdef AdviceDatabase < handle
    % AdviceDatabase - Medium for storing and exchange data for advice
    
    properties
        % Configuration settings
        config_ = [];
        num_robots_ = [];
        robot_handles_ = [];
        advice_mechanism_ = [];
        short_decay_rate_ = [];
        long_decay_rate_ = [];
        
        % Iteration tracking metrics
        avg_quality_total_ = [];
        avg_quality_decaying_ = [];
        avg_entropy_total_ = [];
        avg_entropy_decaying_ = [];
        delta_q_ = [];
        delta_h_ = [];
        
        % Epoch tracking metrics
        epoch_avg_quality_ = [];
        
        % Advice Exchange Data
        ae_cq_ = [];           % Realtive current average quality
        ae_bq_ = [];           % Relative best average quality
        
    end
    
    methods
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %   Constructor
        %
        %   Loads in configuration data and a copy of each robot to add
        %   listeners, and initializes properties.
        
        function this = AdviceDatabase (config, robots)
            this.config_ = config;
            this.num_robots_ = config.numRobots;
            this.robot_handles_ = robots;
            this.advice_mechanism_ = config.advice_mechanism;
            this.short_decay_rate_ = config.a_dev_short_decay_rate;
            this.long_decay_rate_ = config.a_dev_long_decay_rate;
            
            % Intialize tracking metrics
            keys = 1:this.num_robots_;
            values = zeros(this.num_robots_, 1);
            this.avg_quality_total_ = containers.Map(keys, values);
            this.avg_quality_decaying_ = containers.Map(keys, values);
            this.avg_entropy_total_ = containers.Map(keys, values);
            this.avg_entropy_decaying_ = containers.Map(keys, values);
            this.delta_q_ = containers.Map(keys, values);
            this.delta_h_ = containers.Map(keys, values);
            this.epoch_avg_quality_ = containers.Map(keys, values);
            
            % Initialize Advice Exchange Data
            if (strcmp(this.advice_mechanism_, 'advice_exchange'))
                this.ae_cq_ = containers.Map(keys, values);
                this.ae_bq_ = containers.Map(keys, values);
            end
            
            % Add property listeners for each robot
            for id = 1:this.num_robots_;
                % For robot data tracked at each iteration
                addlistener(robots(id, 1).individual_learning_, 'PerfMetrics', @(src, event)this.handleDataMonitoring(src, event));
                
                % For interaction with Advice
                addlistener(robots(id, 1).individual_learning_.advice_, 'RequestData', @(src, event)this.handleRequestData(src));
                addlistener(robots(id, 1).individual_learning_.advice_, 'StoreData', @(src, event)this.handleStoreData(src));
            end            
        end
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %   handleDataMonitoring
        %
        %   Record changes in performance metrics for the robots
        
        function handleDataMonitoring(this, ~, event)
            switch event.type
                case 'quality'
                    epoch_iters = event.Source.epoch_iterations_;
                    total_iters = event.Source.learning_iterations_ + 1;
                    
                    this.epoch_avg_quality_(event.id) = this.epoch_avg_quality_(event.id) + (event.value - this.epoch_avg_quality_(event.id))/epoch_iters;
                    this.avg_quality_total_(event.id) = this.avg_quality_total_(event.id) + (event.value - this.avg_quality_total_(event.id))/total_iters;
                    this.avg_quality_decaying_(event.id) = this.long_decay_rate_*this.avg_quality_decaying_(event.id) + (1 - this.long_decay_rate_)*event.value;
                case 'entropy'
                    total_iters = event.Source.learning_iterations_ + 1;
                    
                    this.avg_entropy_total_(event.id) = this.avg_entropy_total_(event.id) + (event.value - this.avg_entropy_total_(event.id))/total_iters;
                    this.avg_entropy_decaying_(event.id) = this.short_decay_rate_*this.avg_entropy_decaying_(event.id) + (1 - this.short_decay_rate_)*event.value;
                case 'delta_q'
                    this.delta_q_(event.id) = event.value;
                case 'delta_h'
                    this.delta_h_(event.id) = event.value;
            end
        end
        

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %   handleRequestData
        %
        %   Receives requests for data from Advice mechanism, checks what
        %   data has been requeseted, then saves the data in the
        %   data_return_ property of the requester. 
        
        function handleRequestData(this, src)
            % Get data struct
            list = src.request_data_;
            id = list{1};
            
            % Save Id in output data
            src.data_return_{1, 1} = id;
            
            % Check label for each cell and assign output data 
            for i = 2:length(list)
                switch list{i}
                    case 'epoch_avg_quality'
                        src.data_return_{i - 1, 1} = this.epoch_avg_quality_(id);
                    case 'avg_quality_total'
                        src.data_return_{i - 1, 1} = this.avg_quality_total_(id);
                    case 'avg_quality_decaying'
                        src.data_return_{i - 1, 1} = this.avg_quality_decaying_(id);
                    case 'avg_entropy_total'
                        src.data_return_{i - 1, 1} = this.avg_entropy_total_(id);
                    case 'avg_entropy_decaying'
                        src.data_return_{i - 1, 1} = this.avg_entropy_decaying_(id);
                    case 'delta_q'
                        src.data_return_{i - 1, 1} = this.delta_q_(id);
                    case 'delta_h'
                        src.data_return_{i - 1, 1} = this.delta_h_(id);
                    case 'ae_cq'
                        src.data_return_{i - 1, 1} = this.ae_cq_(id);
                    case 'ae_bq'
                        src.data_return_{i - 1, 1} = this.ae_bq_(id);
                    case 'robot_handle'
                        src.data_return_{i - 1, 1} = this.robot_handles_(id, 1);
                    otherwise
                        % Improper string
                        warning(['Improper data request in handleDataRequest: ', list{i, 1}]); 
                        src.data_received_{i, 1} = 'VOID';
                end
            end

        end
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %   handleStoreData
        %
        %   Receives map of data from Advice mechanism, checks the data
        %   property, then stores the data for that robot.
        
        function handleStoreData(this, src)
            % Get robot Id
            id = src.store_data_('id');
            
            % Check each data property
            if (isKey(src.store_data_, 'ae_cq'))
                this.ae_cq_(id) = src.store_data_('ae_cq');
            end
            if (isKey(src.store_data_, 'ae_bq'))
                this.ae_bq_(id) = src.store_data_('ae_bq');
            end
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %   epochFinished
        %
        %   Calls each robot's advice mechanism to finialize their data for
        %   this epoch, and to update their data about other robots for the
        %   next epoch.
        
        function epochFinished(this)
            % Advice Exchange specific data
            if (strcmp(this.advice_mechanism_, 'advice_exchange') || strcmp(this.advice_mechanism_, 'advice_exchange_plus'))
                for id = 1:this.num_robots_;
                    this.robot_handles_(id, 1).individual_learning_.advice_.publishPerfMetrics();
                end
                for id = 1:this.num_robots_;
                    this.robot_handles_(id, 1).individual_learning_.advice_.updateIndividualMetrics();
                end
            end
            
            for id = 1:this.num_robots_;
                this.robot_handles_(id, 1).individual_learning_.advice_.resetForNextRun();
            end
        end
                        
    end
    
end

