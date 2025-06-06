function [t_f_exo, T_peak, t_C_at_freeze, C_at_freeze, T_ini_exo, t_exo_ini] = exopeak_choose(t_T, temperature, C4_filtered, t_C)
% Detect exothermic peak and initial rise point

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

% Indices in window
idx_window = find(t_T >= t_start & t_T <= t_end);
t_window = t_T(idx_window);
T_window = temperature(idx_window);

% === Find exothermic peak ===
[~, idx_local_max] = max(T_window);
idx_f_exo_T = idx_window(idx_local_max);
t_f_exo = t_T(idx_f_exo_T);
T_peak = temperature(idx_f_exo_T);

% === Find exothermic peak ===
[~, idx_local_max] = max(T_window);
idx_f_exo_T = idx_window(idx_local_max);
t_f_exo = t_T(idx_f_exo_T);
T_peak = temperature(idx_f_exo_T);

% === Find t_exo_ini as time of minimum T before T_peak ===
idx_ini_to_peak = idx_window(1:idx_local_max);  % indices from start to peak
[~, idx_min_T_rel] = min(temperature(idx_ini_to_peak));
idx_min_T_abs = idx_ini_to_peak(idx_min_T_rel);

t_exo_ini = t_T(idx_min_T_abs);
T_ini_exo = temperature(idx_min_T_abs);
xline(t_exo_ini, 'g--', 'Min T before peak');



% === Get C(t_f_exo) ===
[~, idx_f_exo_C] = min(abs(t_C - t_f_exo));
C_at_freeze = C4_filtered(idx_f_exo_C);
t_C_at_freeze = t_C(idx_f_exo_C);

% === Get T(t_ini_exo)
[~, idx_T_ini_exo] = min(abs(t_T - t_exo_ini));
T_ini_exo = temperature(idx_T_ini_exo);

% ΔC from min before peak
[minC_pre, idx_min_pre] = min(C4_filtered(1:idx_f_exo_C));
drop_before_freeze = minC_pre - C_at_freeze;

fprintf('\n--- Exothermic Peak Detection ---\n');
fprintf('Freezing peak at t = %.2f s, T = %.2f °C\n', t_f_exo, T_peak);
fprintf('Start of temp rise (t_{exo,ini}) = %.2f s, T = %.2f °C\n', t_exo_ini, T_ini_exo);
fprintf('C_at_freeze = %.4f pF | Min before freeze = %.4f pF | ΔC = %.4f pF\n', ...
        C_at_freeze, minC_pre, drop_before_freeze);

close;


end
