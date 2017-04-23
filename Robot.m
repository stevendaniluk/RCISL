classdef Robot < handle
  % ROBOT - Contains all information/capabilities for one robot
  
  % The Robot class is inteneded to be a standard interface for the
  % ExecutiveSimulation to interact with the "robots". Interaction is
  % through the act method and the reset for next run method.
  %
  % Once instance of Robot will exist for each robot in the simulation. It
  % contains the RobotState object, which holds all the robot's state data,
  % as well an IndividualLearning obect for learning capabilities.
  %
  % The physical properties fot eh robot (e.g. size, speed, etc.) are
  % contained within the prop_ property of this class.
  
  properties
    id_;                   % Id number of the robot
    config_;               % Configuration object
    robot_state_;          % RobotState object (robot's state variables)
    individual_learning_;  % IndividualLearning object
    action_def_;           % Struct with action properties
    effort_;               % Counter for actions when robot has a target
    prop_;                 % Stuct containing all properties for the robot
                           %   step_size - Distance moved for longitudinal movements
                           %   rotate_size - Angle rotated for rotational movements
                           %   strong - Flag for if the robot is strong
                           %   rugged - Flag for if the robot can handle rough terrain
                           %   reach - Distance a robot can grab a target from
                           %   label - String for indicating robot type
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
      this.robot_state_ = RobotState(this.id_, this.config_, world_state);
      this.individual_learning_ = IndividualLearning(this.id_, this.config_, world_state, this.robot_state_);
      this.effort_ = 0;
      
      % Set robot properties according to type from config
      prop_index = mod(this.id_ - 1, length(this.config_.scenario.robot_types)) + 1;
      type_num = this.config_.scenario.robot_types(prop_index);
      this.prop_ = this.config_.scenario.robot_defs(type_num);
      
      % Form the action definition
      %   1: Move forward
      %   2: Rotate left
      %   3: Rotate right
      %   4: Interact
      
      move_forward.step = this.prop_.step_size;
      move_forward.rotate = 0;
      
      rotate_left.step = 0;
      rotate_left.rotate = this.prop_.rotate_size;
      
      rotate_right.step = 0;
      rotate_right.rotate = -this.prop_.rotate_size;
      
      interact.step = 0;
      interact.rotate = 0;
      
      this.action_def_ = [move_forward, rotate_left, rotate_right, interact];
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %   act
    %
    %   Will perform the action determined by the individual learning layer
    %   by making the appropriate call to Physics.
    %
    %   INPUTS
    %   world_state = WorldState object
    %   physics = Physics object
    
    function act(this, world_state, physics)
      % Get action from individual learning
      action_id = this.individual_learning_.getAction();
      
      % Depending on the action ID, make the appropriate action
      if(action_id <= 3)
        % Move in the direction specified by action
        physics.MoveRobot(world_state, this.robot_state_, this.prop_, this.action_def_(action_id).step, this.action_def_(action_id).rotate);
      else
        % Try to pick up item
        physics.interact(world_state, this.robot_state_, this.prop_);
      end
      
      % Update state after action
      this.robot_state_.update(world_state);
      this.individual_learning_.postActionUpdate(this.robot_state_, world_state);
      
      % Learn from action
      if (mod(world_state.mission_.iters, this.config_.IL.learning_iterations) == 0)
        this.individual_learning_.learn(world_state, this.robot_state_, this.prop_);
      end
      
      % Increment effort
      if(this.robot_state_.target_.id ~= -1)
        this.effort_ = this.effort_ + 1;
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
    %   world_state = The new WorldState object
    
    function resetForNextRun(this, world_state)
      % Reset world and robot state variables
      this.robot_state_ = RobotState(this.id_, this.config_, world_state);
      
      % Reset counter(s)
      this.effort_ = 0;
      
      % Reset the learning layer
      this.individual_learning_.resetForNextRun();
    end
    
  end
  
end

