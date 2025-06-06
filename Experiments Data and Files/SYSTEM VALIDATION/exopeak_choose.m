function [t_f_exo, T_peak, t_C_at_freeze, C_at_freeze, T_ini_exo, t_exo_ini] = exopeak_choose(t_T, temperature, C4_filtered, t_C, trialFileName)

% === Generate unique ID for cache file based on trial file name ===
% === Generate unique ID for cache file based on trial file name ===
[~, trialName, ~] = fileparts(trialFileName);
trialID = regexprep(trialName, '[^\w]', '_');
datasetID = sprintf('exo_cache_%s.mat', trialID);


if isfile(datasetID)
    % === Load cached results ===
    load(datasetID, 't_f_exo', 'T_peak', 't_C_at_freeze', 'C_at_freeze', 'T_ini_exo', 't_exo_ini');
    fprintf('[INFO] Loaded cached exothermic peak data from %s\n', datasetID);
    return;
end

% === User input: Select exothermic window ===
figure;
plot(t_T, temperature);
ylim([-5,7])
title(sprintf('Select window around exothermic peak for %s', trialFileName), 'Interpreter', 'none');
xlabel('Time (s)'); ylabel('Temperature (°C)');

[t_start, ~] = ginput(1);
xline(t_start, '--k', 'Start');
[t_end, ~] = ginput(1);
xline(t_end, '--r', 'End');

if t_start > t_end
    [t_start, t_end] = deal(t_end, t_start);
end

% Indices in window
idx_window = find(t_T >= t_start & t_T <= t_end);
t_window = t_T(idx_window);
T_window = temperature(idx_window);

% Find exothermic peak
[~, idx_local_max] = max(T_window);
idx_f_exo_T = idx_window(idx_local_max);
t_f_exo = t_T(idx_f_exo_T);
T_peak = temperature(idx_f_exo_T);

% Find initial rise (minimum T before peak)
idx_ini_to_peak = idx_window(1:idx_local_max);
[~, idx_min_T_rel] = min(temperature(idx_ini_to_peak));
idx_min_T_abs = idx_ini_to_peak(idx_min_T_rel);

t_exo_ini = t_T(idx_min_T_abs);
T_ini_exo = temperature(idx_min_T_abs);
xline(t_exo_ini, 'g--', 'Min T before peak');

% Find C(t_f_exo)
[~, idx_f_exo_C] = min(abs(t_C - t_f_exo));
C_at_freeze = C4_filtered(idx_f_exo_C);
t_C_at_freeze = t_C(idx_f_exo_C);

% Cache result
save(datasetID, 't_f_exo', 'T_peak', 't_C_at_freeze', 'C_at_freeze', 'T_ini_exo', 't_exo_ini');
fprintf('[INFO] Saved exothermic peak data to %s\n', datasetID);

close;
end
