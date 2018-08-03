function s1 = setparam

tol = 1e-3;
r = 4;
tau = 0.30;
theta_phi = 1.0;
% peakspread_threshold = 0;
rho_spread = 10;
rho_phi = 3.0;
rho_threshold = 0;
spread = 10;
Mdelta = 100;
mu1 = 2336.502;
delta_psd = -70;
thetabuckets = [20 70 110 160];
thetavec = [];

for bucketindex = 1:2:(length(thetabuckets)-1)
    lasttheta = thetabuckets(bucketindex);
    while((lasttheta >= thetabuckets(bucketindex)) & (lasttheta <= thetabuckets(bucketindex+1)))
      Mepsilon = (180/pi)*atan((Mdelta/mu1)*(sin(lasttheta))^2);
      if(Mepsilon < 0)
          pause
      end
      if(Mepsilon < tol)
          Mepsilon = tol;
      end
          lasttheta = lasttheta + Mepsilon;
          thetavec = [thetavec lasttheta];     
    end
end
histEdges = struct( 'chorusAngles', -90:5:90, 'sweeprates', -14:1:14);

edges = -15:1:15;
edges_weighted = -25:1:25;

s1 = sprintf('r%05.2f_psd%d_rhophi%05.2f_thetaphi%05.2f_tau%0.2f.mat',r,abs(delta_psd),rho_phi,theta_phi, tau);
save(s1);
end

