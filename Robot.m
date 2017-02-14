classdef Robot < handle 
    % ROBOT - Contains all information/capabilities for one robot
    
    % The Robot class is inteneded to be a standard itnerface for the
    % Executive simulation to interact with the "robots". It contains
    % methods for the basic robot capabilities (getAction, act, learn), 
    % which will always need to be called by the executive simulation.
    %
    % One instance of Robot must be created for each robot. The Robot class
    % contains a RobotState object for representing this robots current
    % state (i.e. robot specific state variables), and an
    % IndividualLearning object, which contains all learning functionality.
    
    properties
        id_;                   % Id number of the robot
        config_;               % Configuration object
        robot_state_;          % RobotState object (robot's state variables)
        world_state_;          % WorldState objetc (world's state varibales)
        individual_learning_;  % IndividualLearning object
        action_;               % The current action being performed 
        iterations_;           % Counter for iterations performed
        action_array_;         % Array with action properties
    end
    
    methods (Access = public)
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   Constructor
        %   
        %   Assigns the robot's ID, loads the configuration, and
        %   instantiates RobotState, IndividualLearning, and TeamLearning
        %   objects.
        %   
        %   INPUTS
        %   id = Id number of robot
        %   config = Configuration object
        %   world_state = WorldState object
 
        function this = Robot(id, config, world_state)
            this.id_ = id;
            this.config_ = config;
            this.world_state_ = world_state;
            this.robot_state_ = RobotState(this.id_, this.world_state_, this.config_);
            this.individual_learning_ = IndividualLearning(this.config_, this.id_);
            this.iterations_ = 0;
                        
            % Form the action array
            this.action_array_ = ... 
                  [this.robot_state_.step_size_               0; 
                              0                    this.robot_state_.rot_size_;
                              0                   -this.robot_state_.rot_size_;
                              0                               0];
            
            % Update our state when created
            this.robot_state_.update();
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   getAction
        %   
        %   Checks the robots current task allocation, retrieves an
        %   action id from the individual learning layer, the forms the
        %   action from the action array.
        %
        %   All action details are set here, in the action array.
  
        function getAction(this)
            % Save the robot state before we change it
            this.robot_state_.saveState();
            
            %Save, in the world, our current target ID
            this.world_state_.UpdateRobotTarget(this.id_, this.robot_state_.target_id_);
            
            % Get action if from individual learning, and set action
            action_id = this.individual_learning_.getAction(this.robot_state_);
            
            % Get action elements for the action_id from the learing layer
            this.action_ = this.action_array_(action_id,1:2);
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   act
        %   
        %   Will perform the corresponding action stored in
        %   this.action_ (i.e. from the getAction method) by making the
        %   appropriate call to the Physics methods
  
        function act(this, physics)
            % Depending on the action ID, make the appropriate action
            if(this.robot_state_.target_id_ ~= this.robot_state_.prev_target_id_ && this.robot_state_.target_id_ == 0)
                % Force robot to drop item if task allocation requests
                force_drop = true;
                physics.interact (this.world_state_, this.id_, this.robot_state_.prev_target_id_, force_drop);
            elseif(this.robot_state_.action_id_ <= 3)
                % Move in the direction specified by action
                physics.MoveRobot (this.world_state_, this.id_, this.action_(1), this.action_(2));
                % Add action tag for graphics
                if(this.robot_state_.action_id_ == 1)
                    this.robot_state_.action_label_  = [this.robot_state_.type_ ,' move'];
                else
                    this.robot_state_.action_label_  = [this.robot_state_.type_ ,' rot'];
                end
            else
                % Drop, or try to pick up item
                force_drop = false;
                physics.interact(this.world_state_, this.id_, this.robot_state_.target_id_, force_drop);
                this.robot_state_.action_label_  = [this.robot_state_.type_ ,' inter'];
            end
            
            this.iterations_ = this.iterations_ + 1;
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   learn
        %   
        %   Activates the learning in the individua learning layer, to
        %   learn from the current state. This should be called during each
        %   iteration, but depending on the learnign rate dictated int he
        %   configuration, it will decide if learning should be performed
        %   at each iteration.
  
        function learn(this)
            % Update, and make individual learning learn
            if (mod(this.iterations_, this.config_.IL.learning_iterations) == 0)
                this.robot_state_.update();
                this.individual_learning_.learn(this.robot_state_);
            end
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %   resetForNextRun
        %   
        %   Resets all the necessary data for performing consecutive runs,
        %   while maintatining learning data
        %
        %   INPUTS
        %   world_state = The new world state object, for the robot state
        %                 to initialize from
  
        function resetForNextRun(this, world_state)
            % Reset world and robot state variables
            this.world_state_ = world_state;
            this.robot_state_ = RobotState(this.id_, this.world_state_, this.config_);
            
            % Update our state when created
            this.robot_state_.update();
            
            % Reset the learning layer
            this.individual_learning_.resetForNextRun();
            
            this.iterations_ = 0;
        end
        
    end
    
end

