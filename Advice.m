classdef Advice < handle
    % Advice - Base class for advice mechanisms
    
    % Contains all common functionality to the advice mechanisms, and
    % methods for interacting with AdviceDatabase.
    
    properties
        % Configuration settings
        config_ = [];
        num_robots_ = [];
        robots_ = [];
        id_ = [];
        epoch_ = [];
        
        % Advisor Properties
        adviser_handles_ = [];
        advisers_initialized_ = [];
        advisor_handle_ = [];
        adviser_id_ = [];
        prev_adviser_id_ = [];
        
        % Structure of data to save
        advice_data_ = [];
        data_initialized_ = [];
        iters_ = [];
        
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
            this.id_ = id;
            this.num_robots_ = config.numRobots;
            this.epoch_ = 1;
            this.adviser_id_ = this.id_;
            this.iters_ = 0;
            this.adviser_handles_ = cell(this.num_robots_ - 1, 1);
            this.advisers_initialized_ = false;
            
            % Initialize structure for data to save
            this.data_initialized_ = true;
            this.advice_data_.advisor = 0;
            this.advice_data_.total_actions = 0;
            this.advice_data_.advised_actions = 0;
            this.advice_data_.advised_actions_ratio = 0;
        end
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %   preAdviceUpdate
        %
        %   To be called before each time advice is retrieved. 
        
        function  preAdviceUpdate(this)
            if (~this.data_initialized_)
                % Allocate a spot in the arrays for next the epoch
                this.advice_data_.advised_actions_ratio(1, this.epoch_) = 0;
                this.advice_data_.advised_actions(1, this.epoch_) = 0;
                this.advice_data_.total_actions(1, this.epoch_) = 0;
                this.data_initialized_ = true;
            end
            
            if (~this.advisers_initialized_)
                % Get robot handles
                j = 1;
                for i = 1:this.num_robots_
                    if i ~= this.id_
                        this.adviser_handles_{j, 1} = this.requestData(i, 'robot_handle');
                        j = j + 1;
                    end
                end
                this.advisers_initialized_ = true;
            end
                        
            %this.prev_adviser_id_ = this.adviser_id_;  
            
            this.iters_ = this.iters_ + 1;
        end
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %   postAdviceUpdate
        %
        %   To be called after each time advice is retrieved. Updates
        %   tracking metrics for the advice.
        
        function  postAdviceUpdate(this)
            % Save advice data
            if (this.adviser_id_ ~= this.id_)
                this.advice_data_.advised_actions(this.epoch_) = this.advice_data_.advised_actions(this.epoch_) + 1;
            end
            this.advice_data_.total_actions(this.epoch_) = this.advice_data_.total_actions(this.epoch_) + 1;
            this.advice_data_.advisor(this.iters_) = this.adviser_id_;
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
        %   resetForNextRun
        %
        %   Resets all tracking metrics for the next run
        
        function resetForNextRun(this)
            % Increment epochs
            this.epoch_ = this.epoch_ + 1;
            this.data_initialized_ = false;
            this.advisers_initialized_ = false;
        end
        
    end
    
end

