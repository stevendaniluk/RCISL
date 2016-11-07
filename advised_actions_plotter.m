%% Advices Actions Plotter

% Reads in simulations data for every simulation listed in the sim_names
% cell. Ratio of advised actions will have a moving average applied, then
% will be averaged over all simulations.
%
% The filenames have the form "folder_name/sim_name_", and a number is
% appended to the filenames to load in the data for each simulation.

clear

% General settings
sim_names = {'a_dev_320_advisor'; 'a_dev_160_advisor'; 'a_dev_80_advisor'; 'a_dev_40_advisor'; 'a_dev_20_advisor'; 'a_dev_10_advisor'; 'a_dev_5_advisor'; 'a_dev_320_advisor_evil'};
num_sims = [20; 20; 20; 20; 20; 20; 20; 20];
num_runs = [150; 150; 150; 150; 150; 150; 150; 150];
legend_names = {'320'; '160'; '80'; '40'; '20'; '10'; '5'; 'Evil'};   % Optional: Manually set legend names
smooth_pts = 10;
iter_axis_max = 1000;

% Input error check
if (~isequal(length(sim_names), length(num_sims), length(num_runs)))
    error('Arrays of simulation names, number of sims, and numebr of runs, are not the same size.')
    return;
end

f = figure;
clf
hold on
ratio = cell(length(sim_names), 1);
for i = 1:length(sim_names)
    name = sim_names{i};
    filename = [name, '/sim_'];
    
    % Load the data
    ratio{i} = zeros(num_sims(i), num_runs(i));
    for j=1:num_sims(i)
        load(['results/', filename, sprintf('%d', j), '/', 'advice_data']);
        ratio{i}(j,:) = advice_data{1}.advised_actions_ratio;
    end
    
    % Average and smooth
    ratio{i} = sum(ratio{i}, 1) / num_sims(i);
    ratio{i} = smooth(ratio{i}, smooth_pts)';
        
    % Plot the iterations
    plot(1:num_runs(i), 100*ratio{i})
end

% Annotate plot
title('Percent of Actions That Were Advised');
xlabel('Epoch');
ylabel('Advised Actions [%]');
axis([0, min(num_runs), 0, 100]);
if (isempty(legend_names))
    legend(sim_names);
else
    legend(legend_names);
end
