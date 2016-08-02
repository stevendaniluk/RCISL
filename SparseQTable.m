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
        num_state_vrbls_ = [];   % Number of variables in state vector
        num_actions_ = [];       % Number of possible actions
        state_bits_ = [];        % Bits required to express state values
        encoder_vector_ = [];    % Multiplying vector to convert state vector to key value
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
        
        function this = SparseQTable (num_state_vrbls, state_bits, num_actions)
            
            this.num_state_vrbls_ = num_state_vrbls;
            this.num_actions_ = num_actions;
            this.state_bits_ = state_bits;
            
            % Form encoder vector to multipy inputted state vectors by
            this.encoder_vector_ = ones(1, this.num_state_vrbls_);
            for i=2:this.num_state_vrbls_
                this.encoder_vector_(i) = prod(2.^this.state_bits_(1:(i-1)));
            end
            this.encoder_vector_ = this.encoder_vector_*this.num_actions_;
            
            % Calculate table size for all possible combinations
            this.table_size_ = prod(2.^this.state_bits_)*this.num_actions_;
            
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
            % Ensure the state_vector elements are within bounds
            state_vector = mod(state_vector, 2.^this.state_bits_);
            
            % Multipy by the encoder vector and add the action num to 
            % convert to a unique key value
            key = action_id + state_vector * this.encoder_vector_';
        end
        
    end
    
end


