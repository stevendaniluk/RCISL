%% Developmental Advice Plotter

% Reads in recorded advice data for the developmental advice mechanism, 
% then plots the metrics for the team and/or the individual robots
%
% The filenames have the form "folder_name/sim_name_", and a number is
% appended to the filenames to load in the data for each simulation.
%
% Generates advisor and advisee plots for:
%   -Average action Q value (decaying moving average)
%   -Average action entropy (decaying moving average)
%
% Generates advisee only plots for:
%   -Accept action Q value
%   -Reject action Q value
%   -Advice reward
%   -Advised actions percentage
%   -Number of advice states visited

clear
clf

% Input data settings
folder = 'test_v2_320_advisor';
sim_num = 1;
num_advice_states = 200;

% Plot settings
plot_by_epoch = true;
save_plots = false;
iter_smooth_pts = 100;
epoch_smooth_pts = 10;

%% Prepare to load data

% Append sime names to path
advice_filename = [folder, '/sim_'];

% Create new directory if needed
if (save_plots)
    if ~exist(['results/', folder, '/figures'], 'dir')
        mkdir(['results/', folder], 'figures');
    end
end

%% Process the advice data

% Load the data
load(['results/', advice_filename, sprintf('%d', sim_num), '/', 'advice_data']);

% Which iterations were, and were not advised
advised_indices = (advice_data{1}.advisor ~= 1);
advised_iters = find(advised_indices);
non_advised_iters = find(~advised_indices);

% Metrics from advice data
if (plot_by_epoch)
    avg_q = advice_data{1}.a_dev.avg_q_epoch;
    local_avg = advice_data{1}.a_dev.local_avg_epoch;
    advisor_avg_q = advice_data{1}.a_dev.advisor_avg_q_epoch;
    advisor_local_avg = advice_data{1}.a_dev.advisor_local_avg_epoch;
    accept_q = advice_data{1}.a_dev.accept_q_epoch;
    reject_q = advice_data{1}.a_dev.reject_q_epoch;
    reward = advice_data{1}.a_dev.reward_epoch;
    num_states_visited = advice_data{1}.a_dev.num_states_visited_epoch;
    advice_state_val = advice_data{1}.a_dev.advice_state_val_epoch;
    %advised_actions_ratio_moving = advice_data{1}.a_dev.advised_actions_ratio_epoch;
    pride = advice_data{1}.a_dev.pride_epoch;
    
    smooth_pts = epoch_smooth_pts;
else
    avg_q = advice_data{1}.a_dev.avg_q_iter;
    local_avg = advice_data{1}.a_dev.local_avg_iter;
    advisor_avg_q = advice_data{1}.a_dev.advisor_avg_q_iter;
    advisor_local_avg = advice_data{1}.a_dev.advisor_local_avg_iter;
    accept_q = advice_data{1}.a_dev.accept_q_iter;
    reject_q = advice_data{1}.a_dev.reject_q_iter;
    reward = advice_data{1}.a_dev.reward_iter;
    num_states_visited = advice_data{1}.a_dev.num_states_visited_iter;
    advice_state_val = advice_data{1}.a_dev.advice_state_val_iter;
    %advised_actions_ratio_moving = advice_data{1}.a_dev.advised_actions_ratio_iter;
    pride = advice_data{1}.a_dev.pride_iter;
    
    smooth_pts = iter_smooth_pts;
end
advised_actions_ratio = advice_data{1}.advised_actions_ratio;

% Smooth the data
avg_q = smooth(avg_q, smooth_pts);
local_avg = smooth(local_avg, smooth_pts);
advisor_avg_q = smooth(advisor_avg_q, smooth_pts);
advisor_local_avg = smooth(advisor_local_avg, smooth_pts);
accept_q = smooth(accept_q, smooth_pts);
reject_q = smooth(reject_q, smooth_pts);
reward = smooth(reward, smooth_pts);
pride = smooth(pride, smooth_pts);

advised_actions_ratio = smooth(advised_actions_ratio, epoch_smooth_pts);

% Make vector of epochs/iterations to plot data against
num_epochs = length(advised_actions_ratio);
num_iters = length(avg_q);

if (plot_by_epoch)
    x_length = num_epochs;
    x_label_string = 'Epochs';
else
    x_length = num_iters;
    x_label_string = 'Iterations';
end
x_vector = 1:x_length;

%% Plot advisor and advisee metrics
f1 = figure(1);
clf

% Average Q
subplot(4,1,1)
hold on
plot(x_vector, avg_q)
plot(x_vector, advisor_avg_q)
title('Robot Individual Learning Average Action Quality');
xlabel(x_label_string);
ylabel('Q_a_v_g');
axis([1, x_length, 0, 0.3]);
legend('Advisee', 'Advisor');

% Local metric (entropy)
subplot(4,1,2)
hold on
plot(x_vector, local_avg) 
plot(x_vector, advisor_local_avg) 
title('Advice Local Average Metric');
xlabel(x_label_string);
ylabel('H_a_v_g');
axis([1, x_length, 0, 2.5]);
legend('Advisee', 'Advisor');

% Advice state value
subplot(4,1,3)
plot(x_vector, advice_state_val)
title('Advice State [0, 1]');
xlabel(x_label_string);
ylabel('Value');
axis([1, x_length, 0, 1]);

% Pride
subplot(4,1,4)
plot(x_vector, pride)
title('Pride');
xlabel(x_label_string);
ylabel('Pride');
axis([1, x_length, -0.15, 0.15]);
%axis([1, x_length, 0, 1.0]);
ref_line = refline([0 0]);
ref_line.Color = 'r';
ref_line.LineStyle = '--';

% Save (if desired)
if (save_plots)
    savefig(f1, ['results/', folder, '/figures/Advice_Dev_Metrics_1.fig']);
end

%% Plot advisee metrics
f2 = figure(2);
clf

% Quality of advice actions
subplot(4,1,1)
hold on
plot(x_vector, accept_q);
plot(x_vector, reject_q);
title('Quality of Advice Actions')
xlabel(x_label_string);
ylabel('Q')
axis([1, x_length, -0.15, 0.15]);
%axis([1, x_length, -1.5, 1.5]);
ref_line = refline([0 0]);
ref_line.Color = 'r';
ref_line.LineStyle = '--';
legend('Accept', 'Reject');

% Advice reward
subplot(4,1,2)
plot(x_vector, reward);
title('Reward Received For Advice Action')
xlabel(x_label_string);
ylabel('R')
axis([1, x_length, -0.15, 0.15]);
%axis([1, x_length, -1.0, 1.0]);
ref_line = refline([0 0]);
ref_line.Color = 'r';
ref_line.LineStyle = '--';

% Advices actions percentage
subplot(4,1,3)
hold on
plot(1:num_epochs, 100*advised_actions_ratio)
%plot(x_vector, 100*advised_actions_ratio_moving)
title('Percent of Actions That Were Advised');
xlabel('Epochs');
ylabel('Advised Actions [%]');
axis([0, num_epochs, 0, 100]);
%legend('Per Epoch', 'Moving')

% Number of advice states visited
subplot(4,1,4)
plot(x_vector, 100*num_states_visited/num_advice_states)
title('Percent of Advice States Visited')
xlabel(x_label_string);
ylabel('Percent of States [%]')
axis([1, x_length, 0, 110]);
ref_line = refline([0 100]);
ref_line.Color = 'r';
ref_line.LineStyle = '--';

% Save (if desired)
if (save_plots)
    savefig(f2, ['results/', folder, '/figures/Advice_Dev_Metrics_2.fig']);
end

