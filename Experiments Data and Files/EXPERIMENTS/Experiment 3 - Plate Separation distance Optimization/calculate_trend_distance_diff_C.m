clear; clc; close all;

% Folder containing the data files
folderPath = 'C:\Users\nicol\Desktop\TFG\muntatge\MATLAB\Experiments\C\Ideal Distance\Try3_IN_OUT\Ac_1.5_2';

% Distance mapping (in cm)
distance_cm = [1, 2, 3, 4, 5];
numDistances = length(distance_cm);
numTrials = 5;

% Arrays to store data
distances = [];
deltaC = [];

for d = 1:numDistances
    for trial = 1:numTrials
        % File name
        fileName = sprintf('24V_celulose_film_8_layers_Ac_1.5_%d_cm_%d.mat', d, trial);
        filePath = fullfile(folderPath, fileName);

        if exist(filePath, 'file')
            data = load(filePath);
            if isfield(data, 'evmTimestamps') && isfield(data, 'C4')
                time = data.evmTimestamps;
                C = data.C4;

                % Compute ΔC: mean(C at 25-30s) - mean(C at 0-10s)
                baseIdx = time >= 0 & time <= 10;
                inIdx   = time >= 25 & time <= 30;

                if any(baseIdx) && any(inIdx)
                    C_base = mean(C(baseIdx));
                    C_in   = mean(C(inIdx));
                    delta = C_in - C_base;

                    distances(end+1) = distance_cm(d); %#ok<*SAGROW>
                    deltaC(end+1) = delta;
                end
            end
        end
    end
end

% Convert to column vectors
x_valid = distances(:);
y_valid = deltaC(:);

% Linear fit
p_lin = polyfit(x_valid, y_valid, 1);
y_fit_lin = polyval(p_lin, x_valid);
SS_res_lin = sum((y_valid - y_fit_lin).^2);
SS_tot = sum((y_valid - mean(y_valid)).^2);
R2_lin = 1 - SS_res_lin / SS_tot;

% Exponential fit using fminsearch
exp_model = @(params, x) params(1) * exp(params(2) * x);
obj_fun = @(params) sum((y_valid - exp_model(params, x_valid)).^2);
initial_params = [1, -0.1];
exp_params = fminsearch(obj_fun, initial_params);
y_fit_exp = exp_model(exp_params, x_valid);
SS_res_exp = sum((y_valid - y_fit_exp).^2);
R2_exp = 1 - SS_res_exp / SS_tot;

% Create fit curves
x_fit = linspace(min(x_valid), max(x_valid), 100);
y_curve_lin = polyval(p_lin, x_fit);
y_curve_exp = exp_model(exp_params, x_fit);

% Plotting
figure;
hold on;
scatter(x_valid, y_valid, 40, 'k', 'filled', 'DisplayName', 'Data points');
plot(x_fit, y_curve_lin, 'k-', 'LineWidth', 1, 'DisplayName', ...
    sprintf('Linear fit: y = %.3fx + %.3f (R^2 = %.3f)', p_lin(1), p_lin(2), R2_lin));
plot(x_fit, y_curve_exp, 'k--', 'LineWidth', 1, 'DisplayName', ...
    sprintf('Exponential fit: y = %.3fe^{%.3fx} (R^2 = %.3f)', exp_params(1), exp_params(2), R2_exp));

xlabel('Distance between plates {\itd} (cm)', 'FontSize', 12);
ylabel('\DeltaC (pF)', 'FontSize', 12);
title('{\it\DeltaC} vs Plate Distance with Linear & Exponential Fits for {\itA_c} = 3 cm^2', 'FontSize', 20);
legend('Location', 'northeast','FontSize',16);
grid on;
