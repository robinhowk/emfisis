function [chorusflag] = isbraid(image_mat,peakfactor_threshold,thetavec,spread, rho_threshold)
%%This works because over a small subimage, where one dominant angle
%%persists. Not so well over cases with many small peaks across the
%%anglular span in the radon domain

chorusflag = 0;
numrows = size(image_mat,1);
numcols = size(image_mat,2);
anglepeaks = max(image_mat);
theta = nan;

% rho_spread = 30;
% rho_peak = 1000;

[angles,angle_indices,peakfactors] = find_ridge_peaks(anglepeaks,peakfactor_threshold,thetavec,spread);

% plot(anglepeaks);
% pause;

sharpestangle = angles(peakfactors == max(peakfactors));
        if(~isnan(sharpestangle))
            theta = (90-sharpestangle);
            % check rho threshold
            rad_slice = image_mat(:,angle_indices(peakfactors == max(peakfactors)));
%             rad_slice = rad_slice / max(rad_slice);
            
            if max(rad_slice) >= rho_threshold
                chorusflag = 1;
            end

%             for slice_index = 1:length(rad_slice)
%                 curval  = rad_slice(slice_index);
%                 firstindex = max((slice_index - rho_spread), 1);
%                 firstval = rad_slice(firstindex);
%                 lastindex = min((slice_index + rho_spread), length(rad_slice));
%                 lastval = rad_slice(lastindex);
%                 testval = (curval - firstval) * (curval - lastval);
%                 
%                 if (firstindex ~= lastindex) && (testval > 0)
%                     rmsval  = rms(rad_slice(firstindex:lastindex));
%                     localpeakfactor = curval / rmsval;
%                 
%                     if localpeakfactor >= rho_peak
%                         chorusflag = 1;
%                     end
%                 end
%             end
%             chorusflag = 1;   
            theta = nan;
        end