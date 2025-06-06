clear; clc; close all

%% Constants
sourceFolder = 'C:\Users\nicol\Desktop\TFG\muntatge\MATLAB\Experiments\C\PROVA_ANALISIS\Tria';

WindowSize_C = 29; % Window size for averaging the C
WindowSize_G = 29;

[DTs_Gradient, Dts_Gradient,~, ~] = valley_detect(sourceFolder, WindowSize_C,WindowSize_G, 1,1);