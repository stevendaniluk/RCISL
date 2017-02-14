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
    %
    % Stores Q-values (utility values) and experience (number of
    % visitations to that state) for each state-action pair.
    %
    % Given the number of state variables, the range of state variables,
    % and the number of actions, an appropriately sized sparse array will
    % be formed.
    % 
    % Each state and action combo will have a unique key value,
    % representing the corresponding row in the table. State variables must 
    % be integers, and action values must be non-zero integers. 
    %
    % Example: There are 5 state variables, with minimum values of 
    % [0, 0, 0, 0, 0] and maximum values of [15, 1, 15, 15, 15]
    %
    % A table is formed such that:
    %   Rows 1:80 are for vectors [0 0 0 0 0] to [15 0 0 0 0]
    %   Rows 81:160 are for vectors [0 1 0 0 0] to [15 1 0 0 0]
    %   Rows 161:2561 are for vectors [0 0 0 0 0] to [15 1 15 0 0]
    %   etc.
    %
    % An encoder vector is used, so that when the state vector is
    % multiplied by this vector, it accounts for the offset needed for each
    % element. For this example the encoder vector is 
    % [1, 80, 160, 2560, 40960]. Thus the second element of the state
    % vector gets offset by 80, the third by 160, the forth by 2560, etc..
    
    properties (Access = public)        
        % Main Q-learning parameters
        gamma_;                % Gamma coefficient in Q-learning update
        alpha_max_;            % Maximum value of alpha
        alpha_rate_;           % Coefficient in alpha update
        num_state_vrbls_;      % Number of variables in state vector
        num_actions_;          % Number of possible actions
        state_resolution_;     % Bits required to express state values
        encoder_vector_;       % Multiplying vector to convert state vector to key value
        table_size_;           % Length of Q-table
        q_table_;              % Sparse array  of Q-values
        exp_table_;            % Sparse array  of experience values
    end
    
    methods (Access = public)
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Constructor
        %
        %   INPUTS
        %   config = Configuration object
 
        function this = QLearning(gamma, alpha_max, alpha_rate, num_state_vrbls, state_resolution, num_actions)
            % Set learning parameters
            this.gamma_ = gamma;
            this.alpha_max_ = alpha_max;
            this.alpha_rate_ = alpha_rate;
            
            % Set state info
            this.num_state_vrbls_ = num_state_vrbls;
            this.num_actions_ = num_actions;
            this.state_resolution_ = state_resolution;
            
            % Form encoder vector to multipy inputted state vectors by
            this.encoder_vector_ = ones(1, this.num_state_vrbls_);
            for i=2:this.num_state_vrbls_
                this.encoder_vector_(i) = prod(this.state_resolution_(1:(i-1)));
            end
            this.encoder_vector_ = this.encoder_vector_*this.num_actions_;
            
            % Calculate table size for all possible combinations
            this.table_size_ = prod(this.state_resolution_)*this.num_actions_;
            
            % Create sparse Q and experience table
            this.q_table_ = sparse(this.table_size_, 1);
            this.exp_table_ = sparse(this.table_size_, 1);
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
            [quality_now, experience_now] =  this.getUtility(state_now);
            [quality_future, ~] =  this.getUtility(state_future);
            
            % Exponentially decrease learning rate with experience
            alpha = this.alpha_max_*exp(-experience_now(action_id)/this.alpha_rate_);
            
            % Standard Q-learning update rule [Boutilier, 1999]
            quality_update = quality_now(action_id) + alpha*(reward + this.gamma_*max(quality_future) - quality_now(action_id));

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

        function [quality, experience] = getUtility(this, state_vector)
            % Find row corresponding to keyVector
            key = this.getKey(state_vector, 1);
            % Make vector of entries for all actions
            key = key:(key + this.num_actions_ - 1);
            
            % Retrieve quality and experience, and convert to full vectors 
            % (since they may be sparse)
            quality = this.q_table_(key);
            quality = full(quality);
            
            experience = this.exp_table_(key);
            experience = full(experience);
        end        
            
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
 
        function updateUtility(this, state_vector, action_id, quality)
            % Find corresponding row in table
            key= this.getKey(state_vector, action_id);
            % Increment experience
            experience = this.exp_table_(key) + 1;
            % Insert new data
            this.q_table_(key) = quality;
            this.exp_table_(key) = experience;
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   overwriteUtility
        %   
        %   Overwrite existing Q value and experience into quality table
        %
        %   INPUTS
        %   state = Vector of state variables
        %   actions = Single number, or vector of applicable actions
        %   quality = New Q value(s) for table
        %   experience = New experience value(s) for the table
 
        function overwriteUtility(this, state_vector, actions, quality, experience)            
            % Find corresponding row in table
            key= this.getKey(state_vector, min(actions));
            % Make vector of entries for all actions
            key = key + actions - min(actions);
            
            % Insert into table
            this.q_table_(key) = quality;
            this.exp_table_(key) = experience;
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   getKey
        %
        %   Get the table index for a certain key vector
        %
        %   INPUTS
        %   state_vector = Vector of state variables
        %   action_id = Action number [1,num_actions_]
        
        function key= getKey(this, state_vector, action_id)
            % Multipy by the encoder vector and add the action num to 
            % convert to a unique key value
            key = action_id + state_vector * this.encoder_vector_';
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Reset
        %
        %   Reset the table to an empty sparse array
        
        function reset(this)
            this.q_table_ = sparse(this.table_size_, 1);
            this.exp_table_ = sparse(this.table_size_, 1);
        end
        
    end
    
end
