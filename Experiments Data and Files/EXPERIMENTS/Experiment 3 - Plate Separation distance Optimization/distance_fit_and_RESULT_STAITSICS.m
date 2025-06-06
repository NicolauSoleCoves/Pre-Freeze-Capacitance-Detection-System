clear; clc; close all;

folderPath = 'C:\Users\nicol\Desktop\TFG\muntatge\MATLAB\Experiments\C\Ideal Distance\Try3_IN_OUT\Ac_1.5_2';
distance_cm = [1, 2, 3, 4, 5];
numDistances = length(distance_cm);
numTrials = 5;

results = struct();

for d = 1:numDistances
    results(d).distance_cm = distance_cm(d);
    results(d).Cbase = nan(1, numTrials);
    results(d).Cbase_std = nan(1, numTrials);
    results(d).Cpeak = nan(1, numTrials);
    results(d).Cpeak_std = nan(1, numTrials);
    results(d).deltaC = nan(1, numTrials);
end

% Load data
for d = 1:numDistances
    for trial = 1:numTrials
        fileName = sprintf('24V_celulose_film_8_layers_Ac_1.5_%d_cm_%d.mat', d, trial);
        filePath = fullfile(folderPath, fileName);
        
        if exist(filePath, 'file')
            data = load(filePath);
            if isfield(data, 'evmTimestamps') && isfield(data, 'C4')
                time = data.evmTimestamps;
                C = data.C4;
                baseIdx = time >= 0 & time <= 10;
                inIdx = time >= 25 & time <= 30;

                if any(baseIdx) && any(inIdx)
                    C_base_vals = C(baseIdx);
                    C_in_vals = C(inIdx);

                    results(d).Cbase(trial) = mean(C_base_vals);
                    results(d).Cbase_std(trial) = std(C_base_vals);
                    results(d).Cpeak(trial) = mean(C_in_vals);
                    results(d).Cpeak_std(trial) = std(C_in_vals);
                    results(d).deltaC(trial) = results(d).Cpeak(trial) - results(d).Cbase(trial);
                end
            end
        end
    end
end

% Summary
summary = struct();
for d = 1:numDistances
    valid = ~isnan(results(d).deltaC);
    summary(d).distance_cm = results(d).distance_cm;
    summary(d).mean_deltaC = mean(results(d).deltaC(valid));
    summary(d).std_deltaC = std(results(d).deltaC(valid));
end

% Print per-trial details
fprintf('\n--- Per-Trial Capacitance Data ---\n');
for d = 1:numDistances
    r = results(d);
    fprintf('\nDistance: %.1f cm\n', r.distance_cm);
    fprintf('%-7s %-12s %-12s %-12s %-12s %-12s\n', ...
        'Trial', 'Cbase', 'Cbase_sd', 'Cpeak', 'Cpeak_sd', 'DeltaC');
    for t = 1:numTrials
        if ~isnan(r.deltaC(t))
            fprintf('%-7d %-12.3f %-12.3f %-12.3f %-12.3f %-12.3f\n', ...
                t, r.Cbase(t), r.Cbase_std(t), r.Cpeak(t), r.Cpeak_std(t), r.deltaC(t));
        else
            fprintf('%-7d %-12s %-12s %-12s %-12s %-12s\n', t, 'NaN', 'NaN', 'NaN', 'NaN', 'NaN');
        end
    end
end

% Prepare fit data
x_fit = [summary.distance_cm];
y_fit = [summary.mean_deltaC];
y_err = [summary.std_deltaC];

% Linear fit
p_lin = polyfit(x_fit, y_fit, 1);
y_lin_fit = polyval(p_lin, x_fit);
R2_lin = 1 - sum((y_fit - y_lin_fit).^2) / sum((y_fit - mean(y_fit)).^2);

% Exponential fit
exp_model = @(p, x) p(1) * exp(p(2) * x);
obj_fun = @(p) sum((y_fit - exp_model(p, x_fit)).^2);
exp_params = fminsearch(obj_fun, [1, -0.5]);
y_exp_fit = exp_model(exp_params, x_fit);
R2_exp = 1 - sum((y_fit - y_exp_fit).^2) / sum((y_fit - mean(y_fit)).^2);

% Smooth x for fit curves
x_smooth = linspace(min(x_fit), max(x_fit), 100);
y_lin_smooth = polyval(p_lin, x_smooth);
y_exp_smooth = exp_model(exp_params, x_smooth);

% Plot
figure; hold on;

% Scatter points from all trials
x_scatter = [];
y_scatter = [];
for d = 1:numDistances
    for t = 1:numTrials
        if ~isnan(results(d).deltaC(t))
            x_scatter(end+1) = results(d).distance_cm;
            y_scatter(end+1) = results(d).deltaC(t);
        end
    end
end
scatter(x_scatter, y_scatter, 40, 'k', 'DisplayName', 'Data points');

% Error bars on means
errorbar(x_fit, y_fit, y_err, 'ko', 'LineWidth', 1.5, ...
    'MarkerFaceColor', 'k', 'CapSize', 5, 'DisplayName', 'Mean ± std');

% Fit curves
plot(x_smooth, y_lin_smooth, 'k-', 'LineWidth', 1.5, ...
    'DisplayName', sprintf('Linear fit: y = %.3fx + %.3f (R^2 = %.3f)', p_lin(1), p_lin(2), R2_lin));
plot(x_smooth, y_exp_smooth, 'k--', 'LineWidth', 1.5, ...
    'DisplayName', sprintf('Exponential fit: y = %.3fe^{%.3fx} (R^2 = %.3f)', exp_params(1), exp_params(2), R2_exp));

xlabel('Distance (cm)', 'FontSize', 12);
ylabel('\DeltaC (pF)', 'FontSize', 12);
title('{\it\DeltaC} vs {\itd} with Fit and Error Bars', 'FontSize', 20);
legend('Location', 'northeast', 'FontSize', 16);
grid on; box on;
