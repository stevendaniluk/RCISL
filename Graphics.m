% GRAPHICS - Generates simulation graphics from the world and robot states

% Called at each iteration of the simulation.
%
% Can generate live graphics, or plot the tracks of each robot and target
% after the run is completed, as dictated by the show_live_graphics and
% show_track_graphics parameters in the configuration.

% INPUTS
% config = Configuration object being used
% world_state = WorldState object
% robots = Array of Robot objects

function [] = Graphics(config, world_state, robots)
% If requested, display the live graphics during the run
if(config.sim.show_live_graphics)
  clf
  cla
  hold on;
  
  % Display current iteration
  text(1, 9, sprintf('%d', world_state.mission_.iters));
  
  % Draw the robots
  for i=1:config.scenario.num_robots
    
    % Create arrow to represent each robot's true position
    arrow = zeros(5,2);
    arrow(:, 1) = world_state.robots_(i).x;
    arrow(:, 2) = world_state.robots_(i).y;
    
    ang = world_state.robots_(i).theta;
    len = 0.5;
    
    arrow(1,1:2) = [arrow(1,1) - len*cos(ang), arrow(1,2) - len*sin(ang)];
    arrow(2,1:2) = [arrow(2,1) + len*cos(ang), arrow(2,2) + len*sin(ang)];
    arrow(3,1:2) = [arrow(3,1) + 0.1*cos(ang)+0.1*sin(ang), ...
      arrow(3,2) + 0.1*sin(ang)+0.1*cos(ang)];
    arrow(4,1:2) = [arrow(4,1) + 0.1*cos(ang)-0.1*sin(ang), ...
      arrow(4,2) + 0.1*sin(ang)-0.1*cos(ang)];
    arrow(5,1:2) = [arrow(5,1) + len*cos(ang), arrow(5,2) + len*sin(ang)];
    
    % Draw arrow for each robot
    plot(arrow(:, 1), arrow(:, 2), 'b');
    
    % Add text for robot id, type, and current action
    label = sprintf('%d - %s', i, robots(i).prop_.label);
    text(world_state.robots_(i).x + 0.2, world_state.robots_(i).y + 0.2, label);
    
    % If noise is present, plot the state estimates
    if(config.noise.sigma > 0)
      
      
      % Draw the robots current belief about its own position
      circle_points = getCircle(robots(i).robot_state_.pose_, 0.5*config.scenario.robot_size);
      plot(circle_points(1, :), circle_points(2, :), 'g');
      
      % Draw the robots current belief about its goal position
      circle_points = getCircle(robots(i).robot_state_.goal_, 0.1*config.scenario.goal_size);
      plot(circle_points(1, :), circle_points(2, :), 'b');
      
      % Draw the robots current belief about its target position
      circle_points = getCircle(robots(i).robot_state_.target_, 0.5*config.scenario.target_size);
      plot(circle_points(1, :), circle_points(2, :), 'b');
    end
    
    % Draw line connecting robots to their targets
    target_id = robots(i).robot_state_.target_.id;
    if (target_id ~= -1)
      target_line_x = [world_state.targets_(target_id).x, world_state.robots_(i).x];
      target_line_y = [world_state.targets_(target_id).y, world_state.robots_(i).y];
      plot(target_line_x , target_line_y, 'r');
    end
  end
  
  % Draw the obstacles
  for i = 1:config.scenario.num_obstacles
    circle_points = getCircle(world_state.obstacles_(i), config.scenario.obstacle_size);
    plot(circle_points(1, :), circle_points(2, :), 'r');
  end
  
  % Draw the targets
  for i = 1:config.scenario.num_targets
    circle_points = getCircle(world_state.targets_(i), config.scenario.target_size);
    if(world_state.targets_(i).returned)
      plot(circle_points(1, :), circle_points(2, :), 'r');
    elseif(strcmp(world_state.targets_(i).type, 'light'))
      plot(circle_points(1, :), circle_points(2, :), 'b');
    elseif(strcmp(world_state.targets_(i).type, 'heavy'))
      plot(circle_points(1, :), circle_points(2, :), 'g');
    end
  end
  
  % Draw the goal location
  circle_points = getCircle(world_state.goal_, config.scenario.goal_size);
  plot(circle_points(1, :), circle_points(2, :), 'k');
  
  % Set axis
  axis([0 config.scenario.world_width 0 config.scenario.world_height]);
  axis square
  
  drawnow limitrate;
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   getCircle
%
%   For plotting purposes, returns an array of data
%   points centred at 'pt', and with radius of 'r'

function circle_points = getCircle(pt, r)
angles = 0:0.01:2*pi;
xp = r*cos(angles);
yp = r*sin(angles);
circle_points = [pt.x + xp; pt.y + yp];
end
