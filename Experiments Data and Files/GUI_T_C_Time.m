%% ------------------------INICIALIZATION:---------------------------------

%% PREPARE IDLE
clear all; clc; close all;

%% INITIAL CONSTANTS:
numSamples = 64;

%% SERIAL PORT SETUP:
serialPort = "COM5"; %check the port where the ARDUINO is connected.
baudRate = 115200; % check that the arduino is configured to this badurate

% Check and close old serial open comunications
if exist('s', 'var')
    
    clear s;
end

% Create a new serial comunication:
s = serialport(serialPort, baudRate);
pause(1);
flush(s);
disp("Serial connection established!");
%% ACTIVATE REALAY
write(s, ['T', 13, 10], "uint8")
write(s, ['T', 13, 10], "uint8")
%% GRAPH INITIALIZATION
temperature = [];
timeStamp_T = [];
timeStamp_CSV = [];

%% PREPARE THE CSV DATA
csvFilePath = 'C:\ti\Sensing Solutions EVM GUI-1.10.0\PC GUI\data.csv';
initialFileSize = dir(csvFilePath).bytes;
dataCSV = readtable(csvFilePath);
sample_zero = height(dataCSV);

%% ---------------------------MAIN LOOP:-----------------------------------
figure(1);
% Open window with cancel button:
hWaitbar = waitbar(0, 'Running...', 'Name', 'Data Acquisition', ...
                   'CreateCancelBtn', 'delete(gcbf);');
% Loop:
while true
    %% Exit if user closes waitbar
    if ~ishandle(hWaitbar)
        disp("Stopped by user");
        break;
    end

    %% Read and Parse Arduino Data
    while s.NumBytesAvailable > 0
        rawData = readline(s);
    end

    values = str2double(split(strtrim(rawData), ','));

    if numel(values) == 2 && all(~isnan(values))
        timestamp_arduino = values(1) / 1000;  % Convert ms to seconds
        temp = values(2);
        
        % Fetch the new data to the vectors
        temperature(end+1) = temp;
        timeStamp_T(end+1) = timestamp_arduino;

        %% Plot Temperature
        subplot(2,1,1);
        plot(timeStamp_T, temperature, ...
            'Color', "#A2142F", ...
            'LineStyle','--', ...
            'LineWidth',1);
        ylabel('Temperature (°C)','FontSize',16);
        xlabel('Time (s)','FontSize',16);
        title('Live T Data from AHT10 via MEGA2560','FontSize',24);
        grid on;
        
        % View window:
        if max(timeStamp_T) > numSamples
            xlim([max(timeStamp_T) - numSamples, max(timeStamp_T)]);
        end
    end

    %% Plot Capacitance from CSV (unchanged)
    subplot(2,1,2);
    dataCSV = readtable(csvFilePath);
    dataCSV = dataCSV(sample_zero:end,:);

    % Fetch the new data into the vectors
    evmTimestamps = cumsum(dataCSV{:, 'logDeltaMs'}) / 1000;
    C4 = dataCSV{:, 'MEAS4_pF'};

    plot(evmTimestamps, C4, ...
        'Color', "#000000", ...
        'LineStyle','-', ...
        'LineWidth',1);
    xlabel('Time (s)', 'FontSize',16);
    ylabel('Capacitance (pF)', 'FontSize',16);
    title('Live C Data from FDC1004EVM','FontSize',24);
    grid on;
    
    % View window
    if max(evmTimestamps) > numSamples
        xlim([max(evmTimestamps) - numSamples, max(evmTimestamps)]);
    end

    %% Dummy update for the waiting window
    if ishandle(hWaitbar)
        waitbar(rand, hWaitbar, 'Adquiring...');
    end


    pause(0.001); % Keep it low for near real-time
end

% If the process is terminated, close the waiting window
if ishandle(hWaitbar)
    close(hWaitbar);
end


%% -----------------------------FINAL PLOT:--------------------------------
figure(2);
clf;
hold on;

yyaxis right
plot(timeStamp_T, temperature, ...
    'Color', "#A2142F", ...
    'DisplayName', 'Temperature')
ylabel('Temperature (ºC)','FontSize',16);
ax = gca;
ax.YColor = "#000000";
%ylim([-3, 8])

% Filter the capacitance data noise with a moving average filter:
windowSize = 10;
C4_filtered = movmean(C4, windowSize);

% Plot the data, with noise and filtered
yyaxis left
plot(evmTimestamps, C4, ...
    'Color', "#000000", ...
    'DisplayName', 'Capacitance')
plot(evmTimestamps, C4_filtered, ...
    'Color', "#EDB120", ...
    'LineStyle','-', ...
    'DisplayName', 'Filtered Capacitance');
ylabel('Capacitance (pF)','FontSize',16);
ax.YColor = "k";

xlabel('Time (s)','FontSize',16);
title('Complete Data Overview','FontSize',24);
legend("Location", "northeast", 'FontSize', 12, "NumColumns", 4);
grid on;
hold off;



%% -----------------------------Clean Up:----------------------------------
% Turn off the relay
write(s, ['T', 13, 10], "uint8")
% Close the serial comunication with the arduino
clear s;
