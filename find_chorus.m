function ridges = find_chorus(paramfilename, spect)
     var = load(paramfilename); 
    %paramfilename has the following variables: 
    % r,tausub,peakfactor_threshold,peakspread_threshold,spread,Delta_psd,Mdelta;
    % for parallel processing
    r = var.r;
    theta_phi = var.theta_phi;
    spread = var.spread;
    thetavec = var.thetavec;

    minval = min(min(spect(spect ~= -Inf)));
    spect(spect == -Inf) = minval;
    imagefilenew = (spect - minval);

    len = (length(thetavec));
    thetavec = thetavec(1:len/2);

    [numrows, numcols] = size(spect);
    ridges = minval * ones(numrows,numcols);    
%     bw_ridges = zeros(size(spect));

    for index1 = 1:numrows
        for index2 = 1:numcols
            bottom = max((index1-1*r),1);
            top = min((index1+1*r),numrows);
            left = max((index2 - r),1);
            right = min( (index2+r), numcols);

%             curval = imagefilenew(index1,index2);

            subimage = medfilt2(imagefilenew(bottom:top, left:right));        
%             subimage = imagefilenew(bottom:top, left:right);
            localDeltaPsd = dynamicPsd1(subimage, thetavec);       
            subimagenew = subimage;
            subimagenew(subimagenew < localDeltaPsd) = 0;
            radsubimagenew = radon(subimagenew, thetavec);
            [subrows, subcols] = size(subimagenew);
            
            if (subimagenew(ceil(subrows/2), ceil(subcols/2)) > 0)
               [chorus_flag] = isbraid(radsubimagenew,theta_phi,thetavec,spread);
                if chorus_flag % & (spect(index1,index2) >= ridge_threshold_pm) )
                    ridges(index1,index2) = (spect(index1,index2));
%                     bw_ridges(index1,index2) = 1;
                end
            end
        end
    end
end
