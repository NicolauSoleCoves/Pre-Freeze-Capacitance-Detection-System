clear; clc; close all;

windowSize= 20;%Window of the movemean for C4
windowSize_diff = 40; %Window of the mean of diffC4

%% === Load latest saved file from your folder ===
folderPath = 'C:\Users\nicol\Desktop\TFG\muntatge\MATLAB\Experiments\C\ICE_WATER_SAMPLES\Ac_4_4';
baseName = 'V24V_d1.5cm_Ac16cm2_14';

load(baseName);  % loads: timeStamp_T, temperature, evmTimestamps, C4

% === Filter out invalid C4 values (less than 2 or greater than 15.8) ===
for i = 2:length(C4)
    if C4(i) < 2 || C4(i) > 15.8
        C4(i) = C4(i-1);  % Replace with previous value
    end
end

%% === Filter capacitance ===
windowSize = 50;
C4_filtered = movmean(C4, windowSize);
t_C = evmTimestamps;
t_T = timeStamp_T;

%% === Derivatives ===


dCdt = zeros(size(C4_filtered));
for i = 2:length(C4_filtered)-1
    dt_forward = t_C(i+1) - t_C(i);
    dt_backward = t_C(i) - t_C(i-1);
    dCdt(i) = (C4_filtered(i+1) - C4_filtered(i-1)) / (dt_forward + dt_backward);
end
% Edge values with forward/backward difference
dCdt(1) = (C4_filtered(2) - C4_filtered(1)) / (t_C(2) - t_C(1));
dCdt(end) = (C4_filtered(end) - C4_filtered(end-1)) / (t_C(end) - t_C(end-1));


dt = mean(diff(t_C));
dCdt = gradient(C4_filtered, dt);
d2Cdt2 = gradient(dCdt, dt);

smoothed_dCdt = movmean(dCdt, windowSize_diff);
%% === Select exothermic window and detect freezing point peak ===
figure;
plot(t_T, temperature);
ylim([-5,7])
title('Select window around the exothermic peak (click two points)');
xlabel('Time (s)'); ylabel('Temperature (°C)');

% Click two points to define time window
[t_start, ~] = ginput(1);
xline(t_start, '--k', 'Start');
[t_end, ~] = ginput(1);
xline(t_end, '--r', 'End');

% Ensure correct order
if t_start > t_end
    [t_start, t_end] = deal(t_end, t_start);
end

% Find indices in the selected window
idx_window = find(t_T >= t_start & t_T <= t_end);
[~, idx_local_max] = max(temperature(idx_window));
idx_f_exo_T = idx_window(idx_local_max);
t_f_exo = t_T(idx_f_exo_T);
T_peak = temperature(idx_f_exo_T);

% Get corresponding capacitance at t_f_exo
[~, idx_f_exo_C] = min(abs(t_C - t_f_exo));
C_at_freeze = C4_filtered(idx_f_exo_C);
[minC_pre, idx_min_pre] = min(C4_filtered(1:idx_f_exo_C));
drop_before_freeze = minC_pre - C_at_freeze;

fprintf('\n--- Exothermic Peak Detection ---\n');
fprintf('Freezing peak at t = %.2f s, T = %.2f °C\n', t_f_exo, T_peak);
fprintf('C_at_freeze = %.4f pF | Min before freeze = %.4f pF | ΔC = %.4e pF\n', ...
        C_at_freeze, minC_pre, drop_before_freeze);

close;

% Find C(t_f_exo)
[~, idx_f_exo] = min(abs(t_C - t_f_exo));
C_at_freeze = C4_filtered(idx_f_exo);
[minC_pre, idx_min_pre] = min(C4_filtered(1:idx_f_exo));
drop_before_freeze = minC_pre - C_at_freeze;

%% === Change detection (using std) ===
windowSizes = [5, 10, 20, 30];
std_windows = arrayfun(@(w) movstd(C4_filtered, w), windowSizes, 'UniformOutput', false);

%% === Plot everything ===
figure;
    subplot(2,1,1)
        hold on;
        yyaxis left
        plot(t_C, C4, 'Color', "#EDB120", 'DisplayName', 'Capacitance');
        plot(t_C, C4_filtered, "-k", 'DisplayName', 'Capacitance');
        plot(t_C(idx_min_pre), minC_pre, 'ko', 'DisplayName', 'Min Before Freeze');
        plot(t_C(idx_f_exo), C_at_freeze, 'kx', 'DisplayName', 'Freezing Point');
        plot(t_C(idx_f_exo_C), C_at_freeze, 'bo', 'MarkerFaceColor','b', 'DisplayName', 'C(t_f_{exo})');
        ylabel('C (pF)')
        ax = gca;
        ax.YColor = "#000000";
    
        yyaxis right
        plot(t_T, temperature, 'Color', "#A2142F", 'DisplayName', 'Temperature');
        plot(t_f_exo, T_peak, 'ro', 'MarkerFaceColor','r', 'DisplayName', 'Freezing Point (T peak)');
        ylabel('T (°C)');
        ax.YColor = "k";
    
        grid on;
        legend('Location', 'northeast');

    hold off
    
    subplot(2,1,2)
        hold on;
        yyaxis left
        plot(t_C, dCdt, '-', 'Color', "#0072BD", 'DisplayName', 'dC/dt');
        plot(t_C, smoothed_dCdt,'-','color','k', 'DisplayName', 'MEAN dC/dt')
        ylabel('Derivative')
        ax = gca;
        ax.YColor = "#000000";
        
        yyaxis right
        %plot(t_C, d2Cdt2, '-', 'Color', "#D95319", 'DisplayName', 'd²C/dt²');
        ylabel('Second Derivative')
        ax.YColor = "#000000";
        
        grid on;
        legend('Location', 'northeast');


    xlabel('Time (s)');
    title('Capacitance & Temperature Analysis');
    
    hold off;
%% === ΔC(t) relative to freezing point ===
deltaC = C4_filtered - C_at_freeze;

%% === Change-point detection (basic example using mean/std) ===
changePoints = find(abs(diff(sign(d2Cdt2))) > 0); % inflection points


%% === Capacitance change BEFORE freezing event ===
C_before_freeze = C4_filtered(1:idx_f_exo_C);  % only before freezing
[maxC_pre, idx_max_pre] = max(C_before_freeze);
[minC_pre, idx_min_pre] = min(C_before_freeze);  % already calculated

cap_increase_max = maxC_pre - C_at_freeze;
cap_increase_min = minC_pre - C_at_freeze;

% Optional: show max point in plot
subplot(2,1,1)
hold on
yyaxis left
plot(t_C(idx_max_pre), maxC_pre, 'mo', 'MarkerFaceColor', 'm', 'DisplayName', 'Max Before Freeze');
hold off


%% === Print Results ===
fprintf('\n==== Trial Summary ====\n');
fprintf('Estimated freezing point (s): %.2f\n', t_f_exo);
fprintf('T_peak = %.2f °C\n', T_peak);
fprintf('C(t_f_exo) = %.4f pF\n', C_at_freeze);
fprintf('Minimum C before freezing: %.4f pF\n', minC_pre);
fprintf('Maximum C before freezing: %.4f pF\n', maxC_pre);
fprintf('Drop before freezing (min - freeze): %.4f pF\n', drop_before_freeze);
fprintf('Capacitance increase before freezing (max - freeze): %.4f pF\n', cap_increase_max);
fprintf('Capacitance increase before freezing (min - freeze): %.4f pF\n', cap_increase_min);
fprintf('Inflection points (curvature zero-crossings): %d points\n', numel(changePoints));


%% === Identify all zero-crossing points of smoothed derivative within time window ===

% Find where smoothed derivative crosses zero
sign_change = diff(sign(smoothed_dCdt));
zc_indices_all = find(sign_change ~= 0);

% Define time window: from min C index to 100s after T peak
t_limit = t_f_exo + 100;
idx_limit = find(t_C <= t_limit, 1, 'last');
idx_window_start = 1;

% Keep only crossings within that window
zc_in_window = zc_indices_all(zc_indices_all >= idx_window_start & zc_indices_all <= idx_limit);

% Extract times and values
t_zero_crosses = t_C(zc_in_window);
C_zero_crosses = C4_filtered(zc_in_window);

% Print to console
fprintf('\nZero-crossings of dC/dt between t = %.2f s and %.2f s:\n', t_C(idx_window_start), t_limit);
for i = 1:length(zc_in_window)
    fprintf('  -> t = %.2f s | C = %.4f pF\n', t_zero_crosses(i), C_zero_crosses(i));
end

% === Plot on Subplot 1 ===
subplot(2,1,1)
hold on
yyaxis left
plot(t_zero_crosses, C_zero_crosses, 'gs', 'MarkerFaceColor', 'g', ...
    'DisplayName', 'dC/dt = 0 pts');
legend('Location', 'northeast');
hold off


%% === Plot mean and std of C4_filtered ===
% Compute moving mean and standard deviation
mean_C = movmean(C4_filtered, windowSize);
std_C = movstd(C4_filtered, windowSize);

CV = mean_C./std_C;


figure(2);clf;
    subplot(2,1,1)
        hold on;
        yyaxis left
        plot(t_C, mean_C, '-b', 'DisplayName', 'Moving Mean (C)');
        ylabel('Mean Capacitance (pF)');
        ax = gca;
        ax.YColor = 'b';
        
        yyaxis right
        plot(t_T, temperature, 'Color', "#A2142F", 'DisplayName', 'Temperature');
        plot(t_f_exo, T_peak, 'ro', 'MarkerFaceColor','r', 'DisplayName', 'Freezing Point (T peak)');
        ylabel('T (°C)');
        ax.YColor = "k";
        
        grid on;
        legend('Location', 'northeast');
    hold off

    subplot(2,1,2)
        hold on

        yyaxis left
        plot(t_C, std_C, '-r', 'DisplayName', 'Moving Std (C)');
        ylabel('Std Dev (pF)');
        ax.YColor = 'r';
    
        yyaxis right
        plot(t_C, CV, 'Color', "#A2142F", 'DisplayName', 'CV');
        plot(t_f_exo, T_peak, 'ro', 'MarkerFaceColor','r', 'DisplayName', 'Freezing Point (T peak)');
        ylabel('T (°C)');
        ax.YColor = "k";
        
        grid on;
        legend('Location', 'northeast');
    hold off

    xlabel('Time (s)');
title('Moving Mean and Standard Deviation of Capacitance');



%% === Prefrozen detection algorithm ===
threshold_high = 0.02;
threshold_low = 0.001;

prefrozen_idx = NaN;

% Find first point where std > threshold_high
for i = 1:length(std_C)
    if std_C(i) > threshold_high
        % Then search ahead for where std drops below threshold_low
        for j = i+1:length(std_C)
            if std_C(j) < threshold_low
                prefrozen_idx = j;
                break;
            end
        end
        break; % Exit once first such segment is found
    end
end

if isnan(prefrozen_idx)
    warning('No pre-frozen point found satisfying the criteria.');
else
    t_prefrozen = t_C(prefrozen_idx);
    C_prefrozen = C4_filtered(prefrozen_idx);

    fprintf('\n--- Pre-Frozen Point Detection ---\n');
    fprintf('Pre-frozen point at t = %.2f s | C = %.4f pF\n', t_prefrozen, C_prefrozen);

    %% === Plot on Figure 1 ===
    figure(1);
    subplot(2,1,1);
    hold on;
    yyaxis left;
    plot(t_prefrozen, C_prefrozen, 'kp', 'MarkerFaceColor','c', ...
        'DisplayName', 'Pre-Frozen Point');
    legend('Location', 'northeast');
    hold off;

    %% === Plot on Figure 2 ===
    figure(2);
    subplot(2,1,1);
    hold on;
    yyaxis left;
    plot(t_prefrozen, mean_C(prefrozen_idx), 'kp', 'MarkerFaceColor','c', ...
        'DisplayName', 'Pre-Frozen Point');
    yyaxis right;
    plot(t_prefrozen, temperature(find(abs(t_T - t_prefrozen) == min(abs(t_T - t_prefrozen)),1)), ...
        'kp', 'MarkerFaceColor','c');
    legend('Location', 'northeast');
    hold off;
end
