classdef TeamLearning < handle
  % TEAMLEARNING - Contains learning capabilities for the team of robots
  
  % Merely a wrapper for LAlliance that provides an interface to be
  % used by ExecutiveSimulation
  
  properties
    config_;      % Configuration Object
    l_alliance_;  % LAlliance object
  end
  
  methods
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %   Constructor
    %
    %   INPUTS:
    %   config = Configuration object
    
    function this = TeamLearning (config)
      this.config_ = config;
      
      if (strcmp(this.config_.TL.task_allocation, 'l_alliance'))
        this.l_alliance_ = LAlliance(this.config_);
      elseif (strcmp(this.config_.TL.task_allocation, 'fixed'))
        if(this.config_.scenario.num_robots ~= this.config_.scenario.num_targets)
          error('Must have equal amounts of robots and targets with fixed task allocation strategy');
        end
      end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %   getTasks
    %
    %   Calls upon L-Alliance to select the task, then stores in the
    %   RobotState for each robot
    %
    %   INPUTS:
    %   robots = Array of robot objects
    %   world_state = WorldState object
    
    function getTasks(this, robots, world_state)
      % Use appropriate task allocation strategy
      if (strcmp(this.config_.TL.task_allocation, 'l_alliance'))
        % Update L-Alliance for robots in a random order
        rand_robot_id = randperm(this.config_.scenario.num_robots);
        for i = 1:this.config_.scenario.num_robots
          robot_id = robots(rand_robot_id(i), 1).robot_state_.id_;
          % Save the old task
          %robots(rand_id,1).robot_state_.prev_target_id_ = robots(rand_id,1).robot_state_.target_id_;
          % Update task states
          this.l_alliance_.updatetaskProperties(robot_id, world_state);
          
          % Recieve the updated task, and assign it
          old_task = robots(robot_id, 1).robot_state_.target_.id;
          this.l_alliance_.chooseTask(robot_id);
          robots(robot_id, 1).robot_state_.target_.id = this.l_alliance_.getCurrentTask(robot_id);
          new_task = robots(robot_id, 1).robot_state_.target_.id;
          
          % When the task changes the robot can't be carrying anything
          if(old_task ~= new_task)
            robots(robot_id, 1).robot_state_.target_.carrying = false;
          end
        end
        
      elseif (strcmp(this.config_.TL.task_allocation, 'fixed'))
        for i = 1:this.config_.scenario.num_robots
          prelim_task_id = robots(i,1).robot_state_.id_;
          
          % Only assign the task if it is not complete
          returned = world_state.targets_(prelim_task_id).returned;
          if returned == 1
            robots(i,1).robot_state_.target_.id = -1;
          else
            robots(i,1).robot_state_.target_.id = prelim_task_id;
          end
        end
      end
      
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %   learn
    %
    %   Updates all task properties, and when necessary it will update
    %   the motivation of each robot towards the task
    %
    %   INPUTS:
    %   robots = Array of robot objects
    %   world_state = WorldState object
    
    function learn(this, robots, world_state)
      % Update the motivation if necessary
      if (mod(world_state.mission_.iters, this.config_.TL.LA.motiv_freq) == 0)
        for id = 1:this.config_.scenario.num_robots
          if (strcmp(this.config_.TL.task_allocation, 'l_alliance'))
            this.l_alliance_.updateImpatience(robots(id, 1).robot_state_.id_);
            this.l_alliance_.updateMotivation(robots(id, 1).robot_state_.id_);
          end
        end
      end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %   resetForNextRun
    %
    %   Resets all the necessary data for performing consecutive runs,
    %   while maintatining learning data
    
    function resetForNextRun(this)
      if (strcmp(this.config_.TL.task_allocation, 'l_alliance'))
        this.l_alliance_.reset();
      end
    end
    
  end
  
end

