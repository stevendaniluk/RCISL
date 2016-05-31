% Iterations Plotter
clear

filename = '';
num_tests = 10;
num_runs = 300;

iterations = zeros(num_tests, num_runs);

% Load iterations from each test
for i=1:num_tests
    load(['results/', filename, sprintf('%d', i), '/', 'simulation_data']);
    iterations(i,:) = cell2mat(simulation_data(1:num_runs, 1));
end

% Average
avg_iterations = sum(iterations, 1) / num_tests;

%% Smooth with 10 point moving average
pts = 10;

smooth_iterations = zeros(size(avg_iterations));
SMA_now = avg_iterations(1);
smooth_iterations(1) = SMA_now;

for i=2:num_runs
    SMA_prev = SMA_now;
    if (i < pts)
       SMA_now = sum(avg_iterations(1:i))/i;
    else
        SMA_now = SMA_prev + avg_iterations(i)/pts - avg_iterations(i - pts + 1)/pts;
    end    
    
    smooth_iterations(i) = SMA_now;
end

%% Plot
plot(1:num_runs, smooth_iterations)
title('Average Iterations');
xlabel('Number of Runs');
ylabel('Iterations');
axis([0, num_runs, 0, 5000]);
