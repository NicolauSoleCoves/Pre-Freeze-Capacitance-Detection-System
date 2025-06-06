function [dC4_dt,t_mid,C4_smoothed] = mov_average_slope(C4,evmTimestamps,W)
%MOV_AVERAGE_SLOPE Summary of this function goes here
%   Detailed explanation goes here
C4_smoothed = movmean(C4, W);  % Or use movmedian(C4, 11)
dt = diff(evmTimestamps);
dC4_dt = diff(C4_smoothed) ./ dt;  % Derivative
t_mid = evmTimestamps(1:end-1) + dt/2;
end

