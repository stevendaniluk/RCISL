classdef QLearning <handle
    % QLEARNING - Performs Q-Learning given states, actions and rewards
    
    % Contains equations for updating Q-values and the learning rate, then
    % stores the updated values in a SparseQTable.
    %
    % Also keeps track of alpha, gamma, experience, quality, and reward at
    % each iteration.
    %
    % A standard Q-learning update rule is used [Boutilier, 1999], with a 
    % constant gamma, and an exponentially decreasing learning rate 
    % dependent on the number of visitations to a state [Source Unknown].
    
    properties (Access = public)
        % For storing alpha, gamma, experience, quality, and reward
        learning_data_ = [];        % Table
        learning_data_index_ = 0;   % Current index
        
        % Main Q-learning parameters
        quality_ = [];      % Table of Q values and experience
        gamma_ = [];        % Gamma coefficient in Q-learning update
        alpha_denom_ = [];  % Coefficient in alpha update
        alpha_power_ = [];  % Coefficient in alpha update
    end
    
    properties (Access = private)
        
    end
    
    methods (Access = public)
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Constructor
        %
        %   INPUTS
        %   config = Configuration object
 
        function this = QLearning(config)
            % Load learning parameters from config file
            this.gamma_ = config.gamma;
            this.alpha_denom_ = config.alpha_denom;
            this.alpha_power_ = config.alpha_power;
            
            % Form array for storing learning data
            this.learning_data_ = zeros(config.max_iterations, 6);
            
            % Intiialize quality table
            this.quality_ = SparseQTable(config.num_state_vrbls, config.num_state_bits, config.num_actions);
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   learn
        %   
        %   Performs Q-learning update, stores the learning data, and
        %   updates the quality table
        %
        %   INPUTS
        %   state_now =  Vector of current state variables
        %   state_future = Vector of future state variables
        %   action_id = Action number [1, num_actions]
        %   reward = Reward recieved
        
        function learn(this, state_now, state_future, action_id, reward)
            % Get qualities and experience from table
            [quality_now, experience_now] =  this.quality_.getElements(state_now);
            [quality_future, ~] =  this.quality_.getElements(state_future);
            
            % Exponentially decrease learning rate with experience [Unknown]
            alpha = 1/(exp((experience_now(action_id).^this.alpha_power_)/this.alpha_denom_));
            
            % Standard Q-learning update rule [Boutilier, 1999]
            quality_update = quality_now(action_id) + alpha*(reward + this.gamma_*max(quality_future) - quality_now(action_id));
            
            % Update tracking metrics
            this.addToLearningData ([alpha, this.gamma_, experience_now(action_id), ...
                                     quality_now(action_id), reward, nnz(this.quality_.q_table_)]);            

            % Update quality table
            this.updateUtility(state_now, action_id, quality_update);
            
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   getUtility
        %   
        %   Return quality and experience from table
        %
        %   INPUTS
        %   state = Vector of state variables

        function [quality, experience] = getUtility(this, state)
            [quality, experience] = this.quality_.getElements(state);
        end        

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   resetLearningData
        %   
        %   Resets the learning data array and index to zero 

        function resetLearningData(this)
            this.learning_data_ = zeros(size(this.learning_data_));
            this.learning_data_index_ = 0;            
        end
        
    end
    
    methods (Access = private)
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   updateUtility
        %   
        %   Insert new Q value into quality table
        %
        %   INPUTS
        %   state = Vector of state variables
        %   action_id = Action number [1, num_actions]
        %   q_value = New Q value for table
 
        function updateUtility(this, state, action_id, q_value)
            this.quality_.storeElements(state,q_value,action_id);
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   addToLearningData
        %   
        %   Add the inputted dataVector to the learning_data_ array 
        %
        %   INPUTS
        %   data_vector = Vector: [alpha, gamma, experience, quality, reward, visited states]
        
        function addToLearningData (this, data_vector)
            this.learning_data_index_ = this.learning_data_index_ + 1;
            this.learning_data_(this.learning_data_index_, :) = data_vector;
        end
        
    end
    
end
