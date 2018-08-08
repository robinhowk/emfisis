function [ridges, bw_ridges] = find_ridges(paramfilename,datafilename,spect)
%paramfilename has the following variables: 
% r,tausub,peakfactor_threshold,peakspread_threshold,spread,Delta_psd,Mdelta;
% close all;
load(paramfilename);
load(datafilename);

minval = min(min(spect(spect ~= -Inf)));
spect(spect == -Inf) = minval;
imagefilenew = (spect - minval);

len = (length(thetavec)); %#ok<NODEF>
thetavec = thetavec(1:len/2);
[numrows, numcols] = size(spect);
ridges = minval*ones(numrows,numcols);
bw_ridges = zeros(size(spect));

radimage1 = radon(imagefilenew, thetavec);
maxrad = max(max(abs(radimage1)));
rho_peak = maxrad * rho_threshold;

for index1 = 1:(numrows-r)
    for index2 = 1:(numcols-r)
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