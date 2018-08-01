function [ridges, bw_ridges] = find_ridges(paramfilename,datafilename,spect)
load(paramfilename);
load(datafilename);
%paramfilename has the following variables: 
% r,tausub,peakfactor_threshold,peakspread_threshold,spread,Delta_psd,Mdelta;
% close all;
difft = diff(tspec);
difff = diff(fspec);
ratio_ft = difff(1)/difft(1);

minval = min(min(spect(spect ~= -Inf)));
spect(spect == -Inf) = minval;
imagefilenew = (spect - minval);
imagefiletr = transpose(imagefilenew);

len = (length(thetavec)); %#ok<NODEF>
thetavec = thetavec(1:len/2);
%  ridge_theshold_pm = min(ridge_threshold_pm, minval);
maxval = max(spect(:));
[numrows, numcols] = size(spect);
ridges = minval*ones(numrows,numcols);
bw_ridges = zeros(size(spect));
localsweeprates = nan(size(spect));
anglespines = nan(size(spect));
angles = nan(size(spect));

radimage1 = radon(imagefilenew, thetavec);
maxrad = max(max(abs(radimage1)));
rho_peak = maxrad * rho_threshold;

for index1 = (r+1):(numrows-r)
    for index2 = (1+r):(numcols-r)
        curval = imagefilenew(index1,index2);
        bottom = max((index1-1*r),1);
        top = min((index1+1*r),numrows);
        left = max((index2 - 1*r),1);
        right = min( (index2+1*r), numcols);
       
        subimage = imagefilenew(bottom:top, left:right);
        radsubimage = radon(subimage,thetavec);
        maxsubimage = max(subimage(:));
        
        deltasub = (maxsubimage - curval)/(maxsubimage);
       
        if( deltasub <= tau)
            [chorus_flag] = isbraid(radsubimage,theta_phi,thetavec,spread, rho_peak);
            if chorus_flag
                ridges(index1,index2) = (spect(index1,index2));
                bw_ridges(index1,index2) = 1;
            end
        end
    end
end

% bwskel = bwmorph(bw_ridges,'close',Inf);
% bwskel = bwmorph(bwskel,'thin',Inf);
% bwskel = bwmorph(bwskel,'clean');
% bwskel = bwmorph(bwskel,'skel',Inf);
% rad_bwskel = radon(bwskel,thetavec);
% max_bwskel = max(rad_bwskel)/max(rad_bwskel(:));
% 
% [chorus_angles,chorus_angle_indices] = find_ridge_peaks(max_bwskel,theta_phi,thetavec,spread);
% 
% % chorus_angles
% 
% angle_count = 1;
% chorus_angles_final = [];
% chorus_angle_indices_final = [];
% rho_peakfactors = [];
% rho_peakfactor_index = [];
% 
% for index = 1:length(chorus_angle_indices)
%     rad_bwskel_slice = rad_bwskel(:,chorus_angle_indices(index));
%     max_rad_bwskel_slice = rad_bwskel_slice / max(rad_bwskel_slice);
% %     plot(max_rad_bwskel_slice);
%     len_slice = length(max_rad_bwskel_slice);
%     theta = thetavec(chorus_angle_indices(index));
%     angle_found = 0; % set state of chorus angle found flag to false
%     peak_count = 1;  % reset counter for peaks found
% %     pause
%     
%     for slice_index = 1:length(max_rad_bwskel_slice)
%         curval = max_rad_bwskel_slice(slice_index);
%         firstindex = max((slice_index - rho_spread), 1);
%         firstval = max_rad_bwskel_slice(firstindex);
%         lastindex = min((slice_index + rho_spread), len_slice);
%         lastval = max_rad_bwskel_slice(lastindex);
%         testval = (curval - firstval)*(curval - lastval);
%         if((firstindex ~= lastindex) &&(testval > 0))
%             rmsval = rms(max_rad_bwskel_slice(firstindex:lastindex));
%             localpeakfactor = curval / rmsval;
%             
%             if(localpeakfactor >= rho_phi)
%                 angle_found = 1; % set state of true chorus angle found flag to true
%                 rho_peakfactors(angle_count, peak_count) = localpeakfactor;
%                 rho_peakfactor_index(angle_count, peak_count) = slice_index;
%                 peak_count = peak_count + 1;
%             end
%         end
%     end
%     
%     if(angle_found == 1)
%         chorus_angles_final(angle_count) = 90 - theta;
%         chorus_angle_indices_final(angle_count) = chorus_angle_indices(index);
%         angle_count = angle_count + 1;
%     end
% end
% 
% 
% % chorus_angles_final
% sweeprates = ratio_ft*tan((pi/180)*(chorus_angles_final));
% save temp2
return;
