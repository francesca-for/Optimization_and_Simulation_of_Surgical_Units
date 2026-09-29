clear
close all
clc

%% ================ EMERGENCY SCENARIO parameters ================

% --- Service times (hours) for Appendectomy
tau_A_1 = 1;    % Stage 1
tau_A_2 = 2;    % Stage 2
tau_A_3 = 0.5;  % Stage 3

% --- Service times (hours) for Tonsillectomy
tau_T_1 = 0.5;  
tau_T_2 = 2;    
tau_T_3 = 1.5;

% --- Arrival rates
lambdaA = 1;  % patients/hour (Appendectomy)
lambdaT = 2;  % patients/hour (Tonsillectomy)

%% ===================== PART 1: SIMULATION (ARBITRARY VALUES) =====================

% Choose an arbitrary set of rooms
v_m1 = [1 2 3 5 10 50];  % rooms in stage 1
v_m2 = [1 2 3 4 6 50];  % rooms in stage 2
v_m3 = [1 3 5 7 10 50];  % rooms in stage 3

for i = 1: length(v_m1)
    m1 = v_m1(i); m2 = v_m2(i); m3 = v_m3(i);

    % Open the Simulink model (make sure "emergency_scenario.slx" is on the path)
    open_system('emergency_scenario');
    
    % Run the simulation
    simOut = sim('emergency_scenario','StopTime','10000');
    [mean_SA, mean_ST, mean_TF] = computeFlowTimes(simOut);

    fprintf('-------------- SIMULATION RESULTS (ARBITRARY VALUES) --------------\n');
    fprintf('m1 = %d, m2 = %d, m3 = %d\n', m1, m2, m3);
    fprintf('Average flow time (Appendectomy patients) SA: %.2f hours\n', mean_SA);
    fprintf('Average flow time (Tonsillectomy patients) ST: %.2f hours\n', mean_ST);
    fprintf('Total Average flow time (all patients): %.2f hours\n', mean_TF);
end

%% ===================== PART 2: EXHAUSTIVE SEARCH + LP SOLVER =====================

% Threshold on the overall average flow time
Smax = 20;

% Define search ranges for (m1, m2, m3)
range_m1 = 1:10;
range_m2 = 1:10;
range_m3 = 1:10;

% Define costs (k€) for each room
cost_stage1 = 10;  
cost_stage2 = 50;
cost_stage3 = 2;

% Arrays to collect feasible combinations and results
Comb     = [];  % (m1, m2, m3)
Svals    = [];  % average flow time (all patients)
Costvals = [];  % cost for each combination

% Loop over all (m1, m2, m3)
for m1 = range_m1
    for m2 = range_m2
        for m3 = range_m3
            
            % Run the simulation for a sufficiently large StopTime
            simOut = sim('emergency_scenario','StopTime','10000');
            
            % Calculate the overall average flow time (all patients)
            meanS_all = computeTotalFlowTime(simOut);
            
            % Keep this combination if meanS_all <= Smax
            if meanS_all <= Smax
                cost = cost_stage1*m1 + cost_stage2*m2 + cost_stage3*m3;
                
                Comb     = [Comb; m1, m2, m3];
                Svals    = [Svals; meanS_all];
                Costvals = [Costvals; cost];
            end
            
        end
    end
end

% Check how many feasible combinations we have
nFeas = size(Comb,1);
if nFeas == 0
    warning('No combination found with average flow time <= %.1f hours.', Smax);
    return;
end

% Build the LP model
% x(i) = 1 if we pick combination i, 0 otherwise

x = optimvar('x', nFeas, 'Type', 'integer', 'LowerBound', 0, 'UpperBound', 1);

% Objective: minimize sum(cost * x)
obj = sum(Costvals .* x);

mProblem = optimproblem;
mProblem.Objective = obj;

% Constraint: exactly one combination must be chosen
mProblem.Constraints.OneCombo = sum(x) == 1;

% Solve with intlinprog
[Sol, fval] = solve(mProblem, 'solver', 'intlinprog');

% Retrieve solution
bestCost = fval;
chosenIdx = find(Sol.x);

if length(chosenIdx) ~= 1
    warning('The solver did not return a single combination (exitflag = %d).', exitflag);
else
    best_m1 = Comb(chosenIdx,1);
    best_m2 = Comb(chosenIdx,2);
    best_m3 = Comb(chosenIdx,3);
    bestS   = Svals(chosenIdx);
    
    fprintf('\n---------- OPTIMIZATION RESULTS (LP SOLVER) ----------\n');
    fprintf('Selected Combination: m1=%d, m2=%d, m3=%d\n', best_m1, best_m2, best_m3);
    fprintf('Total Average flow time (all patients) = %.2f hours\n', bestS);
    fprintf('Total Cost = %.0f k€\n', bestCost);
end

%% ======= OPTIMIZATION RESULTS Plot ======= 

cost_flow = [Costvals, Svals];
% Sort and extract data
cost_flow = sortrows(cost_flow, 1);

% Extract data
x_values = cost_flow(:, 1); % Cost
y_values = cost_flow(:, 2); % Flow Time

% Plot 
figure;
plot(x_values, y_values, '-o', 'MarkerFaceColor', 'blue', 'MarkerEdgeColor', 'black', 'MarkerSize', 3);

% Set axis labels and title
xlabel('Cost');
ylabel('AVG Flow Time');
title('Cost vs AVG Flow Time');

% Enable and customize the grid
grid on; % Enable the grid

%% ====================== LOCAL FUNCTIONS ====================== 

function [mean_SA, mean_ST, mean_TF] = computeFlowTimes(simOut)
    % Extract arrival/departure data
    arrival_data   = simOut.id_Arrival.Data;   
    arrival_time   = simOut.id_Arrival.Time;   
    departure_data = simOut.id_finalDeparture.Data;  
    departure_time = simOut.id_finalDeparture.Time;
    
    arrival_type   = simOut.type_Arrival.Data;       
    departure_type = simOut.type_finalDeparture.Data;
    
    % Check for incomplete entities
    missing_ids = setdiff(arrival_data, departure_data);
    if ~isempty(missing_ids)
        warning('There are %d entities that have not completed the process.', length(missing_ids));
    end
    
    % Compute flow times
    flow_time_A = [];
    flow_time_T = [];
    totalFlow_time = [];
    
    for i = 1:length(departure_data)
        id_out = departure_data(i);
        idx = find(arrival_data == id_out, 1);
        
        if ~isempty(idx)
            flow_time = departure_time(i) - arrival_time(idx);
            totalFlow_time = [totalFlow_time; flow_time];
            
            if departure_type(i) == 1  % Appendectomy
                flow_time_A = [flow_time_A; flow_time];
            elseif departure_type(i) == 2  % Tonsillectomy
                flow_time_T = [flow_time_T; flow_time];
            end
        end
    end
    
    % Calculate mean flow times
    if ~isempty(flow_time_A)
        mean_SA = mean(flow_time_A);
    else
        mean_SA = NaN;
    end
    
    if ~isempty(flow_time_T)
        mean_ST = mean(flow_time_T);
    else
        mean_ST = NaN;
    end
    
    
    if ~isempty(totalFlow_time)
        mean_TF = mean(totalFlow_time);
    else
        mean_TF = NaN;
    end
end

%  -------------------------------------------------------------

function meanS_all = computeTotalFlowTime(simOut)

    arrival_data   = simOut.id_Arrival.Data;
    arrival_time   = simOut.id_Arrival.Time;
    
    departure_data = simOut.id_finalDeparture.Data;
    departure_time = simOut.id_finalDeparture.Time;
    
    % Flow times array
    flow_times = zeros(length(departure_data),1);
    for iEnt = 1:length(departure_data)
        id_out = departure_data(iEnt);
        idx_in = find(arrival_data == id_out, 1);
        if ~isempty(idx_in)
            flow_times(iEnt) = departure_time(iEnt) - arrival_time(idx_in);
        end
    end
    
    meanS_all = mean(flow_times);
end

