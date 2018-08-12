function [chorusflag] = isbraid(image_mat,peakfactor_threshold,thetavec,spread, rho_threshold)
%%This works because over a small subimage, where one dominant angle
%%persists. Not so well over cases with many small peaks across the
%%anglular span in the radon domain

chorusflag = 0;
anglepeaks = max(image_mat);

% rho_spread = 30;
% rho_peak = 1000;

[angles,angle_indices,peakfactors] = find_ridge_peaks(anglepeaks,peakfactor_threshold,thetavec,spread);

% plot(anglepeaks);
% pause;

sharpestangle = angles(peakfactors == max(peakfactors));
if(~isnan(sharpestangle))
    % check rho threshold
    rad_slice = image_mat(:,angle_indices(peakfactors == max(peakfactors)));

    if max(rad_slice) >= rho_threshold
        chorusflag = 1;
    end
end