clear all;clc;close all
%% ---------------------------------CONSTANTS-------------------------------------------------------
folderPath = 'C:\Users\nicol\Desktop\TFG\muntatge\MATLAB\Experiments\C\ICE_WATER_SAMPLES\Ac_4_4';
baseName = 'V24V_d1.5cm_Ac16cm2_14';
WindowSize_C = 29; % Window size for averaging the C
WindowSize_S = 29; % Window size for averaging Std(C)
WindowSize_G = 29; % Window size for averaging the gradient

xlimit = [0 500];

%% ----------- Load latest saved file from your folder --------------------------------------------

cd(folderPath);
load(baseName);  % loads: timeStamp_T, temperature, evmTimestamps, C4

% ----------- Clean up C4 data from outliers -------------------------------------------------------
for i = 2:length(C4)
    if C4(i) < 2 || C4(i) > 15.6
        C4(i) = C4(i-1);
    end
end

t_C = evmTimestamps;
t_T = timeStamp_T;
%% ----------------------SIGNAL PROCCESSING-------------------------------------------------------
% MOVING AVERAGE to erase some noise from C:
C4_filtered = movmean(C4, WindowSize_C);

% Gradient to calculate the derivative(slope) of C:
t_C = t_C;
dt = mean(diff(t_C));
dCdt = gradient(C4_filtered, dt);
%Smooth the gradient
smoothed_dCdt = movmean(dCdt, WindowSize_G);

% Calculate the std(C(t)):
std_C = movstd(C4_filtered, WindowSize_S);

%% Change of slope: Peaks and Valleys:

% Detect zero crossings
sign_dCdt = sign(smoothed_dCdt);
zeroCrossings = diff(sign_dCdt);

% Peak = +1 to -1 crossing → zeroCrossing = -2
% Valley = -1 to +1 crossing → zeroCrossing = +2

peakIndices = find(zeroCrossings == -2) + 1;
valleyIndices = find(zeroCrossings == 2) + 1;

% Extract values
peakTimes = t_C(peakIndices);
peakValues = C4_filtered(peakIndices);

valleyTimes = t_C(valleyIndices);
valleyValues = C4_filtered(valleyIndices);


%% Algorithm:
th1 = 0.02;
th2 = 0.0005;
P1 = false;
for i=1:length(C4_filtered)
    if std_C(i) > th1
        P1 = true;
    end
    if P1
        if std_C(i) < th2
            t_change = t_C(i);
            C_change = C4_filtered(i);
            P1 = false;
            %break;  % Stop loop once change is found
        end
    end
end

%% Choose the exothermic peak
[t_f_exo,T_peak,t_C_at_freeze,C_at_freeze] = exopeak_choose(t_T,temperature,C4_filtered,t_C);


%% Calculate delay:
% Compute time difference
delta_t = t_change - t_C_at_freeze;
% Compute temperature at detection point
T_change = interp1(t_T, temperature, t_change);

%% ------------General Plot  with interest points and curves--------------------------------------------------
figure(1);clf
    subplot(2,1,1);
        hold on
        yyaxis right
            % C curves    
            plot(t_C, C4, 'k.','DisplayName','Raw C_{in}','MarkerSize',1);
            plot(t_C,C4_filtered,'-','Color', "#ff00fb", 'DisplayName','Moveavg C_{in}','LineWidth',1)
            % C Interest points
            plot(t_C_at_freeze,C_at_freeze,'kx','DisplayName','C_{exo, peak}','MarkerSize',15)
            
            plot(peakTimes,peakValues,'r|','DisplayName','C_{peaks}','MarkerSize',40,'MarkerFaceColor','r')
            plot(valleyTimes,valleyValues,'g|','DisplayName','C_{valleys}','MarkerSize',40,'MarkerFaceColor','g')
            
            plot(t_change,C_change,'b*', 'DisplayName','C_{change}','MarkerSize',15)
            
            % show the detection delay and T:
            text(mean(xlim()), max(C4_filtered), ...
                sprintf(['Detection Delay: \\Delta t = %.2f s\n' ...
                         'T = %.2f °C'], delta_t, T_change), ...
                'FontSize', 10, 'Color', 'b', 'HorizontalAlignment', 'center', ...
                'Interpreter', 'tex');

            xlabel('Time (s)');
            ylabel('C (nF)');
            ax = gca;
            ax.YColor="k";       
        yyaxis left
            plot(t_T, temperature, 'Color', "#A2142F", 'DisplayName', 'Temperature');
            plot(t_f_exo,T_peak,'kx','DisplayName','C_{exo, peak}','MarkerSize',10)
            ylabel('T (°C)');
            ax.YColor = "k";
            xlim(xlimit);
        legend('NumColumns',2);
        title('Reference Data \it{C(t)} and \it{T(t)}')
        grid on;            
        hold off
%------------------------------------------------------------------------------------------------
    subplot(2,1,2);
            hold on
            yyaxis right
                plot(t_C,dCdt,'.','Color', "k", 'DisplayName','dC with moveavg','LineWidth',1)
                plot(t_C,smoothed_dCdt,'-','Color', "#ff00fb", 'DisplayName','dC with moveavg','LineWidth',1)
                ylabel('dC/dt (nF/s)');                
                ax = gca;
                ax.YColor="k";
            yyaxis left
                plot(t_C, std_C, 'Color', "#A2142F", 'DisplayName', 'std(C(t))');
                ylabel('std(C(t)) (nF)');
                ax.YColor = "k";
            xlim(xlimit);

            xlabel('t (s)');            
            legend();
            title('Statistic Calculation \it{dC/dt} and \it{std(C(t))}');
            grid on;
            hold off

%% OTHER DATA PLOTS:
% %%
% figure(3);clf;
% hold on
% sgtitle('Comparative plot of the affect in the window size (W) using Move avgerage vs linear Polyfit')
%     subplot(5,1,1);
%         hold on
%         yyaxis Left
%             plot(t_mid_11,dC4_dt_11,'-','Color', "#ff00fb", 'DisplayName','dC with moveavg','LineWidth',1)
%             plot(t_C, dC4_dt_mov_10, 'k-','DisplayName','dC with polyfit lin slope','LineWidth',1);
%             ylim([-0.035,0.01]);         xlim([0 300]);
%             hold off
%             title('W=11')
%             legend('Location','best')
%             grid on
%             ax = gca;
%             ax.YColor="k";
%         yyaxis Right
%             plot(t_C,C4_smoothed,'-','Color', "k", 'DisplayName','Moveavg Cin','LineWidth',1)
%             ax.YColor = "k";          
% 
%     subplot(5,1,2);
%         hold on
%         yyaxis Left
%             plot(t_mid_15,dC4_dt_15,'-','Color', "#ff00fb", 'DisplayName','dC with moveavg','LineWidth',1)
%             plot(t_C, dC4_dt_mov_15, 'k-','DisplayName','dC with polyfit lin slope','LineWidth',1);
%             ylim([-0.035,0.01]);         xlim([0 300]);
%             hold off
%             title('W=15')
%             grid on
%             ax = gca;
%             ax.YColor="k";
%         yyaxis Right
%             plot(t_C,C4_smoothed,'-','Color', "k", 'DisplayName','Moveavg Cin','LineWidth',1)
%             ax.YColor = "k";
% 
%     subplot(5,1,3);
%         hold on
%         yyaxis Left
%             plot(t_mid_21,dC4_dt_21,'-','Color', "#ff00fb", 'DisplayName','dC with moveavg','LineWidth',1)
%             plot(t_C, dC4_dt_mov_20, 'k-','DisplayName','dC with polyfit lin slope','LineWidth',1);
%             ylim([-0.035,0.01]);         xlim([0 300]);
%             hold off
%             title('W=21')
%             grid on
%             ylabel('dC/dt (pF/s)')
%             ax = gca;
%             ax.YColor="k";
%         yyaxis Right
%             plot(t_C,C4_smoothed,'-','Color', "k", 'DisplayName','Moveavg Cin','LineWidth',1)
%             ylabel('C(t)');
%             ax.YColor = "k";
% 
%     subplot(5,1,4);
%         hold on
%         yyaxis Left
%             plot(t_mid_51,dC4_dt_51,'-','Color', "#ff00fb", 'DisplayName','dC with moveavg','LineWidth',1)
%             plot(t_C, dC4_dt_mov_50, 'k-','DisplayName','dC with polyfit lin slope','LineWidth',1);
%             ylim([-0.035,0.01]);         xlim([0 300]);
%             hold off
%             title('W=51')
%             grid on
%             ax = gca;
%             ax.YColor="k";
%         yyaxis Right
%             plot(t_C,C4_smoothed,'-','Color', "k", 'DisplayName','Moveavg Cin','LineWidth',1)
%             ax.YColor = "k";
% 
%     subplot(5,1,5);
%         hold on
%         yyaxis Left
%             plot(t_mid_101,dC4_dt_101,'-','Color', "#ff00fb", 'DisplayName','dC with moveavg','LineWidth',1)
%             plot(t_C, dC4_dt_mov_101, 'k-','DisplayName','dC with polyfit lin slope','LineWidth',1);
%             ylim([-0.035,0.01]);         xlim([0 300]);
%             xlim([0 300]);
%             hold off
%             title('W=101')
%             xlabel('t (s)')
%             grid on
%             ax = gca;
%             ax.YColor="k";
%         yyaxis Right
%             plot(t_C,C4_smoothed,'-','Color', "k", 'DisplayName','Moveavg Cin','LineWidth',1)
%             ax.YColor = "k";
% 
% hold off