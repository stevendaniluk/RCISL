%% Results Plotter

% Reads in simulations data for every simulation listed in the sim_names
% cell. Iterations will have a moving average applied, then will be
% averaged over all simulations.
%
% The filenames have the form "folder_name/sim_name_", and a number is
% appended to the filenames to load in the data for each simulation.

clear
clf

% General settings
sim_names = {'pro_test'; '4_bots_no_advice_200'};
num_sims = [2; 5];
num_runs = [300; 200];
legend_names = {};   % Optional: Manually set legend names
smooth_pts = 10;
iter_axis_max = 1000;

% Input error check
if (~isequal(length(sim_names), length(num_sims), length(num_runs)))
    error('Arrays of simulation names, number of sims, and numebr of runs, are not the same size.')
    return;
end

f = figure(1);
hold on
iters = cell(length(sim_names), 1);
for i = 1:length(sim_names)
    name = sim_names{i};
    filename = [name, '/sim_'];
    
    % Load the data
    iters{i} = zeros(num_sims(i), num_runs(i));
    for j=1:num_sims(i)
        load(['results/', filename, sprintf('%d', j), '/', 'simulation_data']);
        iters{i}(j,:) = simulation_data.iterations;
    end
    
    % Average and smooth
    iters{i} = sum(iters{i}, 1) / num_sims(i);
    iters{i} = smooth(iters{i}, smooth_pts)';
        
    % Plot the iterations
    plot(1:num_runs(i), iters{i})
end

% Annotate plot
title('Mission Iterations');
xlabel('Run Number');
ylabel('Iterations');
axis([0, max(num_runs), 0, iter_axis_max]);
if (isempty(legend_names))
    legend(sim_names);
else
    legend(legend_names);
end
