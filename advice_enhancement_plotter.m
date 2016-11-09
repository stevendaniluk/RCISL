%% Advice Enhancement Plotter
%
% Reads in recorded advice data for the advice enhancement mechanism, 
% then plots the metrics an individual robot
%
% The filenames have the form "folder_name/sim_name_", and a number is
% appended to the filenames to load in the data for each simulation.
%
% Generates plots for:
%   -k_o_bar
%   -k_hat_bar
%   -delta_k
%   -beta_m
%   -beta_hat

%clear
clf

% Input data settings
folder = 'test';
sim_num = 1;
robot = 1;

% Plot settings
plot_by_epoch = true;
save_plots = false;
iter_smooth_pts = 100;
epoch_smooth_pts = 5;

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
    k_o_bar = advice_data{robot}.a_enh.k_o_bar_epoch;
    k_hat_bar = advice_data{robot}.a_enh.k_hat_bar_epoch;
    delta_k = advice_data{robot}.a_enh.delta_k_epoch;
    beta_m = advice_data{robot}.a_enh.beta_m_epoch;
    beta_hat = advice_data{robot}.a_enh.beta_hat_epoch;
    max_p_a_in = advice_data{robot}.a_enh.max_p_a_in_epoch;
    max_p_a_out = advice_data{robot}.a_enh.max_p_a_out_epoch;
        
    smooth_pts = epoch_smooth_pts;
else
    k_o_bar = advice_data{robot}.a_enh.k_o_bar_iter;
    k_hat_bar = advice_data{robot}.a_enh.k_hat_bar_iter;
    delta_k = advice_data{robot}.a_enh.delta_k_iter;
    beta_m = advice_data{robot}.a_enh.beta_m_iter;
    beta_hat = advice_data{robot}.a_enh.beta_hat_iter;
    max_p_a_in = advice_data{robot}.a_enh.max_p_a_in_iter;
    max_p_a_out = advice_data{robot}.a_enh.max_p_a_out_iter;
    
    smooth_pts = iter_smooth_pts;
end
advised_actions_ratio = advice_data{1}.advised_actions_ratio;

% Smooth the data
k_o_bar = smooth(k_o_bar, smooth_pts);
k_hat_bar = smooth(k_hat_bar, smooth_pts);
delta_k = smooth(delta_k, smooth_pts);
beta_m = smooth(beta_m, smooth_pts);
beta_hat = smooth(beta_hat, smooth_pts);
max_p_a_in = smooth(max_p_a_in, smooth_pts);
max_p_a_out = smooth(max_p_a_out, smooth_pts);

advised_actions_ratio = smooth(advised_actions_ratio, epoch_smooth_pts);

% Make vector of epochs/iterations to plot data against
num_epochs = length(advised_actions_ratio);
num_iters = length(k_o_bar);

if (plot_by_epoch)
    x_length = num_epochs;
    x_label_string = 'Epochs';
else
    x_length = num_iters;
    x_label_string = 'Iterations';
end
x_vector = 1:x_length;

%% Plot K metrics
f1 = figure(1);
clf

% Original and enhanced knowledge
subplot(3,1,1)
hold on
plot(x_vector, k_o_bar)
plot(x_vector, k_hat_bar)
title('Knowledge Values');
xlabel(x_label_string);
ylabel('||K||_1');
axis([1, x_length, 0, 1.0]);
legend('K_o', 'K_h_a_t');

% Change in knowledge
subplot(3,1,2)
hold on
plot(x_vector, delta_k) 
title('Change in knowledge');
xlabel(x_label_string);
ylabel('\Delta K');
axis([1, x_length, -0.5, 0.5]);
ref_line = refline([0 0]);
ref_line.Color = 'r';
ref_line.LineStyle = '--';

% Agreement
subplot(3,1,3)
hold on
plot(x_vector, beta_m)
plot(x_vector, beta_hat)
title('Agreement');
xlabel(x_label_string);
ylabel('\beta');
axis([1, x_length, -0.1, 0.3]);
legend('\beta_m', '\beta_h_a_t');
ref_line = refline([0 0]);
ref_line.Color = 'r';
ref_line.LineStyle = '--';

% Save (if desired)
if (save_plots)
    savefig(f1, ['results/', folder, '/figures/Advice_Dev_Metrics_1.fig']);
end
