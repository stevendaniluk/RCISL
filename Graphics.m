% GRAPHICS - Generates simulation graphics from the world and robot states

% Called at each iteration of the simulation.
%
% Can generate live graphics, or plot the tracks of each robot and target
% after the run is completed, as dictated by the show_live_graphics and
% show_track_graphics parameters in the configuration.

% INPUTS
% config = Configuration object being used
% world_state = The current world state
% robots = Array of robot objects

function [] = Graphics(config, world_state, robots)

    % Load world state
    [position, orientation, obstacles, targets, goal_position, targetProperties, robotProperties] = world_state.GetSnapshot();

    % If requested, display the live graphics during the run
    if(config.sim.show_live_graphics)
        clf
        cla
        hold on;
        
        % Display current iteration
        text(1, 9, sprintf('%d', world_state.iters_));
        
        % Draw the robots
        for i=1:config.scenario.num_robots
            
            % Create arrow to represent each robot
            arrow=zeros(5,2);
            arrow(:,1)=position(i,1);
            arrow(:,2)=position(i,2);

            ang = orientation(i,3);
            len = 0.5;

            arrow(1,1:2) = [arrow(1,1) - len*cos(ang) arrow(1,2) - len*sin(ang)];
            arrow(2,1:2) = [arrow(2,1) + len*cos(ang) arrow(2,2) + len*sin(ang)];
            arrow(3,1:2) = [arrow(3,1) + 0.1*cos(ang)+0.1*sin(ang) ...
                arrow(3,2) + 0.1*sin(ang)+0.1*cos(ang)];
            arrow(4,1:2) = [arrow(4,1) + 0.1*cos(ang)-0.1*sin(ang) ...
                arrow(4,2) + 0.1*sin(ang)-0.1*cos(ang)];
            arrow(5,1:2) = [arrow(5,1) + len*cos(ang) arrow(5,2) + len*sin(ang)];
            
            % Draw arrow for each robot
            plot(arrow(:,1),arrow(:,2),'b');
            
            % Add text for robot id, type, and current action
            lbl = [sprintf('%d', i), ' ', robots(i).robot_state_.action_label_];
            text(position(i,1)+0.2, position(i,2)+0.2, lbl);
            
            % If noise is present, plot the state estimates
            if(config.noise.sigma > 0)
                % Draw the robots current belief about its own position
                pos_belief = robots(i).robot_state_.belief_self(1:2);
                boxPoints = GetBox(pos_belief, config.scenario.robot_size);
                plot(boxPoints(1,:),boxPoints(2,:),'g');

                % Draw the robots current belief about its goal position
                goal_belief = robots(i).robot_state_.belief_goal(1:2);
                boxPoints = GetBox(goal_belief,0.1);
                plot(boxPoints(1,:),boxPoints(2,:),'b');

                % Draw the robots current belief about its target position
                target_belief = robots(i).robot_state_.belief_task(1:2);
                boxPoints = GetBox(target_belief, 0.5*config.scenario.target_size);
                plot(boxPoints(1,:),boxPoints(2,:),'b');
            end
            
            % Draw line connecting robots to their targets
            if robotProperties(i,1) ~= 0
                target_line_x = [targets(robotProperties(i,1),1) position(i,1)];
                target_line_y = [targets(robotProperties(i,1),2) position(i,2)];
                plot(target_line_x , target_line_y, 'r');
            end
            
            % Draw a line to current advisor (if we have one)
            if(config.advice.enabled == 1)
                advisor_id = robots(i).individual_learning_.advice_.advisor_id_;
                if (~isempty(advisor_id))
                    start_pt = position(i,1:2);
                    end_pt = position(advisor_id,1:2);
                    advisor_line_x = [start_pt(1) end_pt(1)];
                    advisor_line_y = [start_pt(2) end_pt(2)];
                    plot(advisor_line_x, advisor_line_y, 'y');
                end
            end
            
        end

        % Draw the obstacles
        for i = 1:config.scenario.num_obstacles
            boxPoints = GetBox(obstacles(i,:), config.scenario.obstacle_size);
            plot(boxPoints(1,:),boxPoints(2,:),'r');
        end

        % Draw the targets
        for i = 1:config.scenario.num_targets
            boxPoints = GetBox(targets(i,:), config.scenario.target_size);
            
            if targetProperties(i,1) == 0
                plot(boxPoints(1,:),boxPoints(2,:),'g');
                if targetProperties(i,2) == 2
                    plot(boxPoints(1,:),boxPoints(2,:)+0.05,'g');
                end
            else
                plot(boxPoints(1,:),boxPoints(2,:),'r');
            end
        end

        % Draw the goal location
        boxPoints = GetBox(goal_position, config.scenario.goal_size);
        plot(boxPoints(1,:),boxPoints(2,:),'k');
        
         % Set axis
        axis([0 config.scenario.world_width 0 config.scenario.world_height]);
        
        drawnow limitrate;
    end


    % If requested, plot the final robot and target tracks
    if(config.sim.show_track_graphics && (world_state.iterations_ >= config.scenario.max_iterations || world_state.GetConvergence() == 2))

        % Open a new figure
        %figure
        
        % TODO
        % Need to store all related data somewhere
        % Old (not-working) code is below
        
    %
    %     % Output Robot Tracks
    %     for i=1:this.numRobots
    %         hold all
    %         plot(reshape(this.posData(i,1,:),1,[]),reshape(this.posData(i,2,:),1,[]));
    %         drawnow;
    %     end
    %     
    %     % Output Target Tracks
    %     for i=1:this.numTargets
    %         hold all
    %         plot(reshape(this.targData(i,1,:),1,[]),reshape(this.targData(i,2,:),1,[]));
    %         drawnow;
    %     end
    %     
    %     % Output Robot Representation
    %     for i=1:this.numRobots
    %         point = this.posData(i,:,this.numIterations);
    %         boxPoints = GetBox(point,0.5);
    %         hold all
    %         plot(boxPoints(1,:),boxPoints(2,:),'b');
    %     end
    %     
    %     % Output Obstacle Locations
    %     for i=1:this.numObstacles
    %         point = obstacles(i,:);
    %         boxPoints = GetBox(point,0.5);
    %         hold all
    %         plot(boxPoints(1,:),boxPoints(2,:),'r');
    %     end
    %     
    %     % Output Target Locations
    %     for i=1:this.numTargets
    %         point = targets(i,:);
    %         boxPoints = GetBox(point,0.5);
    %         hold all
    %         plot(boxPoints(1,:),boxPoints(2,:),'g');
    %     end
    %     
    %     % Output Goal Location
    %     point = goal_position;
    %     boxPoints = GetBox(point,1);
    %     hold all
    %     plot(boxPoints(1,:),boxPoints(2,:),'k');
    end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   GetBox
%
%   For plotting purposes, returns an array of data
%   points centred at 'point', and with radius of 'size'

function boxPoints = GetBox(point, size)
    ang = 0:0.01:2*pi;
    xp = size*cos(ang);
    yp = size*sin(ang);
    boxPoints = [point(1) + xp; point(2) + yp];
end
