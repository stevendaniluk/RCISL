%% Q-Value Analysis Script

% For investigating patterns in the Q-values throughout the
% learning process.

% Data for q_tables, state_q_data, and simulation_data 
% must be loaded in prior to use!

% Quality analysis
plot_learned_q_vals = false;
plot_online_q_vals = true;
save_video = true;

% Online Q-Value Settings
iter_delta = 1000;
iter_start = 1;
vid_filename='test';
video_framerate = 10;

% General settings
actions = 5;
robot = 1;
plot_axis = [0, 0.12, -0.1, 0.4];

%% For observing a batch of Q-values after learning
if (plot_learned_q_vals)
    % Get qualities, and reshape into one row for each state, 
    % one column for each action
    q_table = full(q_tables{robot});
    q_table = reshape(q_table, [length(q_table)/actions, actions]);

    % Collect quality metrics into a data matrix
    %   Col 1: Variance
    %   Col 2: Mean
    data = zeros(size(q_table, 1), 2);
    data(:, 1) = var(q_table, 0, 2);
    data(:, 2) = sum(q_table, 2)/actions;
    
    % Find which states have a positive Q value
    pos_q_indices = sum(q_table > 0, 2) > 0;
    
    % Get metrics for states with a positive Q
    var_pos_reward = data(pos_q_indices, 1);
    mean_pos_reward = data(pos_q_indices, 2);
    
    % Get metrics for states with negative Q's
    var_neg_reward = data(~pos_q_indices, 1);
    mean_neg_reward = data(~pos_q_indices, 2);
    
    figure(1)
    hold on
    plot(var_pos_reward, mean_pos_reward, 'bo');
    plot(var_neg_reward, mean_neg_reward, 'rx');
    hold off
    xlabel('Variance')
    ylabel('Mean')
    title(['Metrics From Learned Q-Values for ', num2str(length(simulation_data.iterations)), ' Runs'])
    axis(plot_axis)
    legend('+ve Q-Value Present', '-ve Q-Values Only')
    
end

%% For observing Q-values online during learning
if (plot_online_q_vals)
    
    if (save_video)
        % Create AVI video file
        vid = VideoWriter(vid_filename);	% Video object
        
        % Set video parameters
        vid.Quality = 100;					% Range of [0, 100]
        vid.FrameRate = video_framerate;	% Frames per second in video
        
        % Open video file for writing
        open(vid);
    end
    
    % Set which iterations should be included
    total_iters = sum(simulation_data.iterations);
    if (save_video)
        index_end = total_iters;
    else
        index_end = iter_start;
    end
    
     for index_start=iter_start:iter_delta:index_end
        % Adjust the end index
        index_end = index_start + iter_delta;
        index_end = min(index_end, total_iters);

        % Extract the proper Q values
        q_vals = state_q_data{robot}.vals(index_start:index_end, :);
        reward_sign = state_q_data{robot}.reward_sign(index_start:index_end, :);
        
        % Soft into positive and negative reward Q's
        pos_reward_qs_in = q_vals(reward_sign == 1, :);
        neg_reward_qs_in = q_vals(reward_sign == 0, :);
        
        % Get metrics
        var_pos_reward = var(pos_reward_qs_in, 0, 2);
        mean_pos_reward = sum(pos_reward_qs_in, 2)/actions;
        var_neg_reward = var(neg_reward_qs_in, 0, 2);
        mean_neg_reward = sum(neg_reward_qs_in, 2)/actions;
        
        % Plot
        f = figure(2);
        x_string = 'Variance';
        y_string = 'Mean';
        title_string = ['Reward Q-Value Data For ', num2str(iter_delta), ...
                     ' Iterations Starting at ', num2str(index_start), ...
                     ' (Total: ', num2str(total_iters), ')'];
        hold on
        subplot(2,1,1)
        plot(var_pos_reward, mean_pos_reward, 'bx');
        xlabel(x_string)
        ylabel(y_string)
        title(['+ve ', title_string]);
        axis(plot_axis)
        hold on
        subplot(2,1,2)
        plot(var_neg_reward, mean_neg_reward, 'rx');
        xlabel(x_string)
        ylabel(y_string)
        title(['-ve ', title_string]);
        axis(plot_axis)
        
        if (save_video)
            % Get and write frames for video
            writeVideo(vid,getframe(f));
        end
     end
     
     if (save_video)
         % When finished, close the video file
         close(vid);
     end
end
