function [chorusflag] = isbraid(image_mat,peakfactor_threshold,thetavec,spread)
%%This works because over a small subimage, where one dominant angle
%%persists. Not so well over cases with many small peaks across the
%%anglular span in the radon domain

% chorusflag = 0;
% numrows = size(image_mat,1);
% numcols = size(image_mat,2);
anglepeaks = max(image_mat);
% theta = nan;

% rho_spread = 30;
% rho_peak = 1000;

[angles,~,peakfactors] = find_ridge_peaks(anglepeaks,peakfactor_threshold,thetavec,spread);

sharpestangle = angles(peakfactors == max(peakfactors));
        if(~isnan(sharpestangle))
%             theta = (90-sharpestangle);
            chorusflag = 1;
        else
            chorusflag = 0;
%             theta = nan;
        end