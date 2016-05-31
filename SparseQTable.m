classdef SparseQTable < handle
    % SPARSEQTABLE - Table for Q-values and experience
    
    % Stores Q-values (utility values) and experience (number of
    % visitations to that state) for each state-action pair.
    %
    % Given the number of state variables, the range of state variables,
    % and the number of actions, an appropriately sized sparse array will
    % be formed.
    % 
    % Each state and action combo will have a unique key value,
    % representing the corresponding row in the table.
    %
    % State variables and action values must be non-zero integers. 
    %
    % Example: There are 5 state variables, with possible values between 0
    % 15, and there are 8 possible actions
    %
    % The state vector will look like: [X, X, X, X, X]
    % 3 Bits are needed to express the actions
    % 4 Bits are needed to express the state variables
    %
    % Rows of the data array will be formed as follows:
    %   Rows 1 to 2^(3+4) will be for state vectors [0 0 0 0 0] to [15 0 0 0 0]
    %   Rows (2^(3+4)+1) to 2(3+4+4) will be for state vectors [0 1 0 0 0] to [15 1 0 0 0]
    %   Rows (2^(3+4+4)+1) to 2(3+4+4+4) will be for state vectors [0 2 0 0 0] to [15 2 0 0 0]
    %   etc.

    properties (Access = public)
        num_state_vrbls_ = [];   % Number of variables in state vector
        num_actions_ = [];       % Number of possible actions
        state_bits_ = [];        % Bits required to express state values
        action_bits_ = [];       % Bits required to exress action number
        table_size_ = [];        % Length of Q-table
        q_table_ = [];           % Sparse array  of Q-values
        exp_table_ = [];         % Sparse array  of experience values
    end
    
    methods (Access = public)
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Constructor
        %
        %   INPUTS
        %   num_state_vrbls = Total number of state variables
        %   num_state_bits = Number of bits to represent each state
        %   num_actions
        
        function this = SparseQTable (num_state_vrbls, num_state_bits, num_actions)
            
            this.num_state_vrbls_ = num_state_vrbls;
            this.num_actions_ = num_actions;
            
            % Find bits are required to represent state values and action
            this.state_bits_ = num_state_bits;
            this.action_bits_ = ceil(log2(this.num_actions_));
            
            % Calculate table size for all possible combinations
            this.table_size_ = 2^(this.num_state_vrbls_ * this.state_bits_ + this.action_bits_);
            
            % Create sparse Q and experience table
            this.q_table_ = sparse(this.table_size_, 1);
            this.exp_table_ = sparse(this.table_size_, 1);
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   getElements
        %
        %   Retrieves quality and experience from table
        %
        %   INPUTS
        %   state_vector = Vector of state variables
        %
        %   OUTPUTS
        %   quality = vector of quality values for each action
        %   experience = vector of experience in each state-action pair
        
        function [quality, experience] = getElements(this, state_vector)
            
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
        %   storeElements
        %
        %   Stores a new quality value in the table, and updates experience
        %
        %   INPUTS
        %   state_vector = Vector of state variables
        %   quality = new quality value
        %   action_id = Action number [1,num_actions_]
        
        function  storeElements(this, state_vector, quality, action_id)
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
        %   Reset
        %
        %   Reset the table to an empty sparse array
        
        function reset(this)
            this.q_table_ = sparse(this.table_size_, 1);
            this.exp_table_ = sparse(this.table_size_, 1);
        end
        
    end
    
    methods (Access = private)
        
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
            % Find remainder if key_vector is greater than max value
            % This will not be necessary once the encoding is fixed
            state_vector = mod(state_vector, 2^this.state_bits_);
          
            % Increment key value for each entry in state_vector
            % Uses bitshift opeartion, since number of combinations can be
            % expressed in bits. See description at top for an example.
            key = action_id;
            for i = 1:this.num_state_vrbls_
                shift = bitshift(state_vector(i), (i-1)*this.state_bits_ + this.action_bits_);
                key = key + shift;
            end
        end
        
    end
    
end


