classdef AdviceExchange < handle
  % AdviceExchange - Implements the Advice Exchange Algorithm from [Girard, 2015]
  
  % Tracks metrics about the advisee and each potential advisor, then
  % selects the agent with the highest best average quality as the
  % potential advisor and checks some conditions to determine if advice
  % should be accepted from this advisor or not.
  
  properties
    % General properties
    config_;               % Configuration object
    id_;                   % This robot's Id
    iters_;                % Iteration counter during epoch
    epoch_;                % Epoch counter
    advice_data_;          % Structure of data to save
    mechanism_metrics_;    % Mechanism specific metrics for the current epoch (for updating advice_data_)
    adviser_metrics_;      % Adviser specific metrics for the current epoch (for updating advice_data_)
    epoch_iters_;          % Iterations completed in current epoch
    num_advisers_;
    robot_handles_;
    advisers_initialized_;
    
    % Advice Exchange properties
    adviser_id_;
    cq_;           % Realtive current average quality of all robots
    bq_;           % Relative best average quality of all robots
  end
  
  events
    RequestRobotHandle;  % For getting robot data from ExecutiveSimulation
  end
  
  methods
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %   Constructor
    %
    %   Loads in configuration data and a copy of each robot to add
    %   listeners, and initializes properties.
    
    function this = AdviceExchange (config, id)
      % General parameters
      this.config_ = config;
      this.id_ = id;
      this.epoch_ = 1;
      this.iters_ = 0;
      this.epoch_iters_ = 0;
      
      this.robot_handles_ = cell(this.config_.scenario.num_robots, 1);
      this.advisers_initialized_ = false;
      this.adviser_id_ = this.id_;
      
      % Initialize advice data being recorded
      this.initializeMetrics();
      
      % Clear persistent variables in the getSetAdviserData method
      clear getSetAdviserData
      clear getSetCurrentQuality
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %   initializeEpochMetrics
    %
    %   Resets the metrics properties for the next epoch
    
    function initializeMetrics(this)
      % Mechanism metrics
      this.mechanism_metrics_.avg_q = 0;
      this.mechanism_metrics_.advice_used = 0;
      
      % Adviser specific metrics
      num_robots = this.config_.scenario.num_robots;
      this.adviser_metrics_.accept = zeros(num_robots, 1);
      this.adviser_metrics_.cond_a_true_count = zeros(num_robots, 1);
      this.adviser_metrics_.cond_b_true_count = zeros(num_robots, 1);
      this.adviser_metrics_.cond_c_true_count = zeros(num_robots, 1);
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %   preAdviceUpdate
    %
    %   To be called before each time advice is retrieved.
    
    function  preAdviceUpdate(this)
      this.iters_ = this.iters_ + 1;
      this.epoch_iters_ = this.epoch_iters_ + 1;
      
      % Need to initialize the advisers once
      if (~this.advisers_initialized_)
        % Get robot handles from ExecutiveSimulation
        this.notify('RequestRobotHandle');
        this.advisers_initialized_ = true;
      end
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
    %   INPUTS:
    %   state_vector = Vector defining the robots current state
    %   quality = Vector of quality values for this robots state
    %   experience = Vector of times each has been executed
    %
    %   OUTPUTS:
    %   action_id = Id number of advised acton
    
    function action_id = getAdvice(this, state_vector, quality, experience)
      % Prepare data
      this.preAdviceUpdate();
      
      % Do nothing during the first epoch (need data first)
      if(this.epoch_ <= 1)
        [action_id, ~] = this.robot_handles_(this.id_).individual_learning_.Policy(quality, experience);
        this.mechanism_metrics_.avg_q = this.mechanism_metrics_.avg_q + (quality(action_id) - this.mechanism_metrics_.avg_q)/this.epoch_iters_;
        this.getSetCurrentQuality(this.id_, this.mechanism_metrics_.avg_q);
        return;
      end
      
      % DEVELOPMENTAL
      %[action_id, ~] = this.robot_handles_(this.id_).individual_learning_.Policy(quality, experience);
      %this.mechanism_metrics_.avg_q = this.mechanism_metrics_.avg_q + (quality(action_id) - this.mechanism_metrics_.avg_q)/this.epoch_iters_;
      %this.getSetCurrentQuality(this.id_, this.mechanism_metrics_.avg_q);
      %return;
      
      % Find this robots adviser
      [~, this.adviser_id_] = max(this.cq_);
      if(this.adviser_id_ ~= this.id_)
        % Get this adviser's advice
        [advised_quality, advised_experience] = this.robot_handles_(this.adviser_id_).individual_learning_.q_learning_.getUtility(state_vector);
        
        % Compare this epochs current average quality
        my_current_cq = this.mechanism_metrics_.avg_q;
        current_cq_vals = this.getSetCurrentQuality(this.adviser_id_);
        cond_a = my_current_cq < this.config_.advice.delta*current_cq_vals(this.adviser_id_);
        
        % Compare best quality
        cond_b = this.bq_(this.id_) < this.bq_(this.adviser_id_);
        
        % Compare qualities for current action
        % (NOT EVALUATED IN MATLABCISL FROM JUSTIN GIRARD)
        cond_c = sum(quality) < this.config_.advice.rho*sum(advised_quality);
        
        this.adviser_metrics_.cond_a_true_count(this.adviser_id_) = this.adviser_metrics_.cond_a_true_count(this.adviser_id_) + (cond_a - this.adviser_metrics_.cond_a_true_count(this.adviser_id_))/this.epoch_iters_;
        this.adviser_metrics_.cond_b_true_count(this.adviser_id_) = this.adviser_metrics_.cond_b_true_count(this.adviser_id_) + (cond_b - this.adviser_metrics_.cond_b_true_count(this.adviser_id_))/this.epoch_iters_;
        this.adviser_metrics_.cond_c_true_count(this.adviser_id_) = this.adviser_metrics_.cond_c_true_count(this.adviser_id_) + (cond_c - this.adviser_metrics_.cond_c_true_count(this.adviser_id_))/this.epoch_iters_;
        
        % Accept advice?
        if(cond_a && cond_b && cond_c)
          quality = advised_quality;
          experience = advised_experience;
          this.adviser_metrics_.accept(this.adviser_id_) = this.adviser_metrics_.accept(this.adviser_id_) + (1 - this.adviser_metrics_.accept(this.adviser_id_))/this.epoch_iters_;
        end
      end
      
      % Select an (advised) action
      [action_id, ~] = this.robot_handles_(this.id_).individual_learning_.Policy(quality, experience);
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %   resetForNextRun
    %
    %   Resets all tracking metrics for the next run
    
    function resetForNextRun(this)
      % Update adviser metrics
      [this.cq_, this.bq_] = this.getSetAdviserData(this.id_, this.mechanism_metrics_.avg_q);
      
      % Save the advice data
      % TODO
      
      % Reset the metrics for the next round
      this.initializeMetrics();
            
      % Adjust counters
      this.epoch_iters_ = 0;
      this.epoch_ = this.epoch_ + 1;
    end
    
  end
    
  methods (Static)
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %   getSetAdviserData
    %
    %   TODO
    
    function [cq_out, bq_out] = getSetAdviserData(id, new_q)
      persistent cq;
      persistent bq;
      
      if(nargin == 2);
        % Update the data for this adviser
        if(id*id > length(cq)*length(bq))
          % First data point
          cq(id) = new_q;
          bq(id) = new_q;
        else
          % Update with moving average
          alpha = 0.9;
          beta = 0.9;
          cq(id) = alpha*cq(id) + (1 - alpha)*new_q;
          
          if(new_q > bq(id))
            % New best
            bq(id) = new_q;
          else
            % Decay old value
            bq(id) = beta*bq(id);
          end
        end
      elseif(nargin ~= 1)
        warning('Improper number of arguments. Expected 1 or 2, received %d', nargin);
      end
      
      cq_out = cq;
      bq_out = bq;
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %   getSetCurrentQuality
    %
    %   TODO
    
    function current_cq_out = getSetCurrentQuality(id, new_q)
      persistent current_cq;
      
      if(nargin == 2);
        % Update the data for this adviser
        if(id > length(current_cq))
          % First data point
          current_cq(id) = new_q;
        else
          % Update with average
          current_cq(id) = new_q;
        end
      elseif(nargin ~= 1)
        warning('Improper number of arguments. Expected 1 or 2, received %d', nargin);
      end
      
      current_cq_out = current_cq;
    end
    
  end
  
end

