clear all;
clc;
close all;

%% Initial Constants:
numSamples = 60*5;  % 5 minutes of data
prefrozen_detected = false;

% === Filter (moving average) for the capacitance data ===
windowSize = 25;
window_std = windowSize;

% Pre-frozen detection logic
threshold_high = 0.017;
threshold_low = 0.0025;

%% SERIAL PORT SETUP

serialPort = "COM5";
baudRate = 115200;

if exist('s', 'var')
    clear s;
end

s = serialport(serialPort, baudRate);
pause(1);
flush(s);
disp("Serial connection established!");

%% GRAPH INITIALIZATION
temperature = [];
timeStamp_T = [];
timeStamp_CSV = [];

%% Activate Relay
write(s, ['T', 13, 10], "uint8")
write(s, ['T', 13, 10], "uint8")

%% Prepare CSV data
csvFilePath = 'C:\ti\Sensing Solutions EVM GUI-1.10.0\PC GUI\data.csv';
initialFileSize = dir(csvFilePath).bytes;
dataCSV = readtable(csvFilePath);
sample_zero = height(dataCSV);

%% ------------------------------ Main Loop ------------------------------
figure(1);
hWaitbar = waitbar(0, 'Running...', 'Name', 'Data Acquisition', ...
                   'CreateCancelBtn', 'delete(gcbf);');

while true
    %% Exit if user closes waitbar
    if ~ishandle(hWaitbar)
        disp("Stopped by user");
        break;
    end

    % Read and Parse Arduino Data
    while s.NumBytesAvailable > 0
        rawData = readline(s);
    end

    values = str2double(split(strtrim(rawData), ','));

    if numel(values) == 2 && all(~isnan(values))
        timestamp_arduino = values(1) / 1000;  % Convert ms to seconds
        temp = values(2);

        temperature(end+1) = temp;
        timeStamp_T(end+1) = timestamp_arduino;

        % Plot Temperature
        subplot(2,1,1);
        plot(timeStamp_T, temperature, 'Color', "#A2142F",'LineStyle','--','LineWidth',1);
        ylabel('Temperature (°C)','FontSize',16);
        xlabel('Time (s)','FontSize',16);
        title('Live T Data from AHT10 via MEGA2560','FontSize',24);
        grid on;

        if max(timeStamp_T) > numSamples
            xlim([max(timeStamp_T) - numSamples, max(timeStamp_T)]);
        end
        ylim([min(temperature)-1 min(temperature)+7])
    end

    % Plot Capacitance from CSV (updated)
    subplot(2,1,2);
    hold on
    dataCSV = readtable(csvFilePath);
    dataCSV = dataCSV(sample_zero:end,:);

    evmTimestamps = cumsum(dataCSV{:, 'logDeltaMs'}) / 1000;
    


    C4 = dataCSV{:, 'MEAS4_pF'};
    % Clean up C4 from outliers
    if C4(end) < 2 || C4(end) > 15.6
        C4(end) = C4(end-1);
    end
    C4_filtered = movmean(C4, windowSize); % smoothing window

    plot(evmTimestamps, C4, 'Color', "#000000",'LineStyle','-','LineWidth',1);
    if evmTimestamps(end) > windowSize*2
        plot(evmTimestamps, C4_filtered, 'Color', "#EDB120",'LineStyle','-', 'DisplayName', 'Filtered Capacitance');
    end

    xlabel('Time (s)', 'FontSize',16);
    ylabel('Capacitance (pF)', 'FontSize',16);
    title('Live C Data from FDC1004EVM','FontSize',24);
    grid on;
    hold off

    if max(evmTimestamps) > numSamples
        xlim([max(evmTimestamps) - numSamples, max(evmTimestamps)]);
    end

  %% === Pre-frozen Detection ===
if ~prefrozen_detected && timeStamp_T(end) > 30
    % Compute rolling std
    std_C = movstd(C4_filtered, window_std);

    % Start analyzing only after 30s
    start_idx = find(evmTimestamps > 30, 1);

    prefrozen_idx = NaN;
    for i = start_idx:length(std_C)
        if std_C(i) > threshold_high
            for j = i+1:length(std_C)
                if std_C(j) < threshold_low
                    prefrozen_idx = j;
                    break;
                end
            end
            break;
        end
    end

    if ~isnan(prefrozen_idx)
        t_prefrozen = evmTimestamps(prefrozen_idx);
        C_prefrozen = C4_filtered(prefrozen_idx);
        fprintf('[PREFROZEN DETECTED] t = %.2f s | C = %.4f pF\n', t_prefrozen, C_prefrozen);

        % Mark on current plot
        subplot(2,1,2);
        hold on;
        plot(t_prefrozen, C_prefrozen, 'kx', 'MarkerSize', 10, ...
             'MarkerFaceColor', 'c', 'DisplayName', 'Detected Pre-Frozen Point');
        hold off;

        % Lock detection
        prefrozen_detected = true;
    end
end

    %% Dummy update
    if ishandle(hWaitbar)
        waitbar(rand, hWaitbar, 'Acquiring...');
    end

    pause(0.001); % Keep it low for near real-time
end

if ishandle(hWaitbar)
    close(hWaitbar);
end

%% ------------------------------ FINAL PLOT ------------------------------
figure(2);
clf;
hold on;

yyaxis right
plot(timeStamp_T, temperature, 'Color', "#A2142F",'DisplayName', 'Temperature')
ylabel('Temperature (ºC)','FontSize',16);
ax = gca;
ax.YColor = "#000000";

yyaxis left
plot(evmTimestamps, C4, 'Color', "#000000", 'DisplayName', 'Capacitance')
if evmTimestamps(end) > windowSize*2
    plot(evmTimestamps, C4_filtered, 'Color', "#EDB120",'LineStyle','-', 'DisplayName', 'Filtered Capacitance');
end
if exist('t_prefrozen', 'var') && exist('C_prefrozen', 'var')
    plot(t_prefrozen, C_prefrozen, 'bx', ...
        'MarkerSize', 20, ...
        'LineWidth',2, ...
        'DisplayName', 'Detected Pre-Frozen Point');
end
ylabel('Capacitance (pF)','FontSize',16);
ax.YColor = "k";

xlabel('Time (s)','FontSize',16);
title('Complete Data Overview','FontSize',24);
legend("Location", "northeast", 'FontSize', 12, "NumColumns", 4);
grid on;
hold off;

%% Clean Up
write(s, ['T', 13, 10], "uint8")
clear s;

%% AUX FUNCTIONS
% None added; feel free to create helper functions if needed
