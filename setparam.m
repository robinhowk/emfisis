function s1 = setparam(tspec, fspec, radius, minPsd)

% tol = 1e-3;
r = radius;
% tau = 0.30;
% theta_phi = 1.0;
% peakspread_threshold = 0;
% rho_spread = 10;
% rho_phi = 3.0;
% rho_threshold = 0;
% spread = 10;
% Mdelta = 100;
mu1 = (fspec(2)-fspec(1))/(tspec(2)-tspec(1));
deltaPsd = minPsd;
% thetabuckets = [20 70 110 160];
% thetavec = [];

% for bucketindex = 1:2:(length(thetabuckets)-1)
%     lasttheta = thetabuckets(bucketindex);
%     while((lasttheta >= thetabuckets(bucketindex)) && (lasttheta <= thetabuckets(bucketindex+1)))
%       Mepsilon = (180/pi)*atan((Mdelta/mu1)*(sin(lasttheta))^2);
%       if(Mepsilon < 0)
%           pause
%       end
%       if(Mepsilon < tol)
%           Mepsilon = tol;
%       end
%           lasttheta = lasttheta + Mepsilon;
%           thetavec = [thetavec lasttheta];     
%     end
% end

histEdges = struct( 'chorusAngles', -90:5:90, 'sweeprates', -14:1:14);

edges = -15:1:15;
edges_weighted = -25:1:25;

s1 = sprintf('r%5.2f.mat',r);
save(s1);
end

