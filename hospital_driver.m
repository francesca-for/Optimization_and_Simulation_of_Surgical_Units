clear
close all
clc

%% ================ HOSPITAL SCENARIO parameters ================

% Mean service time (in hours) for each stage of appendectomy
% Stage 1, Stage 2, Stage 3
tau_A_1 = 1;
tau_A_2 = 2;
tau_A_3 = 0.5;

% Mean service time (in hours) for each stage of tonsillectomy
% Stage 1, Stage 2, Stage 3
tau_T_1 = 0.5;
tau_T_2 = 2;
tau_T_3 = 1.5;

% Total number of patients to be simulated
N = 20;

% Number of available rooms for each stage of the hospital process
m1 = 1;  % Rooms in stage 1
m2 = 1;  % Rooms in stage 2
m3 = 1;  % Rooms in stage 3

%% === Compute average flow time using RANDOM patient ordering ===

opt = 0;
mean_S_random = run_simulation();
fprintf("\nSimulation Result: RANDOM ORDER \n");
fprintf("Average Flow Time: %.2f hours\n", mean_S_random);
fprintf("----------------------------------------------------------\n");

%% === Compute average flow time using OPTIMIZED patient ordering (Greedy Heuristic) ===

opt = 1;
mean_S_greedy = run_simulation();
fprintf("\nSimulation Result: GREEDY HEURISTIC OPTIMIZED ORDER \n");
fprintf("Average Flow Time: %.2f hours\n", mean_S_greedy);
fprintf("----------------------------------------------------------\n");

%% === COMPARISON BETWEEN UNOPTIMIZED and OPTIMIZED RESULTS ===

% Print both results in a formatted way for easy comparison
fprintf("******************** FINAL COMPARISON ********************\n");
fprintf("UNOPTIMIZED (Random) AVG FLOW TIME: %.2f hours\n", mean_S_random);
fprintf("OPTIMIZED (Greedy Heuristic) AVG FLOW TIME emergency_scenario : %.2f hours\n", mean_S_greedy);

%% FUNCTION DEFINITIONS

function mean_S = run_simulation()
    % Open and simulate the Simulink model for the hospital scenario
    open_system('hospital_scenario');
    simOut = sim('hospital_scenario');
    
    % Extract arrival and departure data from the simulation results
    [arrival_data, arrival_time] = get_arrival_data(simOut);
    [departure_data, departure_time] = get_departure_data(simOut);
    
    % Compute flow time for completed entities
    flow_time_S = calculate_flow_time(arrival_data, arrival_time, departure_data, departure_time);
    
    % Compute and return the mean flow time
    if ~isempty(flow_time_S)
        mean_S = mean(flow_time_S);
    else
        mean_S = NaN;
    end
end

function [arrival_data, arrival_time] = get_arrival_data(simOut)
    % Retrieve the entity arrival IDs and corresponding times from simulation output
    arrival_data = simOut.id_Arrival.Data;
    arrival_time = simOut.id_Arrival.Time;
end

function [departure_data, departure_time] = get_departure_data(simOut)
    % Retrieve the entity departure IDs and corresponding times from simulation output
    departure_data = simOut.id_finalDeparture.Data;
    departure_time = simOut.id_finalDeparture.Time;
end

function flow_time_S = calculate_flow_time(arrival_data, arrival_time, departure_data, departure_time)
    % Calculate the flow time for each entity that has completed the hospital process
    flow_time_S = [];
    for i = 1:length(departure_data)
        id_out = departure_data(i);
        idx = find(arrival_data == id_out, 1); % Find corresponding arrival index
        if ~isempty(idx)
            flow_time = departure_time(i) - arrival_time(idx); % Compute flow time
            flow_time_S = [flow_time_S; flow_time];
        end
    end
end
