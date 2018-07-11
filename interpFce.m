function [ interpValue ] = interpFce( prevTime, nextTime, curTime, prevFce, nextFce )
%Interpolates Fce Values based on given timestamp. Returns the upper and
%lower fce limits. Linear interpolation is used on curTime between prevTime 
%and nextTime to find these values.
    if prevFce < 0 || nextFce < 0
        interpValue = NaN;
        return
    end
    
    prevTime = datenum(prevTime);
    nextTime = datenum(nextTime);
    curTime = datenum(curTime);
    
    % intermediate values used for calculation
    a = (nextFce - prevFce) / (nextTime - prevTime);
    b = curTime - prevTime;
    
    % interpolated value
    interpValue = prevFce + (a * b);
end

