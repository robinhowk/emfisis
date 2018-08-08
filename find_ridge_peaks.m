function [chorus_angles,chorus_angle_indices,peakfactors] = find_ridge_peaks(anglepeaks,peakfactor_threshold,thetavec,spread)

chorus_angles = [];
chorus_angle_indices = []; %this will only be used to plot the red stars that denote the bwskel peaks
peakfactors = [];
anglepeaks = anglepeaks/max(anglepeaks);
diffv = diff(anglepeaks);
cur_count = 1;
len = length(diffv)-1;

for index = 1:(length(anglepeaks)-1)    
    firstindex = max((index - spread),1);
    lastindex = min((index+spread),len);
    curval = anglepeaks(index);
    firstval = anglepeaks(firstindex);
    lastval = anglepeaks(lastindex);
    grad = (curval - firstval)*(curval - lastval);
       
    if((grad > 0) && (firstindex ~=lastindex) )
%         localpeakfactor = (curval-0.5*(firstval+lastval))/(0.5*(lastindex - firstindex));
        rmsval = rms(anglepeaks(firstindex:lastindex));
%         curval(anglepeaks(firstindex), anglepeaks(lastindex));
        localpeakfactor = curval / rmsval;
        
        if((localpeakfactor >= peakfactor_threshold)) %| (curval > 0.25)
            theta = thetavec(index);
            chorus_angles(cur_count) = 90-theta; %#ok<AGROW>
            peakfactors(cur_count) = localpeakfactor; %#ok<AGROW>
            chorus_angle_indices(cur_count) = index; %#ok<AGROW>
            cur_count = cur_count+1;
        end
    end
end
