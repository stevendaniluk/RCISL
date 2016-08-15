classdef AdviceDatabase < handle
    % AdviceDatabase - TODO
    
    properties
        % Configuration settings
        config_ = [];
        num_robots_ = [];
        robot_handles_ = [];
        
        % General Tracking Metrics
        avg_quality_ = [];
        delta_quality_ = [];
        
        % Advice Exchange Data
        cq_ = [];           % Realtive current average quality
        bq_ = [];           % Relative best average quality
        
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
            
            % Intialize tracking metrics
            keys = 1:this.num_robots_;
            values = zeros(this.num_robots_, 1);
            this.avg_quality_ = containers.Map(keys, values);
            this.delta_quality_ = containers.Map(keys, values);
            
            % Initialize Advice Exchange Data
            this.cq_ = containers.Map(keys, values);
            this.bq_ = containers.Map(keys, values);
            
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
                    this.avg_quality_(event.id) = this.avg_quality_(event.id) + (event.value - this.avg_quality_(event.id))/event.iterations;
                case 'delta_quality'
                    this.delta_quality_(event.id) = event.value;
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
                    case 'avg_reward'
                        src.data_return_{i - 1, 1} = this.avg_reward_(id);
                    case 'avg_quality'
                        src.data_return_{i - 1, 1} = this.avg_quality_(id);
                    case 'delta_quality'
                        src.data_return_{i - 1, 1} = this.delta_quality_(id);
                    case 'cq'
                        src.data_return_{i - 1, 1} = this.cq_(id);
                    case 'bq'
                        src.data_return_{i - 1, 1} = this.bq_(id);
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
            if (isKey(src.store_data_, 'cq'))
                this.cq_(id) = src.store_data_('cq');
            end
            if (isKey(src.store_data_, 'bq'))
                this.bq_(id) = src.store_data_('bq');
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
            for id = 1:this.num_robots_;
                this.robot_handles_(id, 1).individual_learning_.advice_.publishPerfMetrics();
            end
            for id = 1:this.num_robots_;
                this.robot_handles_(id, 1).individual_learning_.advice_.updateIndividualMetrics();
            end
            for id = 1:this.num_robots_;
                this.robot_handles_(id, 1).individual_learning_.advice_.resetTrackingMetrics();
            end
        end
                        
    end
    
end

