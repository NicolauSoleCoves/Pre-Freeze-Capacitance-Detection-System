function [dpoints_dt_mov] = lin_slope(C4,emvTimestamp,windowSize)
% LIN_SLOPE does a linear polifit to compute the linear slope of points
% in a specified window
% 
% points: data wich the slope has to be determied
% time_points: time points that accompains the data points
% windowSize:  nº of points to do the algoritm.Must be odd, controls smoothing
%
% dC4_dt_mov: slope of points

dpoints_dt_mov = zeros(size(C4));
halfWin = floor(windowSize/2);

for k = (1+halfWin):(length(C4)-halfWin)
    % Window of time and values
    t_window = emvTimestamp(k-halfWin : k+halfWin);
    c_window = C4(k-halfWin : k+halfWin);
    
    % Linear fit: y = a*t + b --> derivative is slope a
    p = polyfit(t_window, c_window, 1);
    dpoints_dt_mov(k) = p(1);
end

end

